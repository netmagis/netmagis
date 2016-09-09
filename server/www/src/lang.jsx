import React from 'react' ;
import ReactDOM from 'react-dom' ;
import cookie from 'react-cookie' ;

/*
 * Event dispatched when the dictionary finish to change
 * its state (moving to a new language)
 * @moreInfos see updateTranslations
 */

var changeLang_event = new Event ('changeLang') ;

/*
 * Global dictionary (only directly reachable from inside this module)
 */

var Dict = {
    // Current language ("en" is the default language)
    lang: "en",

    // Object containing all the translations from "en"
    // to the current language. Note that "en" doesn't
    // neeed any translation
    translations: null,

    // Boolean indicating if the dictionary is ready to
    // be used or is loading the translations
    loading: false
}

/*
 * Update the dictionary and trigger a general language update.
 * If the new language is not "en", this function fetches the
 * file holding the translations and assigns its contents to
 * the dictionary.
 */

export var updateTranslations = function () {
    var l ;

    /*
     * Set current language: 'lang' cookie first, then document
     * language (ex: <html lang="fr">) set by the API server
     * using the Accept-Language header.
     * Otherwise, use English as the default language .
     */

    l = cookie.load ('lang') ;
    if (l == undefined) {
	l = document.documentElement.lang ;
	if (l == undefined) {
	    l = "en" ;
	}
    }
    Dict.lang = l ;

    /* If the language is english dont load translations */
    if (Dict.lang == "en") {
	Dict.translations = null ;
	window.dispatchEvent (changeLang_event) ;
	return ;
    }

    /*
     * Load translation file
     */

    Dict.loading = true ;
    $.ajax ({
	/* Get json file at the given url */
	dataType: 'json',

	// Translation URL
	url: Dict.lang + '.json',

	/* Success: update translations */
	success: function (response, status, xhr) {
	    Dict.translations = response ;
	},

	/* Error: display a message */
	error: function (xhr, status, error) {
	    console.error (status + ' ' + error) ;
	},

	/* Finished: dispatch event 'changeLang' */
	complete: function (xhr, status) {
	    Dict.loading = false ;
	    window.dispatchEvent (changeLang_event) ;
	}
    }) ;
}

/*
 * React component to wrap app in order to trigger a
 * re-rendering when the dictionary is updated.
 *
 * ex: ReactDOM.render (<Translator> <App /> </Translator>, dom_node) ;
 *
 * Children are given a context containing a `lang` attribute,
 * also note that the  rendering of the children is triggered by the
 * fact that the context change, so don't forget to specify the
 * contextTypes if you want a child to be updated.
 * Just put:  `contextTypes : {lang: React.PropTypes.string}`
 */

export var Translator = React.createClass ({
    /* Context passed to children */
    childContextTypes: {lang: React.PropTypes.string},

    getChildContext: function () {
	return {lang: Dict.lang} ;
    },

    /*
     * Called once in the lifecycle of this component (before
     * the first rendering)
     */

    componentWillMount: function () {
	/* Start listening for language changes */
	window.addEventListener ('changeLang', function () {
		    this.forceUpdate () ;
		}.bind (this)
	    ) ;

	/* Update dictionary for the first time */
	updateTranslations () ;
    },

    /* Just wrap the children */
    render: function () {
	return <div>{this.props.children}</div> ;
    }
}) ;

/*
 * Function used in React children to translate strings.
 * Translates a given string only if there is a tranlation available.
 * Returns the original string otherwise.
 * This function doesn't check the attribute `lang` of the dictionary
 * but unconditionally uses the available translations.
 * @param text String to translate
 * @return The tranlation of `text` if is available, the original value
 *	   of `text` otherwise, a string of spaces of the size of `text`
 *         if the dictionary is still loading.
 */

export var translate = function (text) {
    var tr ;

    /* If text is not defined return it */
    if (!text) return text ;

    /* If currently loading just put spaces */
    if (Dict.loading) return "\xa0".repeat (text.length) ;

    /* If there is a translation use it */
    tr = Dict.translations ;
    if (tr && tr [text]) return tr [text] ;

    /* Otherwise do not translate */
    return text ;
}
