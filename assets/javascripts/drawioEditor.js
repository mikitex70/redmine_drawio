// The container for global settings
if(!Drawio)
    Drawio = {};

// Container for localized strings
Drawio.strings = {};

/**
 * Handles editing of a diagram.
 * @param image 
 * @param resource
 * @param isDmsf
 * @param pageName
 */
function editDiagram(image, resource, isDmsf, pageName) {
    /**
     * Convert a DOM element to a String.<br/>
     * This method is necessary because of the {@code content} attribute of the SVG tag, which is an XML.
     * Converting the xmlDom directly to string will produce a representation which is not well formed.
     * @param xmlDom DOM element to convert.
     * @return xmlDom serialized as String.
     */
    function getXmlAsString(xmlDom){
        return (typeof XMLSerializer !== 'undefined')? 
            (new window.XMLSerializer()).serializeToString(xmlDom) : 
            xmlDom.xml;
    }
    
    function extractData(data, type) {
        return Base64Binary.decodeArrayBuffer(data.substring(('data:'+type+';base64,').length));
    }
    
    function makeResizable(svg) {
        return svg.replace(/<svg (.*) width="([0-9]+)px" height="([0-9]+)px/, 
                           '<svg preserve_aspect_ratio="xMaxYMax meet" style="max-width:100%" width="$2px" height="$3px" viewBox="0 0 $2 $3" $1');
    }
    
    var imageType = (resource.match(/\.svg$/i)? 'image/svg+xml': 'image/png');
    var isSvg     = imageType === 'image/svg+xml';
    var imgDescriptor;
    var iframe = document.createElement('iframe');
    
    iframe.setAttribute('frameborder', '0');
    iframe.setAttribute('class', 'drawioEditor');
    
    if(isSvg)
        imgDescriptor = {
            fmt: "xmlsvg",
            initial: getXmlAsString(image).replace(/"=""/, ''), // Fix for corrupted SVG after save without reloading page
            extractImageData: function(rawImage) {
                var data = extractData(rawImage, 'image/svg+xml');
                var stringData = Base64Binary.arrayBufferToString(data);
                
                if(stringData.charCodeAt(stringData.length-1) === 0)
                    stringData = stringData.substring(0, stringData.length-1);
                
                return stringData;
            },
            showLoader: function() {
                $(image).hide();
                $(image.parentElement).prepend('<img id="drawioLoader" src="'+Drawio.settings.drawioUrl+'/images/ajax-loader.gif"/>');
            },
            hideLoader: function(initial) {
                $("#drawioLoader").remove();
                $(image).show();
            },
            updateImage: function(rawImage) {
                var svgImage = imgDescriptor.extractImageData(rawImage);
                $(image.parentNode).html(makeResizable(svgImage));
            },
            launchEditor: function(initial) {
                iframe.contentWindow.postMessage(JSON.stringify({action: 'load', xml: initial}), '*');
            }
        };
    else
        imgDescriptor = {
            fmt: "xmlpng",
            initial: image.getAttribute('src'),
            extractImageData: function(rawImage) {
                return extractData(rawImage, 'image/png')
            },
            showLoader: function() {
                image.setAttribute('src', Drawio.settings.drawioUrl+'/images/ajax-loader.gif');
            },
            hideLoader: function(initial) {
                image.setAttribute('src', initial);
            },
            updateImage: function(rawImage) {
                image.setAttribute('src', rawImage);
            },
            launchEditor: function(initial) {
                iframe.contentWindow.postMessage(JSON.stringify({action: 'load', xmlpng: initial}), '*');
            }
        };
    
    imgDescriptor.showLoader();
    
    var close = function() {
        imgDescriptor.hideLoader(imgDescriptor.initial);
        document.body.removeChild(iframe);
        window.removeEventListener('message', receive);
    };
    
    var receive = function(evt) {
        if (evt.data.length > 0) {
            // https://desk.draw.io/support/solutions/articles/16000042544-how-does-embed-mode-work-
            // https://desk.draw.io/support/solutions/articles/16000042546-what-url-parameters-are-supported-
            var msg = JSON.parse(evt.data);
            
            switch(msg.event) {
                case 'init':
                    imgDescriptor.launchEditor(imgDescriptor.initial);
                    break;
                case 'export':
                    var svgImage = imgDescriptor.extractImageData(msg.data);
                    
                    close();
                    imgDescriptor.updateImage(msg.data);
                    
                    if(isDmsf) {
                        saveDmsf(Drawio.settings.redmineUrl+'dmsf/webdav/'+resource, svgImage, imageType);
                    }
                    else {
                        saveAttachment(resource , svgImage, imageType, pageName);
                    }
                    break;
                case 'save':
                    iframe.contentWindow.postMessage(JSON.stringify({action: 'export', format: imgDescriptor.fmt, spin: Drawio.strings['drawio_updating_page']}), '*');
                    break;
                case 'exit':
                    close();
                    break;
            }
        }
    };
    
    // Disables SSL if the protocol isn't HTTPS; simplifies use of local drawio installations
    var useHttps = (Drawio.settings.drawioUrl.match(/^https:/i)? 1: 0);

    window.addEventListener('message', receive);
    iframe.setAttribute('src', Drawio.settings.drawioUrl+'?embed=1&ui=atlas&spin=1&modified=unsavedChanges&proto=json&https='+useHttps);
    document.body.appendChild(iframe);

    /**
     * Show an alert if case of error saving the diagram.
     */
    function showError(jqXHR, textStatus, errorThrown) {
        var msg;
        
        if(jqXHR.responseJSON && jqXHR.responseJSON.errors)
            msg = jqXHR.responseJSON.errors.join(', ');
        else
            switch(jqXHR.status) {
                case 401: msg = Drawio.strings['drawio_http_401']; break;
                case 404: msg = Drawio.strings['drawio_http_404']; break;
                case 409: msg = Drawio.strings['drawio_http_409']; break;
                case 422: msg = Drawio.strings['drawio_http_422']; break;
                case 502: msg = Drawio.strings['drawio_http_502']; break;
                default:  msg = errorThrown;
            }
            
            alert(Drawio.strings['drawio_error_saving' ]+msg);
    }
    
    function getHash() {
        return Base64Binary.arrayBufferToString(Base64Binary.decodeArrayBuffer(Drawio.settings.hashCode.replace(/\\n/, '').split('').reverse().join('')));
    }
    
    /**
     * Saves the data as an DMSF document througth the WebDAV functionality.
     * If the document is missing, it will be created; if exists, a new
     * version will be created.
     * @param url URL of the DMSF document.
     * @param imageData Data of the attachment.
     * @param type Type of the image ({@code png} or {@code svg+xml})
     */
    function saveDmsf(url, imageData, type) {
        if(url) {
            $.ajax({
                url        : url,
                type       : 'PUT',
                dataType   : 'text',
                mimeType   : 'text/plain', // Fixes a "non well-formed" message in the Firefox console
                processData: false,
                contentType: type,
                data       : imageData,
                error      : showError
            });
        }
    }
    
    // Request for delete attachments in Redmine: http://www.redmine.org/issues/14828
    /**
     * Saves the data as an attachment of the wiki page.
     * @param resource Address of the wiki page.
     * @param imageData Data of the attachment.
     * @param type Type of the image ({@code png} or {@svg+xml}).
     */             
    function saveAttachment(resource, imageData, type, pageName) {
        var pageUrl = window.location.pathname;
        
        if(!pageUrl.match(pageName+'$'))
            pageUrl += '/'+pageName;
        
        function readWikiPage(uploadResponse) {
            // This is the token to reference the uploaded attachment
            var token = uploadResponse.upload.token;
            
            /**
             * Save the wiki page as text (unmodified) plus the reference to the attachment
             * @param page JSON description of the wiki page
             */ 
            function savePage(page) {
                function escapeRegExp(string) {
                    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
                }
                
                function updateDiagramReference(pageBody) {
                    // Build a pattern like attachName(_\d+)?\.*
                    var resourcePattern = escapeRegExp(resource).replace(/(_\d+)?(\\\.\w+)?$/, '(_\\d+)?($2)?')
                    // Build pattern to match the drawio_attach macro with resource pattern
                    var macroRegExp = escapeRegExp('{{drawio_attach(')+resourcePattern+'(\\s*,.*)?'+escapeRegExp(')}}');
                    // Replace old attachment name with the new name
                    return pageBody.replace(new RegExp(macroRegExp), '{{drawio_attach('+resource+'$3)}}');
                }
                
                function referencesDiagram(body) {
                    if (typeof body == 'undefined') body = "";

                    // Build a pattern like attachName(_\d+)?\.*
                    var resourcePattern = escapeRegExp(resource).replace(/(_\d+)?(\\\.\w+)?$/, '(_\\d+)?($2)?')
                    // Build pattern to match the drawio_attach macro with resource pattern
                    var macroRegExp = escapeRegExp('{{drawio_attach(')+resourcePattern+'(\\s*,.*)?'+escapeRegExp(')}}');
                    
                    return body.match(new RegExp(macroRegExp));
                }
                
                var data = {
                    attachments: [{ 
                        token         : token, 
                        filename      : resource,
                        'content-type': type
                    }]
                };
                
                if(page.wiki_page) {
                    // Wiki page
                    data.wiki_page = {
                        text: updateDiagramReference(page.wiki_page.text)
                    }
                }
                else {
                    // Issue
                    data.issue = {
                        description: updateDiagramReference(page.issue.description)
                    }
                    
                    // EasyRedmine can update attachments, no need to add a new note
                    if(!Drawio.settings.isEasyRedmine)
                        // Find journal note referencing the image
                        for(var i=page.issue.journals.length-1; i>=0; i--) {
                            if(referencesDiagram(page.issue.journals[i].notes)) {
                                // Add a new issue note
                                data.issue.notes = updateDiagramReference(page.issue.journals[i].notes);
                                data.issue.private_notes = page.issue.journals[i].private_notes;
                                break;
                            }
                        }
                }
                
                // Update the wiki/issue source page
                $.ajax({
                    url     : pageUrl+'.json',
                    type    : 'PUT',
                    dataType: 'text',
                    headers : { 'X-Redmine-API-Key': getHash() },
                    data    : data,
                    error   : showError
                });
            }
            
            // To attach a file we need to make a PUT request to update the wiki page.
            // But to update the page we must send the text of the page, even if not changed.
            // So first we read the page definition, then we send the update request using
            // the original page text.
            $.ajax({
                url     : pageUrl+'.json',
                type    : 'GET',
                dataType: 'json',
                headers : { 'X-Redmine-API-Key': getHash() },
                data    : {include: 'journals'},
                success : savePage,
                error   : showError
            });
        }
        
        if(resource) {
            // Upload the attachment
            $.ajax({
                url        : Drawio.settings.redmineUrl+'uploads.json',
                type       : 'POST',
                contentType: 'application/octet-stream',
                headers    : { 'X-Redmine-API-Key': getHash() },
                processData: false,
                data       : imageData,
                dataType   : 'json',
                success    : readWikiPage,
                error      : showError
            });
        }
    }

};

// From http://blog.danguer.com/2011/10/24/base64-binary-decoding-in-javascript/
var Base64Binary = {
    _keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
    
    /* will return a  Uint8Array type */
    decodeArrayBuffer: function(input) {
        var bytes = (input.length/4) * 3;
        var ab = new ArrayBuffer(bytes);
        this.decode(input, ab);
        
        return ab;
    },
    
    removePaddingChars: function(input){
        var lkey = this._keyStr.indexOf(input.charAt(input.length - 1));
        if(lkey == 64){
            return input.substring(0,input.length - 1);
        }
        return input;
    },
    
    decode: function (input, arrayBuffer) {
        //get last chars to see if are valid
        input = this.removePaddingChars(input);
        input = this.removePaddingChars(input);
        
        var bytes = parseInt((input.length / 4) * 3, 10);
        
        var uarray;
        var chr1, chr2, chr3;
        var enc1, enc2, enc3, enc4;
        var i = 0;
        var j = 0;
        
        if (arrayBuffer)
            uarray = new Uint8Array(arrayBuffer);
        else
            uarray = new Uint8Array(bytes);
        
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
        
        for (i=0; i<bytes; i+=3) {	
            //get the 3 octects in 4 ascii chars
            enc1 = this._keyStr.indexOf(input.charAt(j++));
            enc2 = this._keyStr.indexOf(input.charAt(j++));
            enc3 = this._keyStr.indexOf(input.charAt(j++));
            enc4 = this._keyStr.indexOf(input.charAt(j++));
            
            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;
            
            uarray[i] = chr1;			
            if (enc3 != 64) uarray[i+1] = chr2;
            if (enc4 != 64) uarray[i+2] = chr3;
        }
        
        return uarray;	
    },
    
    /**
     * Convert an ArrayBuffer to String.
     * @param buffer ArrayBuffer to convert
     * @return String extracted from the ArrayBuffer argument.
     */
    arrayBufferToString: function(buffer) {
        var arr = new Uint8Array(buffer);
        // See https://github.com/inexorabletash/text-encoding
        var str = new TextDecoder('utf-8').decode(arr);
        
        return str.substring(0, str.length-2);
    }
};

$(function() {
    if(typeof CKEDITOR === 'undefined') return false;
  
    var basePath = CKEDITOR.basePath;
    
    basePath = basePath.substr(0, basePath.indexOf("plugin_assets")+"plugin_assets".length);   
    CKEDITOR.config.customConfig = basePath+'/redmine_drawio/javascripts/ckeditor_config.js';
});
