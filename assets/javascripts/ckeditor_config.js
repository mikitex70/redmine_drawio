var basePath = CKEDITOR.basePath;

basePath = basePath.substr(0, basePath.indexOf("plugin_assets")+"plugin_assets".length);   
basePath = basePath.replace(/https?:\/\/[^\/]+/, "");
CKEDITOR.plugins.addExternal('drawio', basePath+'/redmine_drawio/javascripts/', 'drawio_plugin.js');

CKEDITOR.editorConfig = function(config) {
    var _extraPlugins  = config.extraPlugins || '';
    var _toolbar       = config.toolbar || [];
    var drawio_toolbar = [['btn_drawio_attach', 'btn_drawio_dmsf']];
    
    // Workaround for the configuration override.
    // The Redmine CKEditor plugin has its own config.js that resets 
    // any change to the extraPlugins property.
    // This code implements a setter on the config.extraPlugins property
    // so the new value is not replaced but instead appended to the
    // existing value. It is supported by the major modern browser (for
    // example from IE 9).
    Object.defineProperty(config, 'extraPlugins', { 
        get: function() { return _extraPlugins; },
        set: function(newValue) {
            if(_extraPlugins === '')
                _extraPlugins = newValue;
            else
                _extraPlugins += ','+newValue;
        }
    });
    // Same as before, but this time I want the drawio toolbar appended
    // after the default toolbar
    Object.defineProperty(config, 'toolbar', {
        get: function() { return _toolbar.concat(drawio_toolbar); },
        set: function(newValue) {
            _toolbar = newValue;
        }
    });
    config.extraPlugins = 'drawio';
}
