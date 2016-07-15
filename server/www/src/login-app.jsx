import React from 'react' ;
import ReactDOM from 'react-dom' ;
import {Translator, updateTranslations} from './lang.jsx' ;
import * as F from './bootstrap-lib/form-utils.jsx' ;
import * as C from './common.js' ;

var App = React.createClass ({
    /* This will force a rerendering on language change */
    contextTypes : {lang: React.PropTypes.string},
    
    getInitialState: function () {
	return {message : "", color: ""}; 
    },

    submit: function () {
	$.ajax ({
	    method: 'POST',
	    url: C.APIURL+'/sessions',
	    contentType: "application/json",
	    data: JSON.stringify ({
		login: $('#Login_form [name="login"]').val (),
		password: $('#Login_form [name="password"]').val ()
	    }),
	    success: function (response) { 
		this.setState ({message: response, color: "green"}) ;
		window.location = "welcome.html" ;
	    }.bind (this),
	    error: function (jqXHR) {
		this.setState ({message: jqXHR.responseText, color: "red"}) ;
	    }.bind (this)
	})
    },

    render: function () {
	return (
	    <div>
	    <F.Form id="Login_form" action="/login">
		<F.Row>
		    <F.Input label="Login" name="login" dims="2+4" />
		</F.Row>
		<F.Row>
		    <F.Input label="Password" name="password" dims="2+4" type="password" />
		</F.Row>
	    </F.Form>
	    <F.Row>
		<F.Button onClick={this.submit}>Log in</F.Button>
	    </F.Row>
	    <p style={{color: this.state.color}}> {this.state.message} </p>
	    </div>
	) ;
    }

}) ;

/* Rendering the app on the node with id = 'app', change in case of conflict */
var dom_node = document.getElementById ('app') ;

ReactDOM.render (<Translator><App /></Translator>, dom_node) ;
