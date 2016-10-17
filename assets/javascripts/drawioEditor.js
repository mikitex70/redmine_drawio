function editDiagram(image, resource) {
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
                    save("/dmsf/webdav/"+resource, msg.data);
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

function save(url, data) {
    if (url != null) {
        var req = new XMLHttpRequest();
        req.withCredentials = true;
        
        req.onreadystatechange = function() {
            if (req.readyState == 4) {
                if (req.status < 200 || req.status > 299) {
                    switch(req.status) {
                        case 409: 
                            alert('DMSF folder does not exists, diagram not saved');
                            break;
                        default:
                            alert('Error ' + req.status);
                    }
                }
            }
        };
        
        req.open('PUT', url, true);
        req.send(data);
    }
}
                    
