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

				var value_dom = Prompters.domain.id2Name(dhcpranges[i].iddom);
				var doms = { 'values': domains, 'value': value_dom };

				var value_dhcpprof = Prompters.dhcpprofiles.id2Name(dhcpranges[i].iddhcpprof);
				var dhcpprofs = { 'values': dhcpprofiles, 'value': value_dhcpprof };

				var cpy = $.extend({'domain': doms, 'dhcpprof': dhcpprofs}, dhcpranges[i]);
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

		save: function(key, input, success, error){
			var iddom = Prompters.domain.name2Id(input.domain);
			var iddhcpprof = Prompters.dhcpprofiles.name2Id(input.dhcpprof);

			var data_req = $.extend({iddom: iddom, iddhcpprof: iddhcpprof}, input);
			delete data_req.domain; delete data_req.dhcpprof;

			var max_lease = parseInt(data_req.max_lease_time);
			var def_lease = parseInt(data_req.default_lease_time);

			data_req.max_lease_time = isNaN(max_lease)? 0 : max_lease;
			data_req.default_lease_time = isNaN(def_lease)? 0 : def_lease;


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
			var iddom = Prompters.domain.name2Id(input.domain);
			var iddhcpprof = Prompters.dhcpprofiles.name2Id(input.dhcpprof);

			var data_req = $.extend({iddom: iddom, iddhcpprof: iddhcpprof}, input);
			delete data_req.domain; delete data_req.dhcpprof;

			var max_lease = parseInt(data_req.max_lease_time);
			var def_lease = parseInt(data_req.default_lease_time);

			data_req.max_lease_time = isNaN(max_lease)? 0 : max_lease;
			data_req.default_lease_time = isNaN(def_lease)? 0 : def_lease;

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
	
	
