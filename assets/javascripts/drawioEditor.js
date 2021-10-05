// The container for global settings
if(!Drawio)
    Drawio = {};

// Container for localized strings
Drawio.strings = {};

/**
 * Handles editing of a diagram.
 * @param image DOM element of the diagram image
 * @param resource The filename of the diagram (with extension)
 * @param isDmsf true if the diagram is stored with the DMSF module
 * @param pageName The wiki page name (if the document is a wiki page)
 */
function editDiagram(image, resource, isDmsf, pageName, originalName) {
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
        return svg.replace(/<svg (.*) width="([0-9]+)px" height="([0-9]+)px viewBox"(.*)"/, 
                           '<svg preserve_aspect_ratio="xMaxYMax meet" style="max-width:100%" width="$2px" height="$3px" viewBox="0 0 $2 $3" $1');
    }
    
    var pngMime   = 'image/png';
    var svgMime   = 'image/svg+xml';
    var xmlMime   = 'application/xml';
    var imageType = (resource.match(/\.svg$/i)? svgMime: (resource.match(/\.png$/i)? pngMime: xmlMime));
    var isSvg     = imageType === svgMime;
    var isPng     = imageType === pngMime;
    var imgDescriptor;
    var iframe = document.createElement('iframe');
    
    iframe.setAttribute('frameborder', '0');
    iframe.setAttribute('class', 'drawioEditor');
    
    if(isSvg)
        imgDescriptor = {
            fmt: "xmlsvg",
            mimeType: svgMime,
            ext: 'svg',
            initial: atob(image.getAttribute('src').substring(('data:'+imageType+';base64,').length)),
            extractImageData: function(rawImage) {
                var data = extractData(rawImage, imgDescriptor.mimeType);
                var stringData = Base64Binary.arrayBufferToString(data);
                
                if(stringData.charCodeAt(stringData.length-1) === 0) {
                    stringData = stringData.substring(0, stringData.length-1);
                }
                if(stringData.charCodeAt(stringData.length-1) === 0) {
                    stringData = stringData.substring(0, stringData.length-1);
                }
                // It seems that the SVG image coming from Drawio is not correctly encoded (or decoded)
                if(stringData.endsWith("</sv")) {
                    stringData += "g>";
                }
                else if(stringData.endsWith("</svg")) {
                    stringData += ">";
                }
                
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
                var base64Svg = "data:image/svg+xml;base64," + Base64Binary.encode(makeResizable(svgImage));
                $(image).attr('src', base64Svg)
            },
            launchEditor: function(initial) {
                iframe.contentWindow.postMessage(JSON.stringify({action: 'load', xml: initial}), '*');
            },
            save: function(msg) {
                iframe.contentWindow.postMessage(JSON.stringify({action: 'export', format: "xmlsvg", spin: Drawio.strings['drawio_updating_page']}), '*');
            }
        };
    else if(isPng)
        imgDescriptor = {
            fmt: "xmlpng",
            mimeType: pngMime,
            ext: 'png',
            initial: image.getAttribute('src'),
            extractImageData: function(rawImage) {
                return extractData(rawImage, imgDescriptor.mimeType)
            },
            showLoader: function() {
                image.setAttribute('src', Drawio.settings.drawioUrl+'/images/ajax-loader.gif');
            },
            hideLoader: function(initial) {
                image.setAttribute('src', initial);
            },
            updateImage: function(rawImage) {
                image.setAttribute('src', rawImage);
                imgDescriptor.initial = rawImage; // so the hideLoader() in the close() will not revert the image
            },
            launchEditor: function(initial) {
                iframe.contentWindow.postMessage(JSON.stringify({action: 'load', xmlpng: initial}), '*');
            },
            save: function(msg) {
                iframe.contentWindow.postMessage(JSON.stringify({action: 'export', format: "xmlpng", spin: Drawio.strings['drawio_updating_page']}), '*');
            }
        };
    else
        imgDescriptor = {
            fmt: 'xml',
            mimeType: xmlMime,
            ext: 'xml',
            initial: $.parseJSON($(image).attr('data-mxgraph')).xml,
            extractImageData: function(rawImage) {
                return rawImage;
            },
            showLoader: function() {
                $(image).html('<img id="drawioLoader" src="'+Drawio.settings.drawioUrl+'/images/ajax-loader.gif"/>');
            },
            hideLoader: function(initial) {
                // Destroy div contents and redraw the diagram
                $(image).html("");
                GraphViewer.createViewerForElement(image[0]);
            },
            updateImage: function(rawImage) {
                var newValue = $.parseJSON($(image).attr('data-mxgraph'));
                newValue.xml = rawImage;
                $(image).attr('data-mxgraph', JSON.stringify(newValue));
            },
            launchEditor: function(initial) {
                iframe.contentWindow.postMessage(JSON.stringify({action: 'load', xml: initial}), '*');
            },
            save: function(msg) {
                save(msg.xml);
            }
        };
    
    imgDescriptor.showLoader();
    
    function close() {
        imgDescriptor.hideLoader(imgDescriptor.initial);
        document.body.removeChild(iframe);
        window.removeEventListener('message', receive);
    };
    
    function receive(evt) {
        if (evt.data.length > 0) {
            // https://desk.draw.io/support/solutions/articles/16000042544-how-does-embed-mode-work-
            // https://desk.draw.io/support/solutions/articles/16000042546-what-url-parameters-are-supported-
            var msg = JSON.parse(evt.data);
            
            switch(msg.event) {
                case 'init':
                    imgDescriptor.launchEditor(imgDescriptor.initial);
                    break;
                case 'export':
                    save(msg.data);
                    break;
                case 'save':
                    if(!(msg.bounds.width && msg.bounds.height)) {
                        // The diagram is empty. If it were saved, there would be no image 
                        // on the page to click to be able to modify the diagram.
                        // So we ask the user to choose to stay in the editor or to leave and
                        // use the default image placeholder.
                        if(msg.currentPage > 0) {
                            alert(Drawio.strings['drawio_empty_diag_page']);
                        }
                        else {
                            alert(Drawio.strings['drawio_empty_diag']);
                        }
                        break;
                    }
                    imgDescriptor.save(msg);
                    break;
                case 'exit':
                    close();
                    break;
            }
        }
    };
    
    // Disables SSL if the protocol isn't HTTPS; simplifies use of local drawio installations
    var useHttps = (Drawio.settings.drawioUrl.match(/^(https:)?\/\//i)? 1: 0);

    window.addEventListener('message', receive);
    iframe.setAttribute('src', Drawio.settings.drawioUrl+'?embed=1&ui=atlas&spin=1&modified=unsavedChanges&libraries=1&proto=json&https='+useHttps);
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
                case 404: 
                    if(isDmsf)
                        msg = Drawio.strings['drawio_http_404'];
                    else
                        msg = Drawio.strings['drawio_save_error'];
                    break;
                case 409: msg = Drawio.strings['drawio_http_409']; break;
                case 422: msg = Drawio.strings['drawio_http_422']; break;
                case 502: msg = Drawio.strings['drawio_http_502']; break;
                default:  msg = errorThrown;
            }
            
            alert(Drawio.strings['drawio_error_saving' ]+msg);
    }
    
    function getHash() {
        return Base64Binary.arrayBufferToString(Base64Binary.decodeArrayBuffer(Drawio.settings.hashCode.split('').reverse().join(''))).replace(/\u0000/g,'');
    }
    
    /**
     * Save the image data as attachment or in DMSF.<br/>
     * The image will also be updated in the page, without reloading.
     * @param data Image data url (content of the {@code src} attribute).
     */
    function save(data) {
        // Diagram is not empty
        var imageData = imgDescriptor.extractImageData(data);
        
        imgDescriptor.updateImage(data);
        close();
        
        if(isDmsf) {
            saveDmsf(Drawio.settings.redmineUrl+'dmsf/webdav/'+resource, imageData, imageType);
        }
        else {
            saveAttachment(resource , imageData, imageType, pageName);
        }
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
        var encodedPageName = new RegExp('/wiki/'+encodeURI(pageName).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')+'$', 'i');

        // pageName !== "" means it's a wiki page
        if(pageName !== "" && !pageUrl.match(encodedPageName))
            pageUrl += '/'+pageName; // Fix main wiki page url
        
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
                    var resourcePattern = escapeRegExp(resource).replace(/^(.*?)(_\d+)?(\\\.\w+)?$/, function(m,p1,p2,p3) {
                        return p1.replace(/_/g, '.')+'(_\\d+)?('+p3+')?';
                    })
                    // Build pattern to match the drawio_attach macro with resource pattern
                    var macroRegExp = escapeRegExp('{{drawio_attach(')+resourcePattern+'(\\s*,.*)?'+escapeRegExp(')}}');
                    // Replace old attachment name with the new name
                    return pageBody.replace(new RegExp(macroRegExp), '{{drawio_attach('+resource+'$3)}}');
                }
                
                function referencesDiagram(body) {
                    if (body == null || typeof body == 'undefined') body = "";

                    // Build a pattern like attachName(_\d+)?\.*
                    var resourcePattern = escapeRegExp(resource).replace(/(_\d+)?(\\\.\w+)?$/, '(_\\d+)?($2)?')
                    // Build pattern to match the drawio_attach macro with resource pattern
                    var macroRegExp = escapeRegExp('{{drawio_attach(')+resourcePattern+'(\\s*,.*)?'+escapeRegExp(')}}');
                    
                    return body.match(new RegExp(macroRegExp));
                }
                
                /**
                 * Fix for `{{fnlist}}` duplication with the `redmine_wiki_extensions` plugin.
                 */
                function fixFnListDuplication(value) {
                    return value.replace(/\n\n\{\{fnlist\}\}\n*$/, '');
                }
                
                /**
                 * Fix for Wiki Extensions header page.
                 */
                function fixWikiExtensionsHeader(value) {
                    return value.replace(/\n<div id="wiki_extentions_header">[\S\s]+?\n<\/div>\n\n/gi, '');
                }
                
                /**
                 * Fix for Wiki Extensions header page.
                 */
                function fixWikiExtensionsFooter(value) {
                    return value.replace(/\n\n<div id="wiki_extentions_footer">[\S\s]+?\n<\/div>$/gi, '');
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
                        text: fixFnListDuplication(fixWikiExtensionsFooter(fixWikiExtensionsHeader(updateDiagramReference(page.wiki_page.text)))),
                        comments: originalName+" -> "+resource
                    };
                    // If it is the main wiki page, the full page name is needed for the put
                    var l = pageUrl.length-'/wiki'.length;
                    
                    if(l >= 0 && pageUrl.lastIndexOf('/wiki') === l) {
                        pageUrl += "/"+page.wiki_page.title;
                    }
                }
                else {
                    // Issue
                    data.issue = {
                        description: fixFnListDuplication(updateDiagramReference(page.issue.description))
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
                url        : Drawio.settings.redmineUrl+'uploads.json?filename='+resource,
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
    _keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
    
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
        
        input = input.replace(/[^A-Za-z0-9+/=]/g, "");
        
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
    
    encode: function (input) {
        var output = "";
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i = 0;

        while(i < input.length) {
            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if(isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if(isNaN(chr3)) {
                enc4 = 64;
            }

            output = output +
                this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
                this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

        }

        return output;
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
        
        return str;
    }
};

window.onDrawioViewerLoad = function() {
    // The 'toolbar-buttons' configuration option expects a function in the `handler` option.
    // But in the 'data-mxgraph' attribute the JSON is a string, which is converted to an object,
    // so a literal function name o even an function expression will raise an error.
    // The only solution is to express the handler as an expression in a string, but this requires
    // a small patch in the `addToolbar` function.
    // To not keep a patched version of the `viewer-static.min.js` file, I will patch it runtime.
    // Maybe it will broke in the future, but for now is working.
    
    // Patch the code
    //var code = GraphViewer.prototype.addToolbar.toString().replace(/t\.enabled\?t\.handler:function/, 't.enabled?("string"===typeof(t.handler)?eval(t.handler):t.handler):function');
    var code = GraphViewer.prototype.addToolbar.toString().replace(/([a-z])\.enabled\?\1\.handler:function/, '$1.enabled?("string"===typeof($1.handler)?eval($1.handler):$1.handler):function');
    // Apply the patch
    GraphViewer.prototype.addToolbar = eval("("+code+")");
    // Draw graphs
    GraphViewer.processElements();
}

$(function() {
  if(typeof CKEDITOR === 'undefined') return false;

  var basePath = CKEDITOR.basePath;
  
  basePath = basePath.substr(0, basePath.indexOf("plugin_assets")+"plugin_assets".length);   
  basePath = basePath.replace(/https?:\/\/[^\/]+/, "");
  CKEDITOR.plugins.addExternal('drawio', basePath+'/redmine_drawio/javascripts/', 'drawio_plugin.js');
  
  if(typeof(Object.getOwnPropertyDescriptor(CKEDITOR, 'editorConfig')) === "undefined") {
      // CKEDITOR.editorConfig is not patched: add a patch to intercept changes of the
      // editorConfig property and be able to apply more than one setup.
      var oldEditorConfig = CKEDITOR.editorConfig || null;
      
      Object.defineProperty(CKEDITOR, 'editorConfig', { 
          get: function() { return oldEditorConfig; },
          set: function(newValue) {
                   if(oldEditorConfig) {
                       var prevValue = oldEditorConfig;
                   
                       oldEditorConfig = function(config) {
                            prevValue(config);
                            newValue(config);
                       }
                   }
                   else
                       oldEditorConfig = newValue;
                }
      });
  }
  
  CKEDITOR.editorConfig = function(config) {
      // Workaround for the configuration override.
      // The Redmine CKEditor plugin has its own config.js that resets 
      // any change to the extraPlugins property.
      // This code implements a setter on the config.extraPlugins property
      // so the new value is not replaced but instead appended to the
      // existing value. It is supported by the major modern browser (for
      // example from IE 9).
      if(typeof(Object.getOwnPropertyDescriptor(config, 'extraPlugins')) === "undefined") {
          var _extraPlugins = config.extraPlugins || '';
          
          Object.defineProperty(config, 'extraPlugins', { 
              get: function() { return _extraPlugins; },
              set: function(newValue) {
                    if(_extraPlugins === '')
                        _extraPlugins = newValue;
                    else
                        _extraPlugins += ','+newValue;
                }
          });
      }

      // Same as before, but this time I want the drawio toolbar appended
      // after the default toolbar
      if(typeof(Object.getOwnPropertyDescriptor(config, 'toolbar')) === "undefined") {
          var _toolbar = config.toolbar || [];

          Object.defineProperty(config, 'toolbar', {
              get: function() { 
                  return _toolbar.concat(config.extraToolbar);
              },
              set: function(newValue) {
                  _toolbar = newValue;
              }
          });
      }
      
      // Now we can proceed with the CKEDITOR setup
      var drawio_toolbar = [['btn_drawio_attach', 'btn_drawio_dmsf']];
      
      config.extraPlugins = 'drawio';
      config.extraToolbar = (config.extraToolbar || []).concat(drawio_toolbar);
  }
});
