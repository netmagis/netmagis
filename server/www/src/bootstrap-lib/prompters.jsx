import React from 'react';
import ReactDOM from 'react-dom';
import * as C from '../common.js';


/**
 * Prompters is the object containing all the handlers that link the web
 * application to the API. Every handler is an object containing one or more 
 * functions and whathever things it needs in order to manage your suggestions. 
 * There are few things to know:
 *
 * - All the components in form-utils.jsx use their name property to identify the
 *   name of the handler that must be used. So make sure that handler exists (if not
 *   just write a new one) and it has all the functions required by the component.
 * 
 * - Here is a list of the functions needed and the components that need them.
 *
 *	- function { components }
 *
 *	- init(callback) { all }
 *		this function is called when the element
 *		is about to be mounted. Note that a component can request a 
 *		re-initialization at eny time. Use this function to retrieve the
 *		data from the API and call the callback once you are done
 *
 *	- getSuggestions(value) {AutoInput}
 *		this function take the actual value of the input and 
 *		must return an array of strings (suggestions).
 *		
 * 	- getValues() {AJXdropdown, Adropdown, Table}
 *		returns a list of all the possible values (ex. all the domains)
 *		For a dropdown it must be a list of strings, for a table it must
 *		return a list of objects where each object represent a row of that
 *		table, according with the `model` property of the table.
 *	- getEmptyRow() { Table }
 *		when a table will create a new empty row, it will ask to this function
 *		what should be the content of that new row
 *
 *	- save/update/delete(key, input) { Table }
 *		this functions create the link with the API to perform the action
 *		of saving/updating/deleting a given entity.
 *		The entity is identified by the argument key (ex: iddhpprof)
 *		and the data (if any) resides into the object input.
 *
 *		
 */

