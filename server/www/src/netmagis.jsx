/* https://reactjs.org/docs/context.html */

require ('es6-promise').polyfill () ;

import React from 'react' ;
import ReactDOM from 'react-dom' ;
import Cookies from 'universal-cookie' ;
import PropTypes from 'prop-types' ;
import fetch from 'isomorphic-fetch' ;

import { addLocaleData, IntlProvider, FormattedMessage } from 'react-intl' ;
import enLocaleData from 'react-intl/locale-data/en' ;
import frLocaleData from 'react-intl/locale-data/fr' ;
addLocaleData ([...enLocaleData, ...frLocaleData]) ;

import { UserContext } from './user-context.jsx' ;

import { NMMenu } from './nm-menu.jsx' ;

//could take the url before netmagis/ to get the adress right on every machine
var baseUrl = window.location.toString ().replace (/[^/]*$/, '') ;

// hack to decode pathname
function getPathname (url) {
    var parser = document.createElement ('a') ;
    parser.href = window.location ;
    return parser.pathname ;

}
const pathUrl = getPathname (window.location).replace (/[^/]*$/, '') ;
//pathname = /netmagis/netmagis/ on test server -> put it router

const cookies = new Cookies () ;

export function api (verb, name, jsonbody, handler) {
    let url = baseUrl + '/' + name
    let opt = {
	method: verb,
	credentials: "same-origin",
    }
    if (jsonbody != null) {
	opt.headers = {
	    'Content-Type': 'application/json'
	}
	opt.body = JSON.stringify (jsonbody)
    }
    fetch (url, opt)
	.then (
	    response => {
		if (response.status >= 400) {
		    throw new Error ("ERROR ", url, "=> ", response.status) ;
		}
		return response.json () ;
	    },
	    error => {
		console.log ("ERROR FETCH ", url, " => ", error) ;
	    }
	)
	.then (
	    json => {
		handler (json) ;
	    },
	    error => {
		console.log ("ERROR ", url, " WHILE DECODING JSON ", error) ;
	    }
	)
}

/////////////////////////////////////////// App

class App extends React.Component {
    decodeCap (json) {
	if (this.state.lang != json.lang)
	    this.fetchTransl (json.lang) ;
	let cap = {} ;
	json.cap.forEach (val => cap [val] = true) ;
	if (! cap ['logged']) {
	    cap ['notlogged'] = true ;
	}
	console.log ("decodeCap: cap=", cap) ;
	this.setState ({
	    user: json.user,
	    lang: json.lang,
	    cap: cap,
	}) ;
    }

    decodeTransl (lang, json) {
	console.log ("decodeTransl: lang=", lang, ", json=", json) ;
	this.setState ({
	    lang: lang,
	    transl: json,
	}) ;
	cookies.set ('lang', lang, {path: pathUrl}) ;
    }

    fetchCap () {
	api ("GET", "cap", null, this.decodeCap.bind (this)) ;
    }

    fetchTransl (l) {
	console.log ("fetchTransl(", l, ")") ;
	api ("GET", l + ".json", null, this.decodeTransl.bind (this, l)) ;
    }

    disconnect () {
	cookies.remove ('session', {path: pathUrl}) ;
	this.fetchCap () ;
    }

    constructor (props) {
	super (props) ;

	this.changeLang = (l, e) => {
	    e.preventDefault () ;
	    this.setState ({ lang: l, }) ;
	    this.fetchTransl (l) ;
	} ;

	this.state = {
	    user: "",
	    lang: "C",
	    cap: {},
	    transl: {},
	    /****************
	    fetchTransl: this.fetchTransl.bind (this),
	    ****************/
	    disconnect: this.disconnect.bind (this),
	    changeLang: this.changeLang,
	} ;
	this.fetchCap () ;
    }

    render () {
	return (
	    <UserContext.Provider value={this.state}>
		<IntlProvider locale={this.state.lang}
			    messages={this.state.transl}
			    >
		    <NMMenu pathname={pathUrl}/>
		</IntlProvider>
	    </UserContext.Provider>
	) ;
    }
}

/* Render the app on the element with id #app */
ReactDOM.render (<App />, document.getElementById ('app')) ;
