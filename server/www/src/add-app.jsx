import React from 'react';
import ReactDOM from 'react-dom';
import {Translator, updateTranslations} from './lang.jsx';
import {Tabs, Pane} from './bootstrap-lib/tabs.jsx';
import {Add_host, Add_block } from './forms/add.jsx';



/** 
 * This app provides the user with a series of tabs each of them supplying a
 * form/app related to the "add" operation.
 *
 * List of the panels:
 *	- Add_host: simple form to add a single host (default)
 *	- Add_block: step-by-step style app to add multiple hosts
 */
var App = React.createClass({


	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},


	/* XXX live translation expertiment 
	   this will not be part of the app */
	componentWillMount: function(){
		var el = $("#langButton")[0];
		el.onclick = function(){ 

			var html = document.documentElement;

			if (html.lang == "fr" )
				html.lang = "en";
			else 
				html.lang = "fr";

			updateTranslations();
		}
	},

	render: function () {
		return ( 
				<Tabs >
					<Pane label="Add single host" >
						<h2 > Add an host </h2>
						<Add_host id="form-addsingle" />
					</Pane> 
					<Pane label="Add address block" >
						<h2> Add many hosts </h2>
						<Add_block />
					</Pane> 
				</Tabs> 
		);
	}
});


/* Rendering the app on the node with id = 'app'
   change in case of conflict */
var dom_node = document.getElementById('app');

ReactDOM.render( <Translator> <App /> </Translator>, dom_node);



