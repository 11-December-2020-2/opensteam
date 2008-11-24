function toggle_admin_display(name) {
    var els = getElementsByClassName("sub_content_box") ;

    for(var i=0;i< els.length ; i++)
    {
        els[i].style.display = "none" ;
    }

    var el = document.getElementById(name) ;
    if( el.style.display == "none" )
    {
        el.style.display = "" ;
    }
    else
    {
        el.style.display = "none" ;
    }
}


function getElementsByClassName(classname, node) {
    if(!node) node = document.getElementsByTagName("body")[0];
    var a = [];
    var re = new RegExp('\\b' + classname + '\\b');
    var els = node.getElementsByTagName("*");
    for(var i=0,j=els.length; i<j; i++)
        if(re.test(els[i].className))a.push(els[i]);
    return a;
}


function remove_filter(e) {
    e.element.remove() ;
}


function transform2ComboBox( el ) {
	if( typeof(el) == 'string')el=$(el)
    new Ext.form.ComboBox({
        typeAhead: true,
        triggerAction: 'all',
        transform: el,
        readonly: true,
        forceSelection: false,
        selectOnFocus: true
    }) ;
}