import React from 'react';
import ReactDOM from 'react-dom';
import {Translator, updateTranslations} from './lang.jsx';
import * as F from './bootstrap-lib/form-utils.jsx';


	

var App = React.createClass({


	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},

	getInitialState: function (){
		return {idgrp: 1};
	},

	model: { key: "_key",
		 desc: [ 
				[ "Sort class" , "Input" , "sort"],
				[ "Name" , "Dropdown" , "view"],
				[ "Select def" , "Checkbox" , "selected"]
		]
	},
	
	render: function () {
		return ( 
			<div>
				<F.Table model={this.model} 
					 name="allowed_views" 
					 params={{idgrp: this.state.idgrp}}
				/>
			</div>
		);

	}
});



/* Rendering the app on the node with id = 'app'
   change it in case of conflict   */

var dom_node = document.getElementById('app');

ReactDOM.render( <Translator> <App /> </Translator>, dom_node);



