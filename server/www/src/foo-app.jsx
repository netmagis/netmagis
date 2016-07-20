import React from 'react' ;
import ReactDOM from 'react-dom' ;
import {Translator, updateTranslations} from './lang.jsx' ;
import * as F from './bootstrap-lib/form-utils.jsx' ;
import * as C from './common.js' ;

var App = React.createClass ({
    /* This will force a rerendering on language change */
    contextTypes: {lang: React.PropTypes.string},
    
    getInitialState: function () {
	return {message : "", color: ""}; 
    },

    render: function () {
	return (
	    <div>
		<p>Hi, I'm just an example!</p>
	    </div>
	) ;
    }

}) ;

/* Render the app on the element with id #app */
var dom_node = document.getElementById ('app') ;

ReactDOM.render (<Translator><App /></Translator>, dom_node) ;
