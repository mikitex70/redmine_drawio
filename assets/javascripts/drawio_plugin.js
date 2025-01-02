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
                                    return this.getValue() !== "";
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
                                    // 获取当前对话框实例
                                    var dialog = this.getDialog();
                                    var selectedType = this.getValue();
                                    
                                    // 调用更新附加选项显示逻辑
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
                                        type: 'hbox', // 使用 hbox 水平排列子控件
                                        widths: ['50%', '50%'], // 分别为标签和复选框设置宽度比率
                                        children: [
                                            {
                                                type: 'html',
                                                html: '<span>' + Drawio.strings['drawio_cke_toolbar_autohide'] + '</span>',
                                                style: 'text-align: left; width: 100%;' // 自定义标签样式
                                            },
                                            {
                                                type: 'checkbox',
                                                id: 'drawio_tbautohide',
                                                label: '', // 不在这里使用标签
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
                                        default: '100'
                                    },
                                    {
                                        type: 'text',
                                        id: 'drawio_page',
                                        label: Drawio.strings['drawio_cke_page'],
                                        labelLayout: 'horizontal'
                                    },
                                    {
                                        type: 'text',
                                        id: 'drawio_layers',
                                        label: Drawio.strings['drawio_cke_layers'],
                                        labelLayout: 'horizontal',
                                        default: ''
                                    },
                                    {
                                        type: 'text',
                                        id: 'drawio_hilight',
                                        label: Drawio.strings['drawio_cke_hiligh'],
                                        labelLayout: 'horizontal',
                                        default: '#0000ff'
                                    }
                                ],
                                style: 'display:none;' // 初始隐藏附加选项
                            }
                        ]
                    }],
                    onShow: function () {
                        var dialog = this;
                        var selectedType = dialog.getValueOf('defaultTab', 'drawio_diagType');
                        
                        // 初始化附加选项显示状态
                        updateExtraOptionsVisibility(dialog, selectedType);
                    },
                    onOk: function() {
                        var diagName = this.getValueOf('defaultTab', 'drawio_diagName');
                        var diagType = this.getValueOf('defaultTab', 'drawio_diagType');
                        var size = this.getValueOf('defaultTab', 'drawio_diagSize');

                        // 获取扩展属性值
                        var tbAutoHide = this.getValueOf('defaultTab', 'drawio_tbautohide');
                        var zoom = this.getValueOf('defaultTab', 'drawio_zoom');
                        var initialZoom = this.getValueOf('defaultTab', 'drawio_initialzoom');
                        var lightbox = this.getValueOf('defaultTab', 'drawio_lightbox');
                        var layers = this.getValueOf('defaultTab', 'drawio_layers');
                        var page = this.getValueOf('defaultTab', 'drawio_page');
                        var hilight = this.getValueOf('defaultTab', 'drawio_hilight');
                        // 打印所有获取的值
                        /*
                        console.log("diagName:", diagName);
                        console.log("diagType:", diagType);
                        console.log("size:", size);
                        console.log("zoom:", zoom);
                        console.log("initialZoom:", initialZoom);
                        console.log("lightbox:", lightbox);
                        console.log("layers:", layers);
                        console.log("page:", page);
                        console.log("hilight:", hilight);
                        */

                        // 构造宏内容
                        diagName = diagName.replace(/^(.*?)(?:\.\w{3})?$/, "$1." + diagType);

                        var macroOptions = [];
                        if (size) macroOptions.push("size=" + size);
                        if (tbAutoHide) macroOptions.push("tbautohide=true"); // 仅当 tbAutoHide 为 true 时附加
                        if (zoom) macroOptions.push("zoom=true"); // 仅当 zoom 为 true 时附加
                        if (initialZoom) macroOptions.push("initialzoom=" + initialZoom);
                        if (lightbox) macroOptions.push("lightbox=true"); // 仅当 lightbox 为 true 时附加
                        if (layers) macroOptions.push("layers=" + layers);
                        if (page) macroOptions.push("page=" + page);
                        if (hilight) macroOptions.push("hilight=" + hilight);

                        // 拼接最终宏内容
                        var macroContent = "{{" + macroName + "(" + diagName;
                        if (macroOptions.length > 0) {
                            macroContent += ", " + macroOptions.join(", ");
                        }
                        macroContent += ")}}";

                        // debug info
                        //console.log("Generated Macro Content:", macroContent);

                        // 插入宏到编辑器
                        editor.insertText(macroContent);
                    }
                };
            });

            // 添加按钮命令
            editor.addCommand('cmd_' + macroName, new CKEDITOR.dialogCommand('dlg_' + macroName));
            editor.ui.addButton('btn_' + macroName, {
                label: options.buttonLabel,
                command: 'cmd_' + macroName,
                icon: options.buttonIcon
            });
        }

        // 定义 drawio_attach 对话框
        defineDialog('drawio_attach', {
            dialogTitle: Drawio.strings['drawio_cke_attach_dlgtitle'],
            buttonLabel: Drawio.strings['drawio_cke_attach_btnlabel'],
            buttonIcon: this.path + '/../../images/jstb_drawio_attach.png'
        });

        // 如果启用了 DMSF，定义 drawio_dmsf 对话框
        if (Drawio.settings.DMSF) {
            defineDialog('drawio_dmsf', {
                dialogTitle: Drawio.strings['drawio_cke_dmsf_dlgtitle'],
                buttonLabel: Drawio.strings['drawio_cke_dmsf_btnlabel'],
                buttonIcon: this.path + '/../../images/jstb_drawio_dmsf.png'
            });
        }

        // 更新附加选项的显示逻辑
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
