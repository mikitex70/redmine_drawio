$(function() {
    var cbxMatchjax   = $('#settings_drawio_mathjax');
    var txtMathJaxUrl = $('#settings_drawio_mathjax_url');
    
    cbxMatchjax.change(function() {
        txtMathJaxUrl.prop('readonly', !cbxMatchjax.is(":checked"));
    });
});
