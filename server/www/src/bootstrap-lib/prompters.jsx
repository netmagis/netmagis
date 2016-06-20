import React from 'react';
import ReactDOM from 'react-dom';
import * as C from '../common.js';


/**
 * Prompters is the object containing all the handlers that AutoInput
 * can use. Every handler is an object containing one or more functions 
 * and all the usefull stuffs you need in order to manage your suggestions. 
 * There are few things to know:
 *
 * - The name of the handler must correspond with the contents of 
 *   the `name` props passed to `AutoInput`
 * 
 * - Every handler must/can (see required/optional) contain the 
 *   following stuffs:
 *	- A function `init(callback)` (optional):
 *		this function will be called once when the element
 *		is about to be mounted.
 *	- A function `getSuggestions(value,callback)` (required if input):
 *		this function take the actual value of the input and 
 *		must return an array of suggestions
 * 	- A function `getValues()` (required if dropdown):
 *		same as getSuggestions but used for the dropdown
 *
 * TODO update this documentation
 */

export var Prompters = {
	
	/*************************  Handler name="cidr" ***********************/
	cidr: { 
		/* Here will be stored all the network addresses */
		networks: [],

		/* Fill the networks array with the API answer */
		init : function (callback)  { 
			C.getJSON(C.APIURL+'/networks', function(response){
				var networks = [];
				for (var i = 0; i < response.length; i++){
					networks.push(response[i]["addr4"]);
					networks.push(response[i]["addr6"]);
				}
				this.networks = networks;
			}.bind(this), callback);
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

	/*************************  Handler name="machine" ***********************/

	machines: {
		machines: [],

		/* Fill the machines array with the API answer */
		init : function (callback)  { 
			console.log("Getting from "+C.TODO_APIURL);
			C.getJSON(C.TODO_APIURL+'/machines', function(response){
					this.machines = response;
					
			}.bind(this), callback);
		},

		/* Gives all the machines */
		getValues: function (){
			return this.machines;
		}
	},


	/*************************  Handler name="domain" ***********************/
		
	domain: {
		 domains: [],	// [{iddom: .. name: ..} , ...]
		_domains: [],	// [ "domain1", "domain2", ... ]

		init : function (callback)  { 
			C.getJSON(C.APIURL+'/domains', function(response){
					this.domains = response;
					response.forEach(function(val){
						this._domains.push(val.name);
					}.bind(this));
					
			}.bind(this), callback);
		},

		getValues: function (){
			return this._domains;
		},

		id2Name: function (id){
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
				console.log(this.addrs);
		},

		getSuggestions: function (value, callback){
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

		init : function (callback) { 
			var cidr = "172.16.0.0/16"; //XXX retrive this value externally
			C.getJSON(C.APIURL+'/dhcpranges?cidr='+cidr, function(response){
					this.dhcpranges = response;
					
			}.bind(this), callback);
		},

		/* Gives all the addresses */
		getValues: function (){
			return this.dhcpranges;
		}



	},
	
	
	/*************************  Handler name="dhcp" *******************/

	dhcp: {

		/** TODO **/
		dhcp: [],

		init : function (callback) { 
			var _callback = function(){this._combine(callback);}.bind(this);

			var c = new CallbackCountdown(_callback,2); /* XXX This will be 3 */

			Prompters.domain.init(c.callback);
			Prompters.dhcprange.init(c.callback);
		},

		_combine: function (callback){
			var dhcpranges = Prompters.dhcprange.getValues();
			var domains = Prompters.domain.getValues();
			for (var i = 0; i < dhcpranges.length; i++){

				var value = Prompters.domain.id2Name(dhcpranges[i].iddom);
				var doms = { 'values': domains, 'value': value };
				var cpy = $.extend({'domain': doms}, dhcpranges[i]);
				this.dhcp.push(cpy);

			}

			callback();


		},

		/* Gives all the addresses */
		getValues: function (){
			return this.dhcp;
		},

		getEmptyRow: function(){
			return {'domain':  Prompters.domain.getValues() };
		},

		save: function(key, input){
			var iddom = Prompters.domain.name2Id(input.domain);
			var data_req = $.extend({iddom: iddom}, input);
			delete data_req.domain;
			console.log("--------- SAVE ----------");
			console.log("POST /api/dhcprange "+JSON.stringify(data_req));
			$.ajax({
				method: 'POST',
				url: C.APIURL+"/dhcpranges",
				data: JSON.stringify(data_req),
				contentType: 'application/json'
			});

			
		},

		update: function(key, input){
			var iddom = Prompters.domain.name2Id(input.domain);
			var data_req = $.extend({iddom: iddom}, input);
			delete data_req.domain;
			console.log("--------- UPDATE ----------");
			console.log("PUT /api/dhcpranges/"+key+" "+JSON.stringify(data_req));
			$.ajax({
				method: 'PUT',
				url: C.APIURL+"/dhcpranges/"+key,
				data: JSON.stringify(data_req),
				contentType: 'application/json'
			});
		},

		delete: function(key, input){
			console.log("--------- DELETE ----------");
			console.log("DELETE /api/dhcpranges/"+key);
			return;
			$.ajax({
				method: 'DELETE',
				url: C.APIURL+"/dhcpranges/"+key
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
	
	
