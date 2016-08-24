import React from 'react' ;
import ReactDOM from 'react-dom' ;
import * as C from '../common.js' ;

/**
 * Prompters is the object containing all the handlers that link the web
 * application to the API. Every handler is an object containing one
 * or more functions and whathever it needs in order to manage suggestions.
 *
 * Notes:
 * - All components in form-utils.jsx use their name property to
 *	identify the name of the handler that must be used.
 *	So make sure that handler exists (if not, one must just write
 *	a new one) and it has all the functions required by the component.
 *
 * - List of the functions needed and the components that need them:
 *	- function { components }
 *	- init (callback) { all }
 *		this function is called when the element is about to
 *		be mounted. A component may request a re-initialization
 *		at any time. This function is used to retrieve data
 *		from the API and call the callback once it is done.
 *	- getSuggestions (value) {AutoInput}
 *		this function takes the actual value of the input and
 *		must return an array of strings (suggestions).
 * 	- getValues () {AJXdropdown, Adropdown, Table}
 *		returns a list of all the possible values (e.g. all domains).
 *		For a dropdown it must be a list of strings,
 *		for a table it must return a list of objects where each
 *		object represents a row of this table, according to the
 *		`model` property of the table.
 *	- getEmptyRow () { Table }
 *		when a table needs to create a new empty row, this function
 *		should return the content of this new row
 *	- save/update/delete (key, input) { Table }
 *		these functions create the link with the API to perform
 *		the action. Entity is identified by the argument `key`
 *		(ex: iddhpprof) and the data (if any) is in the object input.
 */

