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
            initial: getXmlAsString(image),
            showLoader: function() {
                $(image).hide();
                $(image.parentElement).prepend('<img id="drawioLoader" src="'+DRAWIO_URL+'/images/ajax-loader.gif"/>');
            },
            hideLoader: function(initial) {
                $("#drawioLoader").remove();
                $(image).show();
            },
            updateImage: function(rawImage) {
                var svgImage = extractData(rawImage, 'image/svg+xml').slice(0,-1);
                $(image.parentNode).html(makeResizable(Base64Binary.arrayBufferToString(svgImage)));
            },
            launchEditor: function(initial) {
                iframe.contentWindow.postMessage(JSON.stringify({action: 'load', xml: initial}), '*');
            }
        };
    else
        imgDescriptor = {
            fmt: "xmlpng",
            initial: image.getAttribute('src'),
            showLoader: function() {
                image.setAttribute('src', DRAWIO_URL+'/images/ajax-loader.gif');
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
                    var svgImage = extractData(msg.data, imageType).slice(0,-1);
                    
                    close();
                    imgDescriptor.updateImage(msg.data);
                    
                    if(isDmsf) {
                        saveDmsf(REDMINE_URL+'dmsf/webdav/'+resource, svgImage, imageType);
                    }
                    else {
                        saveAttachment(resource , svgImage, imageType, pageName);
                    }
                    break;
                case 'save':
                    iframe.contentWindow.postMessage(JSON.stringify({action: 'export', format: imgDescriptor.fmt, spin: 'Updating page'}), '*');
                    break;
                case 'exit':
                    close();
                    break;
            }
        }
    };
    
    window.addEventListener('message', receive);
    iframe.setAttribute('src', DRAWIO_URL+'?embed=1&ui=atlas&spin=1&modified=unsavedChanges&proto=json');
    document.body.appendChild(iframe);
};

/**
 * Show an alert if case of error saving the diagram.
 */
function showError(jqXHR, textStatus, errorThrown) {
    alert('Error saving diagram:\n'+errorThrown);
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
            error      : function(jqXHR, textStatus, errorThrown) {
                switch(jqXHR.status) {
                    case 404:
                    case 409:
                    case 502: break;
                    default : showError(jqXHR, textStatus, errorThrown);
                }
            },
            statusCode : {
                404: function() { showError(null, null, 'Make sure WebDAV capabilities of DMSF module is enabled'); },
                409: function() { showError(null, null, 'Make sure the DMSF folder exists and is accessible'); },
                502: function() { showError(null, null, 'Make sure WebDAV capabilities of DMSF module is enabled in Read/Write mode'); }
            }
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
                console.debug("pageBody=",pageBody);
                // Build a pattern like attachName(_\d+)?\.*
                var resourcePattern = escapeRegExp(resource).replace(/(_\d+)?(\\\.\w+)?$/, '(_\\d+)?($2)?')
                console.debug("resourcePattern=",resourcePattern);
                // Build pattern to match the drawio_attach macro with resource pattern
                var macroRegExp = escapeRegExp('{{drawio_attach(')+resourcePattern+'(\\s*,.*)?'+escapeRegExp(')}}');
                console.debug("macroRegExp=",macroRegExp);
                // Replace old attachment name with the new name
                console.debug("result=",pageBody.replace(new RegExp(macroRegExp), '{{drawio_attach('+resource+'$3)}}'));
                return pageBody.replace(new RegExp(macroRegExp), '{{drawio_attach('+resource+'$3)}}');
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
            }
            
            // Update the wiki/issue source page
            $.ajax({
                url     : pageUrl+'.json',
                type    : 'PUT',
                dataType: 'text',
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
            success : savePage,
            error   : showError
        });
    }
    
    if(resource) {
        // Upload the attachment
        $.ajax({
            url        : REDMINE_URL+'uploads.json',
            type       : 'POST',
            contentType: 'application/octet-stream',
            processData: false,
            data       : imageData,
            dataType   : 'json',
            success    : readWikiPage,
            error      : showError
        });
    }
}

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
    
    // From http://stackoverflow.com/questions/843680/how-to-replace-dom-element-in-place-using-javascript
    /**
     * Convert an ArrayBuffer to String.
     * @param buffer ArrayBuffer to convert
     * @return String extracted from the ArrayBuffer argument.
     */
    arrayBufferToString: function(buffer) {
        var arr = new Uint8Array(buffer);
        var str = String.fromCharCode.apply(String, arr);
        
        if (/[\u0080-\uffff]/.test(str))
            throw new Error("this string seems to contain (still encoded) multibytes");

        return str;
    }
};

$(function() {
    if(typeof CKEDITOR === 'undefined') return false;
  
    var basePath = CKEDITOR.basePath;
    
    basePath = basePath.substr(0, basePath.indexOf("plugin_assets")+"plugin_assets".length);   
    CKEDITOR.config.customConfig = basePath+'/redmine_drawio/javascripts/ckeditor_config.js';
});
