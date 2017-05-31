CKEDITOR.plugins.add('drawio', {
    init: function(editor) {
        
        function defineDialog(macroName, options) {
            CKEDITOR.dialog.add("dlg_"+macroName, function(editor) {
                return {
                    title: options.dialogTitle,
                    minWidth: 240,
                    minHeight: 150,
                    contents: [{
                        id: 'defaultTab',
                        elements: [
                            {   id: "drawio_diagName",
                                type: "text",
                                label: Drawio.strings['drawio_cke_diagName' ],
                                labelLayout: 'horizontal',
                                size: 32,
                                required: !0,
                                validate: function() {
                                    return this.getValue() !== "";
                                }
                            },
                            {   id: 'drawio_diagType',
                                type: 'radio',
                                label: Drawio.strings['drawio_cke_diagType' ],
                                labelLayout: 'horizontal',
                                items: [['png'], ['svg']],
                                'default': 'png'
                            },
                            {   id: "drawio_diagSize",
                                type: "text",
                                label: Drawio.strings['drawio_cke_size'     ],
                                labelLayout: 'horizontal',
                                size: 4,
                                maxLength: 4,
                                validate: function() {
                                    return !!this.getValue().match(/^(\d+)?$/);
                                }
                            }
                        ]
                    }],
                    onOk: function() {
                        var diagName  = this.getValueOf('defaultTab', 'drawio_diagName');
                        var diagType  = this.getValueOf('defaultTab', 'drawio_diagType');
                        var size      = this.getValueOf('defaultTab', 'drawio_diagSize');
                        var sizeOpt    = "";
                        
                        if(/^\d+$/.test(size))
                            sizeOpt = ", size="+size;

                        diagName = diagName.replace(/^(.*?)(?:\.\w{3})?$/, "$1."+diagType);
                        editor.insertText('{{'+macroName+'('+diagName+sizeOpt+')}}');
                    }
                };
            });
            
            editor.addCommand('cmd_'+macroName, new CKEDITOR.dialogCommand('dlg_'+macroName));
            editor.ui.addButton( 'btn_'+macroName, {
                label  : options.buttonLabel,
                command: 'cmd_'+macroName,
                icon   : options.buttonIcon
            });
        }

        defineDialog('drawio_attach', {
            dialogTitle: Drawio.strings['drawio_cke_attach_dlgtitle'],
            buttonLabel: Drawio.strings['drawio_cke_attach_btnlabel'],
            buttonIcon : this.path+'/../../images/jstb_drawio_attach.png'
            
        });
        
        if(Drawio.settings.DMSF)
            defineDialog('drawio_dmsf', {
                dialogTitle: Drawio.strings['drawio_cke_dmsf_dlgtitle'],
                buttonLabel: Drawio.strings['drawio_cke_dmsf_btnlabel'],
                buttonIcon : this.path+'/../../images/jstb_drawio_dmsf.png'
            });
    }
});
