import React from 'react';
import ReactDOM from 'react-dom';





/**
 * Event dispatched every time the dictionary finished 
 * to change his state (passage to a new language)
 * @moreInfos see updateTranslations
 */
var changeLang_event = new Event('changeLang');






/* The global dictionary (only directly reachable from inside this module) */
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








	
/**
 * Update the dictionary and trigger a geneal language update.
 * If the new language is not english this function gets the 
 * file containing the translations and assign his contents to 
 * the dictionary.
 */

export var updateTranslations = function() { 

		/* Update lang: get the document lang attribute 
		 * (ex: <html lang="fr">). If the attribute is undefined
		 * then english is the default language 
		 */
		Dict.lang = document.documentElement.lang || "en";

	
		/* If the language is english dont load translations */	
		if (Dict.lang == "en") {
			Dict.translations = null;
			window.dispatchEvent(changeLang_event);
			return;
		}
	

		/********** Load translations ***********/	

		Dict.loading = true;

		$.ajax({
			/* Get json file at the given url */
			dataType: 'json',

			// XXX this is not a rapresentative url
			url:'http://130.79.91.54/stage-l2s4/nm_pages/lang/'+Dict.lang+'.json',
			
			/* In case of success update translations */
	    		success: function(response, status, xhr){ 
					Dict.translations = response;
				},

			/* In case of error display a message */
	    		error: function(xhr, status, error){
					console.error(status+" "+error);
				},

			/* When finished dispatch event 'changeLang' */
	    		complete: function(xhr, status){
					Dict.loading = false;
					window.dispatchEvent(changeLang_event);
				}
	 	});
}
	











/**
 * Use this component to wrap your app in order to trigger a
 * re-rendering every time the dictionary is updated. 
 * 
 * ex: ReactDOM.render(<Translator> <App /> </Translator>, dom_node);
 * 
 * The children are given a context containing a `lang` attribute, 
 * also note that the  rendering of the children is triggered by the 
 * fact that the context change, so don't forget to specify the 
 * contextTypes if you want a child to be updated.
 * Just put:  `contextTypes : {lang: React.PropTypes.string}`
 */

export var Translator = React.createClass({

	/* Context passed to the children */	
	childContextTypes : {lang : React.PropTypes.string},

	getChildContext: function(){return {lang: Dict.lang};},

	/* Called once in the lifecycle of this component 
	 (before the first rendering)  */
	componentWillMount: function(){

		/* Start listening for language changes */
		window.addEventListener('changeLang',
			function(){ this.forceUpdate();}.bind(this));

		/* Update dictionary for the first time */
		updateTranslations();

	},
		
	/* Just wrap the children */	
	render: function(){ return( <div> {this.props.children} </div>);}

});










/**
 * Translates a given string only if there is a tranlation available.
 * Returns the original string otherwise. Note that this function
 * doesn't check the attribute `lang` of the dictionary but uses 
 * directly the translations available.
 * @param text String to translate
 * @return The tranlation of `text` if is available, the original value 
 *	   of `text` otherwise, a string of spaces of the size of `text` 
 *         if the dictionary is still loading.
 */

export var translate = function (text) {

		/* If text is not defined return it */
		if (!text) return text;

		/* If loading just put spaces */
		if (Dict.loading) return "\xa0".repeat(text.length);

		/* If there is a translation use it */
		var tr = Dict.translations;
		if (tr && tr[text]) return tr[text];

		/* Otherwise do not translate */
		return text;
}
