function editDiagram(image, resource, isDmsf, pageName) {
    var initial = image.getAttribute('src');
    
    image.setAttribute('src', 'http://www.draw.io/images/ajax-loader.gif');
    
    var iframe = document.createElement('iframe');
    
    iframe.setAttribute('frameborder', '0');
    iframe.setAttribute('class', 'drawioEditor');
    
    var close = function() {
        image.setAttribute('src', initial);
        document.body.removeChild(iframe);
        window.removeEventListener('message', receive);
    };
    
    var receive = function(evt) {
        if (evt.data.length > 0) {
            var msg = JSON.parse(evt.data);
            
            switch(msg.event) {
                case 'init':
                    iframe.contentWindow.postMessage(JSON.stringify({action: 'load', xmlpng: initial}), '*');
                    break;
                case 'export':
                    close();
                    image.setAttribute('src', msg.data);
                    image.setAttribute('data-diagram', msg.data);
                    
                    if(isDmsf) {
                        saveDmsf(REDMINE_URL+"dmsf/webdav/"+resource, msg.data);
                    }
                    else {
                        saveAttachment(resource , msg.data, pageName);
                    }
                    break;
                case 'save':
                    iframe.contentWindow.postMessage(JSON.stringify({action: 'export', format: 'xmlpng', spin: 'Updating page'}), '*');
                    break;
                case 'exit':
                    close();
                    break;
            }
        }
    };
    
    window.addEventListener('message', receive);
    iframe.setAttribute('src', 'https://www.draw.io/?embed=1&ui=atlas&spin=1&modified=unsavedChanges&proto=json');
    document.body.appendChild(iframe);
};

/**
 * Show an alert if case of error saving the diagram.
 */
function showError(jqXHR, textStatus, errorThrown) {
    alert("Error saving diagram:\n"+errorThrown);
}

/**
 * Saves the data as an DMSF document througth the WebDAV functionality.
 * If the document is missing, it will be created; if exists, a new
 * version will be created.
 * @param url URL of the DMSF document.
 * @param data Data (base64 encoded) of the attachment; will be decoded and
 *             sent as image/png.
 */
function saveDmsf(url, data) {
    if(url) {
        var base64Data = data.substring("data:image/png;base64,".length);

        $.ajax({
            url        : url,
            type       : "PUT",
            dataType   : "text",
            mimeType   : "text/plain", // Fixes a "non well-formed" message in the Firefox console
            processData: false,
            contentType: "image/png",
            data       : Base64Binary.decodeArrayBuffer(base64Data),
            error      : function(jqXHR, textStatus, errorThrown) {
                switch(jqXHR.status) {
                    case 404:
                    case 409:
                    case 502: break;
                    default : showError(jqXHR, textStatus, errorThrown);
                }
            },
            statusCode : {
                404: function() { showError(null, null, "Make sure WebDAV capabilities of DMSF module is enabled"); },
                409: function() { showError(null, null, "Make sure the DMSF folder exists and is accessible"); },
                502: function() { showError(null, null, "Make sure WebDAV capabilities of DMSF module is enabled in Read/Write mode"); }
            }
        });
    }
}
             
// Request for delete attachments in Redmine: http://www.redmine.org/issues/14828
/**
 * Saves the data as an attachment of the wiki page.
 * @param resource Address of the wiki page.
 * @param data Data (base64 encoded) of the attachment; will be decoded and
 *             sent as image/png.
 */             
function saveAttachment(resource, data, pageName) {
    var pageUrl = window.location.pathname;
    
    if(!pageUrl.match(pageName+"$"))
        pageUrl += "/"+pageName;
    
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
                var resourcePattern = escapeRegExp(resource).replace(/(_\d+)?(\\\.\w+)?$/, "(_\\d+)?($2)?")
                // Build pattern to match the drawio_attach macro with resource pattern
                var macroRegExp = escapeRegExp("{{drawio_attach(")+resourcePattern+"(\\s*,.*)?"+escapeRegExp(")}}");
                // Replace old attachment name with the new name
                return pageBody.replace(new RegExp(macroRegExp), "{{drawio_attach("+resource+"$3)}}");
            }
            
            var data = {
                attachments: [{ 
                    token         : token, 
                    filename      : resource,
                    "content-type": "image/png" 
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
                url     : pageUrl+".json",
                type    : "PUT",
                dataType: "text",
                data    : data,
                error   : showError
            });
        }
        
        // To attach a file we need to make a PUT request to update the wiki page.
        // But to update the page we must send the text of the page, even if not changed.
        // So first we read the page definition, then we send the update request using
        // the original page text.
        $.ajax({
            url     : pageUrl+".json",
            type    : "GET",
            dataType: "json",
            success : savePage,
            error   : showError
        });
    }
    
    if(resource) {
        // Upload the attachment
        var base64Data = data.substring("data:image/png;base64,".length);
        
        $.ajax({
            url        : REDMINE_URL+"uploads.json",
            type       : 'POST',
            contentType: 'application/octet-stream',
            processData: false,
            data       : Base64Binary.decodeArrayBuffer(base64Data),
            dataType   : "json",
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
    }
};

$(function () {
    if(typeof jsToolBar === 'undefined') return false;
 
    dlg = $("#dlg_redmine_drawio").dialog({
        autoOpen: false,
        width   : "auto",
        height  : "auto",
        modal   : true,
        buttons : {
            "Insert macro": function() { 
                var editor    = dlg.data("editor");
                var macroName = dlg.data("macro");
                var diagName  = $("#drawio_diagName").val();
                var size      = $("#drawio_diagSize").val();
                
                if(diagName != "") {
                    var sizeOpt = "";
                    
                    if(/^\d+$/.test(size)) {
                        sizeOpt = ", size="+size;
                    }
                    
                    editor.encloseSelection('{{'+macroName+'('+diagName+sizeOpt+')}}');
                    dlg.dialog("close");
                }
            },
            Cancel: function() {
                dlg.dialog("close");
            }
        }
    });
    
    $("#drawio_diagSize").keypress(function(evt) {
        if(evt.altKey || evt.ctrlKey || evt.metaKey || evt.which === 0)
            return true;
        
        var keyCode = evt.keyCode || evt.charCode;
        
        switch(keyCode) {
            case 8: // backspace
                return true;
            default: return new RegExp($(this).attr("pattern")).test(this.value+evt.key); // Check if the character is allowed
        }
    });
 
    jsToolBar.prototype.elements.drawio_attach = {
        type : 'button',
        after: 'img',
        title: 'Drawio attached diagram',
        fn   : {
            wiki: function(event) {
                dlg.data("editor", this).data("macro", "drawio_attach").dialog("open");
            }
        }
    };
    
    jsToolBar.prototype.elements.drawio_dmsf = {
        type : 'button',
        after: 'drawio_attach',
        title: 'Drawio DMSF diagram',
        fn   : {
            wiki: function(event) {
                dlg.data("editor", this).data("macro", "drawio_dmsf").dialog("open");
            }
        }
    };
    
    wikiToolbar.draw();
});
