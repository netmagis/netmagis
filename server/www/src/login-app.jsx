import React from 'react';
import ReactDOM from 'react-dom';
import {Translator, updateTranslations} from './lang.jsx';
import * as F from './bootstrap-lib/form-utils.jsx';
import * as C from './common.js';

var App = React.createClass({
	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},
	
	submit: function() {
		$.ajax({
			method: 'POST',
			url: C.APIURL+'/sessions',
			contentType: "application/json",
			data: JSON.stringify( { login: $('#Login_form [name="login"]').val(),
			 	password: $('#Login_form [name="password"]').val()
			      }),
			success: function(response){ 
				console.log(response);
			//	window.location = "/www/html/Forms.html";
			}
		})
	},

	render: function() {
		return (
			<div>
			<F.Form id="Login_form" action="/login" >
				<F.Row>
				<F.Input label="Login" name="login" dims="1+1" />
				</F.Row>
				<F.Row>
				<F.Input label="Password" name="password" dims="1+1" type="password" />
				</F.Row>
			</F.Form>
			<F.Button onClick={this.submit}> Sign in </F.Button>
			</div>

		);
	}

});

/* Rendering the app on the node with id = 'app'
   change in case of conflict */
var dom_node = document.getElementById('app');

ReactDOM.render( <Translator> <App /> </Translator>, dom_node);