export var Prompters = {
    /*************************************************************************/
    cidr: {
	/* array to store available network addresses */
	networks: [],

	/* fill the `networks` array with the API answer */
	init : function (callback)  {
	    C.reqJSON ({
		url: C.APIURL + '/networks',
		success: function (response) {
			var networks = [] ;
			for (var i = 0 ; i < response.length ; i++) {
				networks.push (response [i]["addr4"]) ;
				networks.push (response [i]["addr6"]) ;
			}
			this.networks = networks ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	/* case-insensitive suggestions based on address first chars (value) */
	getSuggestions: function (value, callback) {
	    var iVal = value.trim ().toLowerCase () ;	// input value
	    var iLen = inputValue.length ;		// input length
	    if (iLen === 0)
		return [] ;
	    return this.networks.filter (function (network) {
		    return network.toLowerCase ().slice (0, iLen) === iVal ;
	    }) ;
	},

	getValues: function () {
	    return this.networks ;
	}
    },

    /*************************************************************************/
    hinfos: {
	machines: [],

	init : function (callback) {
	    C.reqJSON ({
		url: C.APIURL+'/hinfos',
		success: function (response) {
			this.machines = response ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	getValues: function () {
	    return this.machines ;
	}
    },

    /*************************************************************************/
    hinfos_present: {
	machines: [],

	init : function (callback) {
	    C.reqJSON ({
		url: C.APIURL + '/hinfos?present=1',
		success: function (response) {
			this.machines = response.map (m => m.name) ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	getValues: function () {
	    return this.machines ;
	}
    },

    /*************************************************************************/
    domain: {
	domains: [],		// [ {iddom: .. name: ..} , ...]
	_domains: [],		// [ "domain1", "domain2", ... ]

	init : function (callback) {
	    C.reqJSON ({
		url: C.APIURL + '/domains',
		success: function (response) {
			this.domains = response ;
			var _domains = [] ;
			response.forEach (function (val) {
			    _domains.push (val.name) ;
			}.bind (this)) ;
			this._domains = _domains ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	getValues: function () {
	    return this._domains ;
	},

	id2Name: function (id) {
	    if (id == undefined || id == null)
		return "Unspecified" ;
	    for (var i = 0 ; i < this.domains.length ; i++) {
		if (this.domains[i].iddom == id) {
		    return this.domains[i].name ;
		}
	    }
	},

	name2Id: function (name) {
	    for (var i = 0 ; i < this.domains.length ; i++) {
		if (this.domains[i].name == name) {
		    return this.domains[i].iddom ;
		}
	    }
	}
    },

    /*************************************************************************/
    freeblocks: {
	blocks: [],

	init: function (callback, params) {
	    C.reqJSON ({
		url: C.APIURL + '/freeblocks?' + $.param (params),
		success: function (res) {
			this.blocks = res ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	getValues: function () {
	    return this.blocks ;
	}
    },

    /*************************************************************************/
    addr: {
	addrs: [],

	makeIpv6: function (cidr) {
	    return cidr + "#TODO" ;
	},

	makeIpv4: function (cidr) {
	    var c_m = cidr.split ("/") ;
	    return C.add_to_IPv4 (c_m [0], 1) ;
	},

	init: function (callback) {
	    Prompters.cidr.init (function () {
		var cidrs = Prompters.cidr.getValues () ;
		for (var i = 0 ; i < cidrs.length ; i++) {
		    var addr ;
		    if (cidrs [i].search (':') > 0) {
			addr = this.makeIpv6 (cidrs [i]) ;
		    } else {
			addr = this.makeIpv4 (cidrs [i]) ;
		    }
		    this.addrs.push (addr) ;
		}
	    }.bind (this)) ;
	},

	getSuggestions: function (value) {
	    var iVal = value.trim ().toLowerCase () ;
	    var iLen = iVal.length ;

	    if (iLen === 0)
		return [] ;

	    return this.addrs.filter (function (addr) {
		return addr.toLowerCase ().slice (0, iLen) === iVal ;
	    }) ;
	},

	/* Gives all the addresses */
	getValues: function () {
	    return this.addrs ;
	}
    },

    /*************************************************************************/
    dhcprange: {
	dhcpranges: [],

	init: function (callback, params) {
	    C.reqJSON ({
		url: C.APIURL + '/dhcpranges?' + $.param (params),
		success: function (response) {
			this.dhcpranges = response ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	/* Gives all the addresses */
	getValues: function () {
	    return this.dhcpranges ;
	}
    },

    /*************************************************************************/
    dhcpprofiles: {
	dhcpprofs : [],

	init : function (callback) {
	    C.reqJSON ({
		url: C.APIURL + '/dhcpprofiles',
		success: function (response) {
			this.dhcpprofiles = response ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	getValues: function () {
	    return this.dhcpprofs ;
	},

	id2Name: function (id) {
	    if (id == undefined || id == null)
		return "" ;

	    for (var i = 0 ; i < this.dhcpprofs.length ; i++) {
		if (this.dhcpprofs [i].iddhcpprof == id) {
		    return this.dhcpprofs [i].name ;
		}
	    }
	},

	name2Id: function (name) {
	    for (var i = 0 ; i < this.dhcpprofs.length ; i++) {
		if (this.dhcpprofs[i].name == name) {
		    return this.dhcpprofs[i].iddhcpprof ;
		}
	    }
	    return null ;
	}
    },

    /*************************************************************************/
    row_dhcprange: {
	dhcp: [],

	init : function (callback, params) {
	    var _callback = function () {
		    this._combine (callback) ;
		}.bind (this) ;
	    var c = new CallbackCountdown (_callback,3) ;

	    Prompters.domain.init (c.callback) ;
	    Prompters.dhcprange.init (c.callback, params) ;
	    Prompters.dhcpprofiles.init (c.callback) ;
	},

	_combine: function (callback) {
	    var dhcpranges = Prompters.dhcprange.getValues () ;
	    var domains = Prompters.domain.getValues () ;
	    var dhcpprofiles = Prompters.dhcpprofiles.getValues () ;

	    var dhcp = [] ;
	    for (var i = 0 ; i < dhcpranges.length ; i++) {

		// OLD
		//var value_dom = Prompters.domain.id2Name (dhcpranges[i].iddom) ;
		var doms = {
		    'values': domains,
		    'value': dhcpranges[i].domain
		} ;

		// OLD
		//var value_dhcpprof = Prompters.dhcpprofiles.id2Name (dhcpranges[i].iddhcpprof) ;
		var dhcpprofs = {
		    'values': dhcpprofiles,
		    'value': dhcpranges[i].dhcpprofile
		} ;

		var cpy = $.extend ({}, dhcpranges [i]) ;
		cpy.domain = doms ;
		cpy.dhcpprof = dhcpprofs ;
		dhcp.push (cpy) ;
	    }
	    this.dhcp = dhcp ;
	    callback () ;
	},

	/* Gives all the addresses */
	getValues: function () {
	    return this.dhcp ;
	},

	getEmptyRow: function () {
	    return {
		'domain':  Prompters.domain.getValues (),
		'dhcpprof':  Prompters.dhcpprofiles.getValues ()
	    } ;
	},

	datareqFromInput: function (input) {
	    // Convert domain and dhcpprof names to ids
	    var iddom = Prompters.domain.name2Id (input.domain) ;
	    var iddhcpprof = Prompters.dhcpprofiles.name2Id (input.dhcpprof) ;
	    var data_req = $.extend ({iddom: iddom, iddhcpprof: iddhcpprof}, input) ;
	    delete data_req.domain ;
	    delete data_req.dhcpprof ;

	    // Cast to max_lease/default_lease to numeric values
	    var max_lease = parseInt (data_req.max_lease_time) ;
	    var def_lease = parseInt (data_req.default_lease_time) ;

	    data_req.max_lease_time = isNaN (max_lease)? 0 : max_lease ;
	    data_req.default_lease_time = isNaN (def_lease)? 0 : def_lease ;

	    // Trim to be nice with the user
	    data_req.min = data_req.min.trim () ;
	    data_req.max= data_req.max.trim () ;

	    return data_req ;
	},

	save: function (key, input, success, error) {
	    var data_req = this.datareqFromInput (input) ;
	    C.reqJSON ({
		method: 'POST',
		url: C.APIURL + "/dhcpranges",
		contentType: 'application/json',
		data: JSON.stringify (data_req),
		success: success,
		error: error
	    }) ;
	},

	update: function (key, input, success, error) {
	    var data_req = this.datareqFromInput (input) ;
	    C.reqJSON ({
		method: 'PUT',
		url: C.APIURL + "/dhcpranges/" + key,
		data: JSON.stringify (data_req),
		contentType: 'application/json',
		success: success,
		error: error
	    }) ;
	},

	delete: function (key, input, success, error) {
	    C.reqJSON ({
		method: 'DELETE',
		url: C.APIURL + "/dhcpranges/" + key,
		success: success,
		error: error
	    }) ;
	}
    },

    /*************************************************************************/
    views: {
	views: [],
	names: [],

	init: function (callback) {
	    C.reqJSON ({
		url: C.APIURL + '/views',
		success: function (response) {
			this.views = response ;
			this.names = [] ;
			response.map (function (x) {
			    this.names.push (x.name) ;
			}.bind (this)) ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	getValues: function () {
	    return this.names ;
	},

	id2Name: function (id) {
	    for (var i = 0 ; i < this.views.length ; i++) {
		if (this.views[i].idview == id) {
		    return this.views [i].name ;
		}
	    }
	},

	name2Id: function (name) {
	    for (var i = 0 ; i < this.views.length ; i++) {
		if (this.views [i].name == name) {
		    return this.views [i].idview ;
		}
	    }
	}
    },

    /*************************************************************************/
    dns_p_view: {
	views: [],

	/* A group id must be specified in params.idgrp */
	init: function (callback, params) {
	    C.reqJSON ({
		url: C.APIURL + '/admin/dns.p_view/' + params.idgrp,
		success: function (response) {
			this.views = response ;
		    }.bind (this),
		complete: callback
	    }) ;
	},

	getValues: function () {
		return this.views ;
	}
    },

    /*************************************************************************/
    allowed_views: {
	idgrp: undefined,
	aviews: [],

	init: function (callback, params) {
	    var _callback = function () {
		    this._combine (callback) ;
		}.bind (this) ;
	    var c = new CallbackCountdown (_callback, 2) ;

	    Prompters.dns_p_view.init (c.callback, params) ;
	    Prompters.views.init (c.callback) ;
	},

	_combine: function (callback) {
	    var v  = Prompters.dns_p_view.getValues () ;
	    this.idgrp = v.idgrp ;
	    this.aviews = v.perm ;
	    for (var i = 0 ; i < this.aviews.length ; i++) {
		    /* Add references to views for dropdown */
		    this.aviews [i].view = {
			values: Prompters.views.getValues (),
			value: Prompters.views.id2Name (this.aviews [i].idview)
		    }
		    /* Add a custom key */
		    this.aviews[i]._key = "nokey" + i ;
	    }
	    callback () ;
	},

	getValues: function () {
	    return this.aviews ;
	},

	save: function (key, input, success, error) {
	    input.idview = Prompters.views.name2Id (input.view) ;
	    input.idgrp = this.idgrp ;
	    input.view = {
		values: Prompters.views.getValues (),
		value: input.view
	    }

	    this.aviews.push (input) ;
	    this.send (success,function (jqXHR) {
		    this.aviews.pop () ; error (jqXHR) ;
		}.bind (this)) ;
	},

	delete: function (key, input, success, error) {
	    for (var i = 0 ; i < this.aviews.length ; i++) {
		if (this.aviews[i]._key == key) {
		    var bkp_row = this.aviews[i] ;
		    this.aviews.splice (i,1) ;
		    this.send (success, function (jqXHR) {
			    this.aviews.push (bkp_row) ;
			    error (jqXHR) ;
			}.bind (this)) ;
		}
	    }
	},

	update: function (key, input, success, error) {
	    input.idview = Prompters.views.name2Id (input.view) ;
	    input.idgrp = this.idgrp ;
	    input.view = {
		values: Prompters.views.getValues (),
		value: input.view
	    }

	    delete input.view ;

	    for (var i = 0 ; i < this.aviews.length ; i++) {
		if (this.aviews [i]._key == key) {
		    var bkp_row = this.aviews [i] ;
		    this.aviews [i] = input ;
		    this.send (success,function (jqXHR) {
			    this.aviews [i] = bkp_row ;
			    error (jqXHR) ;
			}.bind (this)) ;
		    break ;
		}
	    }
	},

	send: function (success, error) {
	    /* Make a copy */
	    var data_req = [] ;
	    for (var i = 0 ; i < this.aviews.length ; i++) {
		data_req.push ({
		    idgrp: this.aviews [i].idgrp,
		    idview: this.aviews [i].idview,
		    sort: this.aviews [i].sort,
		    selected: this.aviews [i].selected
		}) ;
	    }
	    C.reqJSON ({
		method: 'PUT',
		url: C.APIURL + "/admin/dns.p_view/" + this.idgrp,
		contentType: 'application/json',
		data: JSON.stringify (data_req),
		success: success,
		error: error
	    }) ;
	}
    }
}

var CallbackCountdown = function (callback, n) {
    this.count = 0 ;
    this.n = n ;
    this._callback = callback ;
    this.callback = function () {
	    this.count++ ;
	    if (this.count >= this.n) {
		return this._callback.apply (this, arguments) ;
	    }
	}.bind (this) ;
}
