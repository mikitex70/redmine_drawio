CKEDITOR.plugins.add('drawio', {
    init: function (editor) {
        function defineDialog(macroName, options) {
            CKEDITOR.dialog.add("dlg_" + macroName, function (editor) {
                return {
                    title: options.dialogTitle,
                    minWidth: 240,
                    minHeight: 150,
                    contents: [{
                        id: 'defaultTab',
                        elements: [
                            {
                                id: "drawio_diagName",
                                type: "text",
                                label: Drawio.strings['drawio_cke_diagName'],
                                labelLayout: 'horizontal',
                                size: 32,
                                required: true,
                                validate: function () {
                                    // Validate the diagram name:
                                    // * must start with a letter, a digit or an underscore
                                    // * may contain one or more dots (but not at start of the name
                                    // * may contain a '/' for path separator, for saving in a DMSF folder
                                    // * cannot end with a '/'
                                    // The regex can be checked with https://regex101.com
                                    return !!this.getValue().match(/^[a-zA-Z0-9_][a-zA-Z0-9_\-.]*(\/[a-zA-Z0-9_][a-zA-Z0-9_\-.]*)*$/);
                                }
                            },
                            {
                                id: 'drawio_diagType',
                                type: 'radio',
                                label: Drawio.strings['drawio_cke_diagType'],
                                labelLayout: 'horizontal',
                                items: [['png'], ['svg'], ['xml'], ['drawio']],
                                'default': 'png',
                                onChange: function () {
                                    // Get the instance of the current dialog box
                                    var dialog = this.getDialog();
                                    var selectedType = this.getValue();
                                    
                                    // Show the additional options, if it is the case
                                    updateExtraOptionsVisibility(dialog, selectedType);
                                }
                            },
                            {
                                id: "drawio_diagSize",
                                type: "text",
                                label: Drawio.strings['drawio_cke_size'],
                                labelLayout: 'horizontal',
                                size: 4,
                                maxLength: 4,
                                default: '',
                                validate: function () {
                                    return !!this.getValue().match(/^(\d+)?$/);
                                }
                            },
                            {
                                id: 'extraOptions',
                                type: 'vbox',
                                widths: ['80%', '20%'],
                                children: [
                                    {
                                        type: 'hbox',           // Horizontal alignment of child controls with hbox
                                        widths: ['50%', '50%'], // Set width ratios for labels and checkboxes respectively
                                        children: [
                                            {
                                                type: 'html',
                                                html: '<span>' + Drawio.strings['drawio_cke_toolbar_autohide'] + '</span>',
                                                style: 'text-align: left; width: 100%;'  // Custom label styles
                                            },
                                            {
                                                type: 'checkbox',
                                                id: 'drawio_tbautohide',
                                                label: '',  // Do not show the label here
                                                default: true
                                            }
                                        ]
                                    },
                                    {
                                        type: 'hbox',
                                        widths: ['50%', '50%'],
                                        children: [
                                            {
                                                type: 'html',
                                                html: '<span>' + Drawio.strings['drawio_cke_lightbox'] + '</span>',
                                                style: 'text-align: left; width: 100%;'
                                            },
                                            {
                                                type: 'checkbox',
                                                id: 'drawio_lightbox',
                                                label: '',
                                                default: false
                                            }
                                        ]
                                    },
                                    {
                                        type: 'hbox',
                                        widths: ['50%', '50%'],
                                        children: [
                                            {
                                                type: 'html',
                                                html: '<span>' + Drawio.strings['drawio_cke_zoom'] + '</span>',
                                                style: 'text-align: left; width: 100%;'
                                            },
                                            {
                                                type: 'checkbox',
                                                id: 'drawio_zoom',
                                                label: '',
                                                default: false
                                            }
                                        ]
                                    },
                                    {
                                        type: 'text',
                                        id: 'drawio_initialzoom',
                                        label: Drawio.strings['drawio_cke_initialZoom'],
                                        labelLayout: 'horizontal',
                                        maxLength: 3,
                                        default: '100',
                                        validate: function () {
                                            return !!this.getValue().match(/^(100|[1-9]?[0-9])$/);
                                        }
                                    },
                                    {
                                        type: 'text',
                                        id: 'drawio_page',
                                        label: Drawio.strings['drawio_cke_page'],
                                        labelLayout: 'horizontal',
                                        default: '',
                                        validate: function () {
                                            return !!this.getValue().match(/^(\d+)?$/);
                                        }
                                    },
                                    {
                                        type: 'text',
                                        id: 'drawio_layers',
                                        label: Drawio.strings['drawio_cke_layers'],
                                        labelLayout: 'horizontal',
                                        default: '',
                                        validate: function () {
                                            return !!this.getValue().match(/^(\d+)?$/);
                                        }
                                    },
                                    {
                                        type: 'text',
                                        id: 'drawio_hilight',
                                        label: Drawio.strings['drawio_cke_hiligh'],
                                        labelLayout: 'horizontal',
                                        default: '#0000ff',
                                        validate: function () {
                                            return !!this.getValue().match(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/);
                                        }
                                    }
                                ],
                                style: 'display:none;' // Initially hide additional options
                            }
                        ]
                    }],
                    onShow: function () {
                        var dialog = this;
                        var selectedType = dialog.getValueOf('defaultTab', 'drawio_diagType');
                        
                        // Show the additional options, if it is the case
                        updateExtraOptionsVisibility(dialog, selectedType);
                    },
                    onOk: function() {
                        var diagName = this.getValueOf('defaultTab', 'drawio_diagName');
                        var diagType = this.getValueOf('defaultTab', 'drawio_diagType');
                        var size     = this.getValueOf('defaultTab', 'drawio_diagSize');
                        // Retrieve the extended attribute values
                        var tbAutoHide  = this.getValueOf('defaultTab', 'drawio_tbautohide');
                        var zoom        = this.getValueOf('defaultTab', 'drawio_zoom');
                        var initialZoom = this.getValueOf('defaultTab', 'drawio_initialzoom');
                        var lightbox    = this.getValueOf('defaultTab', 'drawio_lightbox');
                        var layers      = this.getValueOf('defaultTab', 'drawio_layers');
                        var page        = this.getValueOf('defaultTab', 'drawio_page');
                        var hilight     = this.getValueOf('defaultTab', 'drawio_hilight');

                        // Construction of the content of the macro
                        diagName = diagName.replace(/^(.*?)(?:\.\w{3})?$/, "$1." + diagType);

                        var macroOptions = [];

                        if (size)        macroOptions.push("size=" + size);
                        if (tbAutoHide)  macroOptions.push("tbautohide=true"); // Add only if tbAutoHide is true
                        if (zoom)        macroOptions.push("zoom=true");       // Add only if zoom is true
                        if (initialZoom) macroOptions.push("initialzoom=" + initialZoom);
                        if (lightbox)    macroOptions.push("lightbox=true");   // Add only if lightbox is true
                        if (layers)      macroOptions.push("layers=" + layers);
                        if (page)        macroOptions.push("page=" + page);
                        if (hilight)     macroOptions.push("hilight=" + hilight);

                        // Build the macro text
                        //var macroContent;

                        //if (diagType === "xml" || diagType === "drawio") {
                        var macroContent = "{{" + macroName + "(" + diagName;

                        if (macroOptions.length > 0) {
                            macroContent += ", " + macroOptions.join(", ");
                        }
                        macroContent += ")}}";
                        /*} else {
                            // Splicing with diagName and size parameters
                            macroContent = "{{" + macroName + "(" + diagName;

                            if (size) {
                                macroContent += ", size=" + size;
                            }
                            macroContent += ")}}";
                        }*/

                        // debug info
                        //console.log("Generated Macro Content:", macroContent);

                        // Insert the macro in the editor
                        editor.insertText(macroContent);
                    }
                };
            });

            // Define the button command
            editor.addCommand('cmd_' + macroName, new CKEDITOR.dialogCommand('dlg_' + macroName));
            editor.ui.addButton('btn_' + macroName, {
                label: options.buttonLabel,
                command: 'cmd_' + macroName,
                icon: options.buttonIcon
            });
        }

        // Define the drawio_attach dialog box
        defineDialog('drawio_attach', {
            dialogTitle: Drawio.strings['drawio_cke_attach_dlgtitle'],
            buttonLabel: Drawio.strings['drawio_cke_attach_btnlabel'],
            buttonIcon: this.path + '/../../images/jstb_drawio_attach.png'
        });

        // If DMSF is enabled, define the drawio_dmsf dialog box.
        if (Drawio.settings.DMSF) {
            defineDialog('drawio_dmsf', {
                dialogTitle: Drawio.strings['drawio_cke_dmsf_dlgtitle'],
                buttonLabel: Drawio.strings['drawio_cke_dmsf_btnlabel'],
                buttonIcon: this.path + '/../../images/jstb_drawio_dmsf.png'
            });
        }

        /**
         * Hides/show extra options if the diagram type is an XML format.
         *
         * @param dialog       Dialog to update
         * @param selectedType Type of diagram selected in the dialog
         */
        function updateExtraOptionsVisibility(dialog, selectedType) {
            var extraOptions = dialog.getContentElement('defaultTab', 'extraOptions');

            if (extraOptions) {
                if (selectedType === 'xml' || selectedType === 'drawio') {
                    extraOptions.getElement().setStyle('display', '');
                } else {
                    extraOptions.getElement().setStyle('display', 'none');
                }
            }
        }
    }
});
