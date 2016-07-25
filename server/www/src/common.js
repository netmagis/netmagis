import React from 'react';

export var APIURL	= "/netmagis";
export var LOGIN_PAGE	= APIURL + "/files/login.html";
export var TODO_APIURL	= "http://130.79.91.54:82/www/html/api";

/* Same as $.ajax but defines some default values */
export var reqJSON = function (req) {
    var default_req = {
	dataType: 'json',
	mimeType: 'application/json',
	statusCode: {
	    401: function () { // Redirect when an auth error occurs
		window.location = LOGIN_PAGE ;
	    }
	}
    }

    // Overwrite the default request with the values provided
    $.ajax ($.extend (default_req, req)) ;
}


/* dotted-quad IP to integer */
export function IPv4_dotquadA_to_intA (strbits) {
    var split = strbits.split ('.', 4) ;
    var myInt = (
	parseFloat (split [0] << 24)		/* 2^24 */
        + parseFloat (split [1] << 16)		/* 2^16 */
        + parseFloat (split [2] << 8)		/* 2^8  */
        + parseFloat (split [3])
    ) ;
    return myInt;
}

/* integer IP to dotted-quad */
export function IPv4_intA_to_dotquadA (strnum) {
    var byte1 = (strnum >>> 24) ;
    var byte2 = (strnum >>> 16) & 0xff ;
    var byte3 = (strnum >>>  8) & 0xff ;
    var byte4 = strnum & 0xff ;
    return byte1 + '.' + byte2 + '.' + byte3 + '.' + byte4 ;
}

/* Add n to an IPv4 address */
export function add_to_IPv4 (ip,n) {
    return IPv4_intA_to_dotquadA (IPv4_dotquadA_to_intA (ip) + n) ;
}

/******************************************************************************
 * Language modification
 * (call is performed through the js returned by /menus API)
 */

export function setLang (l) {
    document.cookie = 'lang' + l + ';Path=' + APIURL ;
    duocument.location.reload (true) ;
}

/******************************************************************************
 * Installation of top-level menus
 */

export function dropdown (iconclass, data) {
    var i ;
    var menu = "" ;
    var icon = "" ;
    var js ;

    if (iconclass != "") {
	icon = '<span class="' + iconclass + '"></span> ' ;
    }

    menu = '<li class="dropdown">'
	    + '<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">'
	    + icon
	    + data.title
	    + '<span class="caret"></span>'
	    + '</a>'
	    + '<ul class="dropdown-menu">'
	    ;
    for (i = 0 ; i < data.items.length ; i++) {
	if (data.items [i].title == '') {
	  menu += '<li role="separator" class="divider"></li>'
	} else {
	  if (data.items [i].js != '') {
	    js = ' onclick="' + data.items [i].js + '"' ;
	  } else {
	    js = '' ;
	  }
	  menu += '<li><a href="'
	      + data.items [i].url
	      + '"'
	      + js
	      + '>'
	      + data.items [i].title
	      + '</a></li>'
	      ;
	}
    }
    menu += '</ul>'
    return menu ;
}

export function placeMenus (data, status) {
    var i ;
    var left = "" ;
    var srch = "" ;
    var right = "" ;

    /* left dropdowns */
    for (i = 0 ; i < data.left.length ; i++) {
	left += dropdown ('', data.left [i]) ;
    }
    $(left).replaceAll ("#nm-topleftmenu") ;

    /* search bar */
    if (data.search != null) {
	srch = '<form class="navbar-form navbar-left" role="search">'
	     + '<div class="form-group">'
	     + '<input type="text" class="form-control" placeholder="'
	     + data.search.title 
	     + '" aria-label="Search">'
	     + '</div>'
	     + '<button type="submit" class="btn btn-default">'
	     + '<span class="glyphicon glyphicon-search" aria-label="Submit"></span>'
	     + '</button>'
	     + '</form>'
	     ;
    }
    $(srch).replaceAll ("#nm-topsearchbar") ;

    /* user and language */
    if (data.user == null) {	/* not connected */
	right += '<li><p class="navbar-text">Not connected</p></li>'
    } else {
	right += dropdown ('glyphicon glyphicon-user', data.user) ;
    }

    right += dropdown ('', data.lang) ;
    $(right).replaceAll ("#nm-toprightmenu") ;
}


export function readyMenus () {
    $.get (APIURL + '/menus', placeMenus) ;
}

$(document).ready (readyMenus) ;
