import React from 'react';
import ReactDOM from 'react-dom';
import {Translator, updateTranslations} from './lang.jsx';
import * as F from './bootstrap-lib/form-utils.jsx';


	
/** 
 * The input fields can be not defined ---> they will be rendered as empty
 */
var App = React.createClass({


	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},

	getInitialState: function (){
		return {cidr: ""};
	},

	model: { key: "iddhcprange",
		 desc: [ 
				[ "Min" , "Input" , "min"],
				[ "Max" , "Input" , "max"],
				[ "Domain" , "Dropdown" , "domain"],
				[ "Default lease duration", "Input", "default_lease_time"],
				[ "Maximum lease duration", "Input", "max_lease_time"],
			        [ "DHCP profile", "Dropdown", "dhcpprof"]
		]
	},
	
	changeNetwork: function (cidr){
		this.setState({cidr: cidr})
		
	},
		
	render: function () {
		return ( 
			<div>
				<F.Adropdown name="cidr" onChange={this.changeNetwork}
					     defaultValue="Select a network" />
				<F.Table model={this.model} 
					 name="row_dhcprange" 
					 params={{cidr: this.state.cidr}}
				/>
			</div>
		);

	}
});




/* Rendering the app on the node with id = 'app'
   change it in case of conflict   */

var dom_node = document.getElementById('app');

ReactDOM.render( <Translator> <App /> </Translator>, dom_node);



