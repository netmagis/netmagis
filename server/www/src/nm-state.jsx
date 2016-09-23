import React from 'react' ;
import ReactDOM from 'react-dom' ;
import cookie from 'react-cookie' ;
import * as C from './common.js' ;

/*
 * Global state. Not exported to other modules.
 */

var StateDict = {
    // Current language. Default is 'en'.
    lang: 'en',

    // Current user. Empty string if not logged in.
    user: '',

    // Capabilities
    cap: {
	any:		true,
	logged:		false,
	admin:		false,
	smtp:		false,
	ttl:		false,
	mac:		false,
	topo:		false,
	topogenl:	false,
	pgauth:		false,
	pgadmin:	false,
	setuid:		false
    },

    // Translations: from the appropriate localization JSON file
    translations: null,

    // Are elements of this state currently being loaded?
    loading: {
	cap: false,
	translations: false
    }
} ;

/*
 * Translate a message (mc is the name for "message catalog")
 */

export var mc = function (text) {
    var tr ;

    /* If text is not defined return it */
    if (! text) return text ;

    /* If currently loading just put spaces */
    if (StateDict.loading.translations)
	return "\xa0".repeat (text.length) ;

    /* If there is a translation use it */
    tr = StateDict.translations ;
    if (tr && tr [text])
	return tr [text] ;

    /* Otherwise do not translate */
    return text ;
} ;


/*
 * Event dispatched when global state changes
 */

var changeState_event = new Event ('changeState') ;

/*
 * Update capabilities and translations: get them from API
 * Order is important:
 * - capabilities are loaded first
 * - next, translations are loaded and then the StateDict change
 *	event is dispatched
 */

var updateTranslations = function () {		// not exported
    // Don't load translations for default language
    if (StateDict.lang == 'en') {
	StateDict.translations = null ;
	window.dispatchEvent (changeState_event) ;
	return ;
    }

    // Load specific language file
    StateDict.loading.translations = true ;
    $.ajax ({
	dataType: 'json',
	url: C.APIURL + '/files/' + StateDict.lang + '.json',
	success: function (response, txtstatus, xhr) {
	    StateDict.translations = response ;
	},
	error: function (xhr, txtstatus, error) {
	    console.error ('translations: ' + txtstatus + ' ' + error) ;
	},
	complete: function (xhr, txtstatus) {
	    StateDict.loading.translations = false ;
	    window.dispatchEvent (changeState_event) ;
	}
    }) ;
} ;

export var updateCap = function () {
    StateDict.loading.cap = true ;
    $.ajax ({
	dataType: 'json',
	url: C.APIURL + '/cap',
	success: function (response, txtstatus, xhr) {
	    var rc ;
	    StateDict.lang = response.lang ;
	    StateDict.user = response.user ;
	    for (var c in StateDict.cap)
		StateDict.cap [c] = false 
	    for (var ic in response.cap) {
		rc = response.cap [ic] ;
		if (StateDict.cap [rc] != undefined) {
		    StateDict.cap [rc] = true ;
		}
	    }
	    updateTranslations () ;
	},
	error: function (xhr, txtstatus, error) {
	    console.error ('cap: ' + txtstatus + ' ' + error) ;
	},
	complete: function (xhr, txtstatus) {
	    StateDict.loading.cap = false ;
	}
    }) ;
} ;

/*
 * Change language though cookie, and update translations
 */

export var changeLang = function (l) {
    cookie.save ('lang', l, {path: C.APIURL}) ;
    StateDict.lang = l ;
    updateTranslations () ;
} ;


/*
 * Log out
 */

export var disconnect = function () {
    cookie.remove ('session', {path: C.APIURL + '/'}) ;
    updateCap () ;
} ;

/*
 * Top-level Netmagis menu
 */

export var NMState = React.createClass ({
    /*
     * Context given to children
     */
    childContextTypes: {nm: React.PropTypes.object},

    /*
     * Called when state or props change. Get context from the global state. 
     */
    getChildContext: function () {
	return ({nm: {
			lang: StateDict.lang,
			user: StateDict.user,
			cap:  StateDict.cap
		    } }) ;
    },

    /*
     * Load real context. This function is called only once in
     * the component life, before the initial rendering.
     */
    componentWillMount: function () {
	// Start listening for language/capability changes
	window.addEventListener ('changeState', function () {
		    this.forceUpdate () ;
		}.bind (this)
	    ) ;

	// Initial loading of capabilities and translations
	updateCap () ;
    },

    /*
     * Just wrap children
     */
    render: function () {
	return (<div>{this.props.children}</div>) ;
    }
}) ;