export var Prompters = {
	
	/*************************  Handler name="cidr" ***********************/
	cidr: { 
		/* Here will be stored all the network addresses */
		networks: [],

		/* Fill the networks array with the API answer */
		init : function (callback)  { 
			C.reqJSON({
				url: C.APIURL+'/networks',
				success: function(response){
					var networks = [];
					for (var i = 0; i < response.length; i++){
						networks.push(response[i]["addr4"]);
						networks.push(response[i]["addr6"]);
					}
					this.networks = networks;
					}.bind(this),
				complete: callback
			});
		},

		/* Case-insensitive suggestions based on the 
		   beginning of the addresses*/
		getSuggestions: function (value, callback){
			var inputValue = value.trim().toLowerCase();
			var inputLength = inputValue.length;

			if (inputLength === 0) return [];

			return this.networks.filter(function (network) {
		    		return network.toLowerCase().slice(0, inputLength) === inputValue;
		  	});
		},

		getValues: function (){
			return this.networks;
		}
	},

	/*************************  Handler name="hinfos" ***********************/

	hinfos: {
		machines: [],

		/* Fill the machines array with the API answer */
		init : function (callback)  { 
			C.reqJSON({
				url: C.APIURL+'/hinfos',
				success: function(response){
					this.machines = response;
				}.bind(this),
				complete: callback
			});
		},

		/* Gives all the machines */
		getValues: function (){
			return this.machines;
		}
	},

	/*************************  Handler name="hinfos_present" ***********************/

	hinfos_present: {
		machines: [],

		init : function (callback)  { 
			C.reqJSON({
				url: C.APIURL+'/hinfos?present=1', 
				success: function(response){
						this.machines = response.map( m => m.name );
					 }.bind(this),
				complete: callback
			});
		},

		getValues: function (){
			return this.machines;
		}

	},
			


	/*************************  Handler name="domain" ***********************/
		
	domain: {
		 domains: [],	// [{iddom: .. name: ..} , ...]
		_domains: [],	// [ "domain1", "domain2", ... ]

		init : function (callback)  { 
			C.reqJSON({
				url: C.APIURL+'/domains', 
				success: function(response){
						this.domains = response;
						var _domains = [];
						response.forEach(function(val){
							_domains.push(val.name);
						}.bind(this));
						this._domains = _domains;
					 }.bind(this),
				complete: callback
			});
		},

		getValues: function (){
			return this._domains;
		},

		id2Name: function (id){
			if ( id == undefined || id == null ) return "Unspecified";

			for (var i = 0; i < this.domains.length; i++){
				if (this.domains[i].iddom == id) {
					return this.domains[i].name;
				}
			}
		},

		name2Id: function (name){
			for (var i = 0; i < this.domains.length; i++){
				if (this.domains[i].name == name) {
					return this.domains[i].iddom;
				}
			}
		}
	},

	/*************************  Handler name="freeblocks" ***********************/
	freeblocks: {
		blocks: [],

		init: function(callback, params){
			C.reqJSON({
				url: '/freeblocks?'+$.param(params),
				success: function(res){
					this.blocks = res;
				}.bind(this),
				complete: callback
			});
		},

		getValues: function(){
			return this.blocks;
		}
	},
	/*************************  Handler name="addr" ***********************/

	addr: {
		addrs: [],

		makeIpv6: function (cidr){
			return cidr+"#TODO";
		},

		makeIpv4: function (cidr){
			var c_m = cidr.split("/");
			return C.add_to_IPv4(c_m[0],1);
		},

		init : function (callback) { 
			Prompters.cidr.init(function(){
				var cidrs = Prompters.cidr.getValues();
				for (var i = 0; i < cidrs.length; i++){
					var addr;
					if (cidrs[i].search(':') > 0){
						addr = this.makeIpv6(cidrs[i]);	
					} else {
						addr = this.makeIpv4(cidrs[i]);	
					}
					this.addrs.push(addr);
				}	
			}.bind(this));
		},

		getSuggestions: function (value){
			var inputValue = value.trim().toLowerCase();
			var inputLength = inputValue.length;

			if (inputLength === 0) return [];

			return this.addrs.filter(function (addr) {
		    		return addr.toLowerCase().slice(0, inputLength) === inputValue;
		  	});
		},

		/* Gives all the addresses */
		getValues: function (){
			return this.addrs;
		}
	},

	/*************************  Handler name="dhcprange" *******************/

	dhcprange: {

		dhcpranges: [],

		init : function (callback, params) { 
			C.reqJSON({
				url: C.APIURL+'/dhcpranges?'+$.param(params), 
				success: function(response){
						this.dhcpranges = response;
					}.bind(this),
				complete: callback
			});
		},

		/* Gives all the addresses */
		getValues: function (){
			return this.dhcpranges;
		}



	},
	
	/*************************  Handler name="dhcpprofiles" *******************/
	dhcpprofiles: {
		dhcpprofs : [],

		init : function (callback) { 
			C.reqJSON({
				url: C.APIURL+'/dhcpprofiles', 
				success: function(response){
						this.dhcpprofiles = response;
					 }.bind(this),
				complete: callback
			});
		},

		getValues: function (){
			return this.dhcpprofs;
		},

		id2Name: function (id){
			if ( id == undefined || id == null ) return "";

			for (var i = 0; i < this.dhcpprofs.length; i++){
				if (this.dhcpprofs[i].iddhcpprof == id) {
					return this.dhcpprofs[i].name;
				}
			}
		},

		name2Id: function (name){
			for (var i = 0; i < this.dhcpprofs.length; i++){
				if (this.dhcpprofs[i].name == name) {
					return this.dhcpprofs[i].iddhcpprof;
				}
			}

			return null;
		}

	},
	/*************************  Handler name="dhcp" *******************/

	row_dhcprange: {

		dhcp: [],

		init : function (callback,params) { 
			var _callback = function(){this._combine(callback);}.bind(this);

			var c = new CallbackCountdown(_callback,3); 

			Prompters.domain.init(c.callback);
			Prompters.dhcprange.init(c.callback,params);
			Prompters.dhcpprofiles.init(c.callback);
		},

		_combine: function (callback){
			var dhcpranges = Prompters.dhcprange.getValues();
			var domains = Prompters.domain.getValues();
			var dhcpprofiles = Prompters.dhcpprofiles.getValues();
			
			var dhcp = [];
			for (var i = 0; i < dhcpranges.length; i++){
		
				// OLD
				//var value_dom = Prompters.domain.id2Name(dhcpranges[i].iddom);
				var doms = { 'values': domains, 'value': dhcpranges[i].domain };

				// OLD
				//var value_dhcpprof = Prompters.dhcpprofiles.id2Name(dhcpranges[i].iddhcpprof);
				var dhcpprofs = { 'values': dhcpprofiles, 'value': dhcpranges[i].dhcpprofile };

				var cpy = $.extend({}, dhcpranges[i]);
				cpy.domain = doms; cpy.dhcpprof = dhcpprofs;
				dhcp.push(cpy);

			}
			this.dhcp = dhcp;


			callback();


		},

		/* Gives all the addresses */
		getValues: function (){
			return this.dhcp;
		},

		getEmptyRow: function(){
			return {'domain':  Prompters.domain.getValues(),
				'dhcpprof':  Prompters.dhcpprofiles.getValues()
			 };

		},

		datareqFromInput: function(input){
			// Convert domain and dhcpprof names to ids
			var iddom = Prompters.domain.name2Id(input.domain);
			var iddhcpprof = Prompters.dhcpprofiles.name2Id(input.dhcpprof);

			var data_req = $.extend({iddom: iddom, iddhcpprof: iddhcpprof}, input);
			delete data_req.domain; delete data_req.dhcpprof;

			// Cast to max_lease/default_lease to numeric values
			var max_lease = parseInt(data_req.max_lease_time);
			var def_lease = parseInt(data_req.default_lease_time);

			data_req.max_lease_time = isNaN(max_lease)? 0 : max_lease;
			data_req.default_lease_time = isNaN(def_lease)? 0 : def_lease;

			// Trim ips just to be nice with the user
			data_req.min = data_req.min.trim();
			data_req.max= data_req.max.trim();


			return data_req;
		},
			
		save: function(key, input, success, error){
			var data_req = this.datareqFromInput(input);

			C.reqJSON({
				method: 'POST',
				url: C.APIURL+"/dhcpranges",
				contentType: 'application/json',	
				data: JSON.stringify(data_req),
				success: success,
				error: error
			});

			
		},

		update: function(key, input, success, error){
			var data_req = this.datareqFromInput(input);

			C.reqJSON({
				method: 'PUT',
				url: C.APIURL+"/dhcpranges/"+key,
				data: JSON.stringify(data_req),
				contentType: 'application/json',	
				success: success,
				error: error
			});
		},

		delete: function(key, input, success, error){
			C.reqJSON({
				method: 'DELETE',
				url: C.APIURL+"/dhcpranges/"+key,
				success: success,
				error: error
			});
		}



	},


	/*************************  Handler name="views" *******************/
	views: {
		views: [],
		names: [],
	
		init: function (callback){
			C.reqJSON({
				url: C.APIURL+'/views', 
				success: function(response){
						this.views = response;
						this.names = [];
						response.map(function(x){
							this.names.push(x.name);}
							.bind(this));
					 }.bind(this),
				complete: callback
			});
		},

		getValues: function(){
			return this.names;
		},

		id2Name: function (id){
			for (var i = 0; i < this.views.length; i++){
				if (this.views[i].idview == id) {
					return this.views[i].name;
				}
			}
		},

		name2Id: function (name){
			for (var i = 0; i < this.views.length; i++){
				if (this.views[i].name == name) {
					return this.views[i].idview;
				}
			}
		}
		
	},
	/*************************  Handler name="dns_p_view" *******************/
	/* A group id must be specified */
	dns_p_view: {
		views: [],
	
		init: function (callback, params){
			C.reqJSON({
				url: C.APIURL+'/admin/dns.p_view/'+params.idgrp, 
				success: function(response){
						this.views = response;
					 }.bind(this),
				complete: callback
			});
		},

		getValues: function(){
			return this.views;
		}


		
	},

	/*************************  Handler name="allowed_views" *******************/

	allowed_views: {
		idgrp: undefined,
		aviews: [],

		init: function (callback, params){
				
			var _callback = function(){this._combine(callback);}.bind(this);

			var c = new CallbackCountdown(_callback,2); 

			Prompters.dns_p_view.init(c.callback,params);
			Prompters.views.init(c.callback);
		},

		_combine: function (callback){
			var v  = Prompters.dns_p_view.getValues();
			this.idgrp = v.idgrp;
			this.aviews = v.perm;

			for (var i = 0; i < this.aviews.length; i++){
				/* Add references to views for dropdown */
				this.aviews[i].view = {
					values: Prompters.views.getValues(),
					value: Prompters.views.id2Name(this.aviews[i].idview)
				}

				/* Add a custom key */
				this.aviews[i]._key = "nokey"+i;
			}
			callback();
		},

		getValues: function(){
			return this.aviews;
		},

		save: function(key, input, success, error){
			input.idview = Prompters.views.name2Id(input.view);
			input.idgrp = this.idgrp;
			input.view = {
				values: Prompters.views.getValues(),
				value: input.view
			}

			this.aviews.push(input);
			this.send(success,function(jqXHR){
				this.aviews.pop(); error(jqXHR);
				}.bind(this));
		},

		delete: function(key, input, success, error){
			for (var i = 0; i < this.aviews.length; i++){
				if (this.aviews[i]._key == key){
					bkp_row = this.aviews[i];
					this.aviews.splice(i,1);
					this.send(success,function(jqXHR){
							this.aviews.push(bkp_row);
							error(jqXHR);}.bind(this));
				}
			}
		},

		update: function(key, input, success, error){
			input.idview = Prompters.views.name2Id(input.view);
			input.idgrp = this.idgrp;
			input.view = {
				values: Prompters.views.getValues(),
				value: input.view
			}

			delete input.view;

			for (var i = 0; i < this.aviews.length; i++){
				if (this.aviews[i]._key == key){
					var bkp_row = this.aviews[i];
					this.aviews[i] = input;
					this.send(success,function(jqXHR){
							this.aviews[i] = bkp_row;
							error(jqXHR);
					}.bind(this));
					break;
				}
			}

		},

		send: function(success, error){
			/* Make a copy */
			var data_req = [];	
			for (var i = 0; i < this.aviews.length; i++){
				data_req.push({
					idgrp: this.aviews[i].idgrp,	
					idview: this.aviews[i].idview,	
					sort: this.aviews[i].sort,	
					selected: this.aviews[i].selected
				});
			}

			C.reqJSON({
				method: 'PUT',
				url: C.APIURL+"/admin/dns.p_view/"+this.idgrp,
				contentType: 'application/json',	
				data: JSON.stringify(data_req),
				success: success,
				error: error
			});
		}

	}


}

var CallbackCountdown = function (callback, n) {
	this.count = 0;
	this.n = n;
	this._callback = callback;
	this.callback = function(){
		this.count++;
		if (this.count >= this.n){
			return this._callback.apply(this, arguments);
		}
	}.bind(this);
}
	
	
