webpackJsonp([0],{

/***/ 0:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _reactDom = __webpack_require__(38);

	var _reactDom2 = _interopRequireDefault(_reactDom);

	var _lang = __webpack_require__(168);

	var _tabs = __webpack_require__(169);

	var _add = __webpack_require__(170);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	/** 
	 * This app provides the user with a series of tabs each of them supplying a
	 * form/app related to the "add" operation.
	 *
	 * List of the panels:
	 *	- Add_host: simple form to add a single host (default)
	 *	- Add_block: step-by-step style app to add multiple hosts
	 */
	var App = _react2.default.createClass({
		displayName: 'App',


		/* This will force a rerendering on languae change */
		contextTypes: { lang: _react2.default.PropTypes.string },

		/* XXX live translation expertiment 
	    this will not be part of the app */
		componentWillMount: function componentWillMount() {
			var el = $("#langButton")[0];
			el.onclick = function () {

				var html = document.documentElement;

				if (html.lang == "fr") html.lang = "en";else html.lang = "fr";

				(0, _lang.updateTranslations)();
			};
		},

		render: function render() {
			return _react2.default.createElement(
				_tabs.Tabs,
				null,
				_react2.default.createElement(
					_tabs.Pane,
					{ label: 'Add single host' },
					_react2.default.createElement(
						'h2',
						null,
						' Add an host '
					),
					_react2.default.createElement(_add.Add_host, { id: 'form-addsingle',
						defaultValues: { "machines": "Unspecified" } })
				),
				_react2.default.createElement(
					_tabs.Pane,
					{ label: 'Add address block' },
					_react2.default.createElement(
						'h2',
						null,
						' Add many hosts '
					),
					_react2.default.createElement(_add.Add_block, null)
				)
			);
		}
	});

	/* Rendering the app on the node with id = 'app'
	   change in case of conflict */
	var dom_node = document.getElementById('app');

	_reactDom2.default.render(_react2.default.createElement(
		_lang.Translator,
		null,
		' ',
		_react2.default.createElement(App, null),
		' '
	), dom_node);

/***/ },

/***/ 168:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
		value: true
	});
	exports.translate = exports.Translator = exports.updateTranslations = undefined;

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _reactDom = __webpack_require__(38);

	var _reactDom2 = _interopRequireDefault(_reactDom);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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
	};

	/**
	 * Update the dictionary and trigger a geneal language update.
	 * If the new language is not english this function gets the 
	 * file containing the translations and assign his contents to 
	 * the dictionary.
	 */

	var updateTranslations = exports.updateTranslations = function updateTranslations() {

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
			url: 'lang/' + Dict.lang + '.json',

			/* In case of success update translations */
			success: function success(response, status, xhr) {
				Dict.translations = response;
			},

			/* In case of error display a message */
			error: function error(xhr, status, _error) {
				console.error(status + " " + _error);
			},

			/* When finished dispatch event 'changeLang' */
			complete: function complete(xhr, status) {
				Dict.loading = false;
				window.dispatchEvent(changeLang_event);
			}
		});
	};

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

	var Translator = exports.Translator = _react2.default.createClass({
		displayName: 'Translator',


		/* Context passed to the children */
		childContextTypes: { lang: _react2.default.PropTypes.string },

		getChildContext: function getChildContext() {
			return { lang: Dict.lang };
		},

		/* Called once in the lifecycle of this component 
	  (before the first rendering)  */
		componentWillMount: function componentWillMount() {

			/* Start listening for language changes */
			window.addEventListener('changeLang', function () {
				this.forceUpdate();
			}.bind(this));

			/* Update dictionary for the first time */
			updateTranslations();
		},

		/* Just wrap the children */
		render: function render() {
			return _react2.default.createElement(
				'div',
				null,
				' ',
				this.props.children,
				' '
			);
		}

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

	var translate = exports.translate = function translate(text) {

		/* If text is not defined return it */
		if (!text) return text;

		/* If loading just put spaces */
		if (Dict.loading) return "\xa0".repeat(text.length);

		/* If there is a translation use it */
		var tr = Dict.translations;
		if (tr && tr[text]) return tr[text];

		/* Otherwise do not translate */
		return text;
	};

/***/ },

/***/ 169:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
		value: true
	});
	exports.Tabs = exports.Pane = undefined;

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _reactDom = __webpack_require__(38);

	var _reactDom2 = _interopRequireDefault(_reactDom);

	var _lang = __webpack_require__(168);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	/** 
	 * Use this element to specify the different contents inside
	 * a Tabs component (see below), the contents must be put inside 
	 * a Pane. A Pane takes also a `label` property which names 
	 * the current tab.
	 * @note: this component just wrap his children inside a <div>
	 *	  his properties are used by the component Tabs.
	 *
	 * example of use: 
	 *	<Pane label="Zoo"> <ListOfAnimals /> </Pane>
	 */

	var Pane = exports.Pane = _react2.default.createClass({
		displayName: 'Pane',


		//contextTypes : {lang: React.PropTypes.string},

		render: function render() {
			return _react2.default.createElement(
				'div',
				null,
				' ',
				this.props.children,
				' '
			);
		}
	});

	/**
	 * Use this component togheter with one or more Panes (see above)
	 * to create a series of toggling tabs. A Tabs takes an optional
	 * property `selected` to specify the preselected panel (the panels 
	 * are enumerated starting from 0, which is the default `selected` value)
	 * 
	 * Example of use:
	 *
	 * ReactDOM.render(
	 *	<Tabs selected=1 >
	 *		<Pane label="Tab 0">
	 *			<First content />
	 *		</Pane>
	 *		<Pane label="Tab 1 (preselected)">
	 *			<Second content />
	 *		</Pane>
	 *	</Tabs> , mount_node
	 * );
	 *
	 */

	var Tabs = exports.Tabs = _react2.default.createClass({
		displayName: 'Tabs',


		/* Use context in order to update on language changes */
		contextTypes: { lang: _react2.default.PropTypes.string },

		/* The first tab is the one active by default */
		getInitialState: function getInitialState() {
			return { selected: this.props.selected || 0 };
		},

		/* Update selected panel */
		handleClick: function handleClick(index, event) {
			event.preventDefault(); // Stop other things from happening
			this.setState({ selected: index });
		},

		/* Render the navigation bar */
		_renderTitles: function _renderTitles() {

			function labels(child, index) {

				/* Label is active if selected */
				var activeClass = this.state.selected === index ? 'active' : '';

				return _react2.default.createElement(
					'li',
					{ key: "tlab" + index, className: activeClass },
					_react2.default.createElement(
						'a',
						{ href: '#',
							onClick: this.handleClick.bind(this, index) },
						(0, _lang.translate)(child.props.label)
					)
				);
			}

			return _react2.default.createElement(
				'ul',
				{ className: 'nav nav-tabs' },
				this.props.children.map(labels.bind(this))
			);
		},

		/* Render the content of the children hiding the not-selected children */
		_renderContent: function _renderContent() {

			function contents(child, index) {
				var show = index == this.state.selected ? '' : 'none';
				return _react2.default.createElement(
					'div',
					{ key: "tcon" + index, style: { display: show } },
					this.props.children[index]
				);
			}

			return _react2.default.createElement(
				'div',
				{ className: 'tabs-content' },
				this.props.children.map(contents.bind(this))
			);

			/**
	   * Old version: renders only the selected contents
	   * (note that the user-content on the other panels
	   * will be erased as the component will be re-mounted)
	   *
	   *	return (
	   *		<div className= "tabs-content" > 
	   *		{this.props.children[this.state.selected]}
	   *		</div>
	   *	);
	   *
	   */
		},

		/* Main render */
		render: function render() {
			return _react2.default.createElement(
				'div',
				{ className: 'tabs' },
				this._renderTitles(),
				this._renderContent()
			);
		}

	});

/***/ },

/***/ 170:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
		value: true
	});
	exports.Add_block = exports.Add_host = undefined;

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _common = __webpack_require__(171);

	var C = _interopRequireWildcard(_common);

	var _formUtils = __webpack_require__(172);

	var F = _interopRequireWildcard(_formUtils);

	function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	/* prop id required */
	var Add_host = exports.Add_host = _react2.default.createClass({
		displayName: 'Add_host',


		contextTypes: { lang: _react2.default.PropTypes.string },

		propTypes: { id: _react2.default.PropTypes.string.isRequired },

		handleClick: function handleClick(event) {
			event.preventDefault();

			var els = F.form2obj(this.props.id);

			alert("submit " + JSON.stringify(els));

			if (this.props.submtCallback) this.props.submtCallback(els);
		},

		render: function render() {

			var d = this.props.defaultValues || {};

			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					F.Form,
					{ id: this.props.id },
					_react2.default.createElement(
						F.Row,
						null,
						_react2.default.createElement(F.InputAdrop, { label: 'Name', name: 'name', ddname: 'domain',
							defaultValue: d["name"], ddDef: d["domain"] }),
						_react2.default.createElement(F.Input, { label: 'TTL', name: 'ttl', dims: '2+1', defaultValue: d["ttl"] })
					),
					_react2.default.createElement(
						F.Row,
						null,
						_react2.default.createElement(F.Ainput, { label: 'Ip address', name: 'addr', defaultValue: d["addr"] }),
						_react2.default.createElement(
							F.Dropdown,
							{ label: 'View', name: 'view', defaultValue: d["view"] },
							_react2.default.createElement(
								'el',
								null,
								'external'
							),
							_react2.default.createElement(
								'el',
								null,
								'internal'
							)
						)
					),
					_react2.default.createElement(
						F.Row,
						null,
						_react2.default.createElement(F.Input, { label: 'Mac address', name: 'mac' }),
						_react2.default.createElement(F.Space, { dims: '2' }),
						_react2.default.createElement(F.Checkbox, { label: 'use SMTP', name: 'smtp', defaultChecked: d["smtp"] })
					),
					_react2.default.createElement(
						F.Row,
						null,
						_react2.default.createElement(F.Adropdown, { label: 'Machine', name: 'hinfos', defaultValue: d["machines"] })
					),
					_react2.default.createElement(
						F.Row,
						null,
						_react2.default.createElement(F.Input, { label: 'Comment', name: 'comment' })
					),
					_react2.default.createElement(
						F.Row,
						null,
						_react2.default.createElement(F.Input, { label: 'Resp. name', name: 'rname', defaultValue: d["rname"] }),
						_react2.default.createElement(F.Input, { label: 'Resp. mail', name: 'rmail', defaultValue: d["rmail"] })
					)
				),
				_react2.default.createElement(
					F.Row,
					null,
					_react2.default.createElement(F.Space, { dims: '5' }),
					_react2.default.createElement(
						F.Button,
						{ dims: '1', onClick: this.handleClick },
						'Add'
					)
				)
			);
		}
	});

	var Select_block = _react2.default.createClass({
		displayName: 'Select_block',


		contextTypes: { lang: _react2.default.PropTypes.string },

		getInitialState: function getInitialState() {
			return { blocks: undefined };
		},

		handleSearch: function handleSearch(event) {
			event.preventDefault();
			/* XXX this is just an example */
			var els = document.getElementById('Search block').elements;
			var query = C.APIURL + "/addrblock";

			C.getJSON(query, function (res) {
				this.setState({ blocks: res });
			}.bind(this));
		},

		search_form: function search_form() {
			return _react2.default.createElement(
				F.Row,
				null,
				_react2.default.createElement(F.InputXORdd, { label: 'Network',
					name: 'cidr', defaultValue: 'Select one' }),
				_react2.default.createElement(F.Input, { label: 'Address count', dims: '1+1' }),
				_react2.default.createElement(F.Space, { dims: '1' }),
				_react2.default.createElement(
					F.Button,
					{ dims: '1', onClick: this.handleSearch },
					'Search'
				)
			);
		},

		select_form: function select_form() {

			if (!this.state.blocks) return null;

			function makeEl(_ref, i) {
				var first = _ref.first;
				var size = _ref.size;

				return _react2.default.createElement(
					'el',
					{ key: i + "elsf" },
					' ',
					first + " (size: " + size + ")",
					' '
				);
			}

			return _react2.default.createElement(
				F.Row,
				null,
				_react2.default.createElement(
					F.Dropdown,
					{ label: 'Block', name: 'cidr' },
					this.state.blocks.map(makeEl)
				),
				_react2.default.createElement(F.Space, { dims: '1' }),
				_react2.default.createElement(
					F.Button,
					{ dims: '1', onClick: this.props.onSelect },
					'Select'
				)
			);
		},

		render: function render() {
			return _react2.default.createElement(
				F.Form,
				{ id: 'Search block' },
				this.search_form(),
				this.select_form()
			);
		}
	});

	var Add_block = exports.Add_block = _react2.default.createClass({
		displayName: 'Add_block',


		contextTypes: { lang: _react2.default.PropTypes.string },

		getInitialState: function getInitialState() {
			return { contents: 0, defaultAddHost: {} };
		},

		handleSelect: function handleSelect(event) {
			event.preventDefault();
			this.setState({ contents: 1 });
		},

		addNext: function addNext(oldValues) {

			oldValues["name"] = oldValues["name"].replace(/[0-9][0-9]*$/, function (x) {
				return parseInt(x) + 1;
			});

			oldValues["addr"] = C.IPv4_intA_to_dotquadA(C.IPv4_dotquadA_to_intA(oldValues["addr"]) + 1);

			this.setState({ contents: 2, defaultAddHost: oldValues });
		},

		componentDidUpdate: function componentDidUpdate() {
			if (this.state.contents == 2) this.setState({ contents: 1 });
		},

		render: function render() {

			switch (this.state.contents) {

				case 0:
					return _react2.default.createElement(Select_block, { onSelect: this.handleSelect });

				case 1:
					return _react2.default.createElement(Add_host, { id: 'Addblk_addh',
						defaultValues: this.state.defaultAddHost,
						submtCallback: this.addNext });

				case 2:
					return _react2.default.createElement('div', null); // Little hack to rerender
			}
		}
	});

/***/ },

/***/ 171:
/***/ function(module, exports, __webpack_require__) {

	"use strict";

	Object.defineProperty(exports, "__esModule", {
		value: true
	});
	exports.getJSON = exports.TODO_APIURL = exports.APIURL = undefined;
	exports.IPv4_dotquadA_to_intA = IPv4_dotquadA_to_intA;
	exports.IPv4_intA_to_dotquadA = IPv4_intA_to_dotquadA;
	exports.add_to_IPv4 = add_to_IPv4;

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	var APIURL = exports.APIURL = "http://130.79.91.54:82/";
	var TODO_APIURL = exports.TODO_APIURL = "http://130.79.91.54:82/www/html/api";

	/* Same as $.getJSON but defines mimeType
	   usefull in case of static files */
	var getJSON = exports.getJSON = function getJSON(url, success, callback) {
		$.ajax({
			url: url,
			dataType: 'json',
			mimeType: 'application/json',
			success: success,
			complete: callback
		});
	};

	/* dotted-quad IP to integer */
	function IPv4_dotquadA_to_intA(strbits) {
		var split = strbits.split('.', 4);
		var myInt = parseFloat(split[0] * 16777216) /* 2^24 */
		 + parseFloat(split[1] * 65536) /* 2^16 */
		 + parseFloat(split[2] * 256) /* 2^8  */
		 + parseFloat(split[3]);
		return myInt;
	}

	/* integer IP to dotted-quad */
	function IPv4_intA_to_dotquadA(strnum) {
		var byte1 = strnum >>> 24;
		var byte2 = strnum >>> 16 & 255;
		var byte3 = strnum >>> 8 & 255;
		var byte4 = strnum & 255;
		return byte1 + '.' + byte2 + '.' + byte3 + '.' + byte4;
	}

	/* Add n to an IPv4 address */
	function add_to_IPv4(ip, n) {
		return IPv4_intA_to_dotquadA(IPv4_dotquadA_to_intA(ip) + n);
	}

/***/ },

/***/ 172:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
		value: true
	});
	exports.Table = exports.Editable_tr = exports.DdEdit = exports.InEdit = exports.InputXORdd = exports.AutoInput = exports.Form = exports.Row = exports.Space = exports.Checkbox = exports.InputAdrop = exports.Inputdrop = exports.Adropdown = exports.Dropdown = exports.AJXdropdown = exports.Dropdown_internal = exports.Button = exports.Ainput = exports.Input = undefined;

	var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

	exports.form2obj = form2obj;

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _reactDom = __webpack_require__(38);

	var _reactDom2 = _interopRequireDefault(_reactDom);

	var _lang = __webpack_require__(168);

	var _reactAutosuggest = __webpack_require__(173);

	var _reactAutosuggest2 = _interopRequireDefault(_reactAutosuggest);

	var _prompters = __webpack_require__(207);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	/**
	 * Returns an object all the values of the form with the given id. The
	 * keys are the name attributes of the fields of the form 
	 */
	function form2obj(id) {
		var elements = document.getElementById(id).elements;

		var obj = {};

		for (var i = 0; i < elements.length; i++) {

			var value;
			var el = elements[i];
			var tag = el.tagName.toLowerCase();

			switch (tag) {

				case "input":
					if (el.type.toLowerCase() == "text") value = el.value;else if (el.type.toLowerCase() == "checkbox") value = el.checked;
					break;

				case "button":
					value = el.textContent;

			}

			obj[elements[i].name] = value;
		}

		return obj;
	}

	/** 
	 * Creates an uncontrolled Bootstrap-like input field preceded by a label.
	 * Every property passed to this object is passed to the input field.
	 *
	 * @properties:
	 *	-label: defines the contents of the label (required)
	 *	-dims : defines the dimensions of this component following the
	 *		Bootstrap grid system. Use the following syntax: "x+y"
	 *		where x is the space reserved for the label and y is the
	 *		space reserved for the input field.
	 *	  
	 * @note:  to fill the input with a default value use the React-specific prop 
	 *	   'defaultValue' and not the prop 'value'.
	 *	    more infos: https://facebook.github.io/react/docs/forms.html#uncontrolled-components
	 */

	var Input = exports.Input = _react2.default.createClass({
		displayName: 'Input',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {

			/* The default value of dims is "2+3" */
			var grid_vals = this.props.dims ? this.props.dims.split('+') : ['2', '3'];

			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					'label',
					{ className: "control-label col-md-" + grid_vals[0] },
					(0, _lang.translate)(this.props.label)
				),
				_react2.default.createElement(
					'div',
					{ className: "col-md-" + grid_vals[1] },
					_react2.default.createElement('input', _extends({}, this.props, { className: 'form-control' }))
				)
			);
		}

	});

	/**
	 * Same as Input but uses the component AutoInput to perform live-suggestions.
	 * Use the html attribute 'name' to link this component the correct
	 * handler contained inside the object Propmters.
	 *
	 * @properties: (same as Input)
	 * @see Input, AutoInput
	 */

	var Ainput = exports.Ainput = _react2.default.createClass({
		displayName: 'Ainput',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {
			var grid_vals = this.props.dims ? this.props.dims.split('+') : ['2', '3'];

			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					'label',
					{ className: "control-label col-md-" + grid_vals[0] },
					(0, _lang.translate)(this.props.label)
				),
				_react2.default.createElement(
					'div',
					{ className: "col-md-" + grid_vals[1] },
					_react2.default.createElement(AutoInput, _extends({}, this.props, { className: 'form-control' }))
				)
			);
		}

	});

	/**
	 * Simple Bootstrap-like button. Every property passed to this button is 
	 * passed as an attribute to the html button node. 
	 * Use this component as a normal button to wrap some text.
	 *
	 * @properties:
	 *	-dims : space reserved to the button following the Bootstrap grid system
	 *		(ex. dims="3")
	 *	
	 * @prec this component should have only text as a child
	 */

	var Button = exports.Button = _react2.default.createClass({
		displayName: 'Button',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {

			/* By default dims="2" */
			var grid_val = this.props.dims ? this.props.dims : '2';

			return _react2.default.createElement(
				'button',
				_extends({ className: "btn btn-default col-md-" + grid_val
				}, this.props),
				(0, _lang.translate)(this.props.children)
			);
		}

	});

	/**
	 * This component creates a simple bootstrap-like dropdown using the 
	 * contents of the children as list element. The children can contain only
	 * text. You can use whatever html tag to indicate the children (by convention
	 * I suggest you to use the tag <el> </el> as it is short and descriptive).
	 * All the properties passed to this component are passed directly to the
	 * button element (so if you define a 'className' property this means that
	 * the button will use it to define a class attribute) in this way you can
	 * define 
	 *
	 * @properties:
	 *	-superClass: the same as className but it will affect the whole
	 *		     component and not only the internal button
	 *	-defaultValue: force the initial value
	 *	-value:	force the value
	 *	-onChange: a function called every time the user changes the value,
	 *		   this new value is passed by parameter
	 *		   
	 * 
	 * Example of use:
	 *	<Dropdown_internal superClass="beautiful_dropdown" >
	 *		<el> element 1 </el> 
	 *		<el> element 2 </el> 
	 *		<el> element 3 </el> 
	 * 	</Dropdown_internal>
	 *
	 * @warning: <el>{ my_var }</el> Ok! 
	 * 	     <el> { my_var } </el> Avoid it! 
	 *	  Apparently in the latter case React generates an array of 3 elements
	 *	  [" ", my_var, " "]. This works still fine for the rendering but could 
	 *	  cause some problem when the value must be retrieved using .val() 
	 *				 
	 */
	var Dropdown_internal = exports.Dropdown_internal = _react2.default.createClass({
		displayName: 'Dropdown_internal',


		contextTypes: { lang: _react2.default.PropTypes.string },

		/* The state contains an attribute value which indicate
	    the current (selected) contents of the dropdown */

		getInitialState: function getInitialState() {

			/* If defaultValue is defined use it as initial
	  	   value, otherwise use the contents of the first
	     child */

			if (this.props.defaultValue != undefined) return { value: this.props.defaultValue };else if (this.props.value != undefined) return { value: this.props.value };else if (this.props.children.length > 0) return { value: this.props.children[0].props.children };else return { value: undefined };
		},

		/* At every update if possible use the props value as state or the 
	    contents of the first child as value if the value is not defined 
	    or there are new children (see filter dropdown)  */

		componentWillReceiveProps: function componentWillReceiveProps(newprops) {

			if (newprops.value != undefined) this.setState({ value: newprops.value });else if (newprops.children.length > 0) {
				if (this.state.value == undefined) {

					this.setState({ value: newprops.children[0].props.children });
				}
			}
		},

		/* Set the contents of the child that has been clicked as value 
	    and execute the onChange callback */
		handleClick: function handleClick(child, event) {
			event.preventDefault();
			var newValue = child.props.children;
			this.setState({ value: newValue });
			if (this.props.onChange) this.props.onChange(newValue);
		},

		/* Creates an element of the dropdown containing the text inside
	    the given child (so make sure the child contains only text) */
		makeOption: function makeOption(child, index) {
			return _react2.default.createElement(
				'li',
				{ key: "dopt" + index },
				_react2.default.createElement(
					'a',
					{ href: '#', onClick: this.handleClick.bind(this, child) },
					(0, _lang.translate)(child.props.children)
				)
			);
		},

		/* Main render */
		render: function render() {
			return _react2.default.createElement(
				'div',
				{ className: this.props.superClass },
				_react2.default.createElement(
					'button',
					_extends({ className: 'btn btn-default dropdown-toggle',
						type: 'button', 'data-toggle': 'dropdown', 'aria-haspopup': 'true',
						'aria-expanded': 'true' }, this.props),
					(0, _lang.translate)(this.state.value),
					_react2.default.createElement('span', { className: 'caret' })
				),
				_react2.default.createElement(
					'ul',
					{ className: 'dropdown-menu' },
					this.props.children.map(this.makeOption)
				)
			);
		}
	});

	/**
	 * Creates a Bootstrap-like dropdown which element will be charged
	 * automatically trough async ajax request using the proper hanlder.
	 *
	 * @properties: same as Dropdown_internal, plus
	 *	-name: defines the name of the handler
	 * 
	 * Example of use:
	 *	 <AJXdropdown name="foods" superClass="foodSelector" />
	 *	
	 */

	var AJXdropdown = exports.AJXdropdown = _react2.default.createClass({
		displayName: 'AJXdropdown',


		contextTypes: { lang: _react2.default.PropTypes.string },

		/* An AJXdropdown has a name prop */
		propTypes: { name: _react2.default.PropTypes.string.isRequired },

		componentWillMount: function componentWillMount() {
			var prompter = _prompters.Prompters[this.props.name];

			if (!prompter) {
				console.error(this.props.name + " is not a prompter!");
			} else if (prompter.init) {
				prompter.init(function () {
					this.forceUpdate();
				}.bind(this));
			}
		},

		render: function render() {
			var values = _prompters.Prompters[this.props.name].getValues();

			function makeElement(val, index) {
				return _react2.default.createElement(
					'el',
					{ key: "ajd" + index },
					val
				);
			}

			return _react2.default.createElement(
				Dropdown_internal,
				this.props,
				values.map(makeElement)
			);
		}

	});

	/**
	 * Creates a Bootstrap-like dropdown preceded by a label.
	 * For more infos see Dropdown_internal.
	 * 
	 * @properties: sames ad Dropdown_internal, plus
	 *	-label: The contents of the label preceding the dropdown
	 *	-dims : Dimensions following bootstrap's grid system (see Input)
	 *
	 * Example of use: 
	 *	<Dropdown dims="2+2" label="Select an animal" />
	 *		<el> Lyon </el>
	 *		<el> Fox  </el>
	 *		<el> Dog  </el>
	 * 	</Dropdown>
	 */
	var Dropdown = exports.Dropdown = _react2.default.createClass({
		displayName: 'Dropdown',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {

			var grid_vals = this.props.dims ? this.props.dims.split('+') : ['2', '3'];

			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					'label',
					{ className: "control-label col-md-" + grid_vals[0] },
					(0, _lang.translate)(this.props.label)
				),
				_react2.default.createElement(
					'div',
					{ className: "dropdown col-md-" + grid_vals[1] },
					_react2.default.createElement(Dropdown_internal, this.props)
				)
			);
		}
	});

	/**
	 * Same as Dropdown but with a list of elements charged trough 
	 * async AJAX call (see AJXdropdown).
	 * 
	 * @properties:
	 *	-label: The contents of the label preceding the dropdown
	 *	-dims : Dimensions following bootstrap's grid system (see Input)
	 *	-name : Name of the handler (see AJXdropdown)
	 *
	 * Example of use:
	 * 	<Adropdown name="animals" label="Select an animal" dims="3+2" />
	 */
	var Adropdown = exports.Adropdown = _react2.default.createClass({
		displayName: 'Adropdown',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {

			var grid_vals = this.props.dims ? this.props.dims.split('+') : ['2', '3'];

			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					'label',
					{ className: "control-label col-md-" + grid_vals[0] },
					(0, _lang.translate)(this.props.label)
				),
				_react2.default.createElement(
					'div',
					{ className: "dropdown col-md-" + grid_vals[1] },
					_react2.default.createElement(AJXdropdown, this.props)
				)
			);
		}
	});

	/**
	 * Creates an input field which ends with a dropdown, everything preceded
	 * by a label. All the properties are passed directly as attributes of the 
	 * input field. For more infos see Input and Dropdown_internal.
	 *
	 * @properties:
	 *	-label: The contents of the label preceding the dropdown
	 *	-dims : Dimensions following bootstrap's grid system (see Input)
	 *	-ddname:  The attribute name to pass to the dropdown
	 *	-ddDef: The default value of the dropdown
	 * 
	 * Example of use:
	 *	<Inputdrop label="Create your e-mail" ddname="availableDomains" ddDef="Select a domain">
	 *		<el> @toto.fr </el>
	 *		<el> @truc.eu </el>
	 *		<el> @foo.com </el>
	 *	</Inputdrop>
	 */

	var Inputdrop = exports.Inputdrop = _react2.default.createClass({
		displayName: 'Inputdrop',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {

			var grid_vals = this.props.dims ? this.props.dims.split('+') : ['2', '3'];

			/* Make a copy of the props without the children */
			var props = {};
			$.extend(props, this.props);
			props.children = null;

			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					'label',
					{ className: "control-label col-md-" + grid_vals[0] },
					(0, _lang.translate)(this.props.label)
				),
				_react2.default.createElement(
					'div',
					{ className: "input-group col-md-" + grid_vals[1],
						style: { "paddingLeft": "15px", "float": "left" } },
					_react2.default.createElement('input', _extends({ className: 'form-control' }, props)),
					_react2.default.createElement(
						Dropdown_internal,
						{ name: this.props.ddname, defaultValue: this.props.ddDef,
							superClass: 'input-group-btn' },
						this.props.children
					)
				)
			);
		}

	});

	/**
	 * Same as Inputdrop but uses an AJXdropdown in order to charge
	 * the values of the dropdown using the ajax api. In this case
	 * use the property `ddname` to specify the name of the handler
	 * for the AJXdropdown.
	 */

	var InputAdrop = exports.InputAdrop = _react2.default.createClass({
		displayName: 'InputAdrop',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {

			var grid_vals = this.props.dims ? this.props.dims.split('+') : ['2', '3'];

			/* Make a copy of the props without the children */
			var props = {};
			$.extend(props, this.props);
			props.children = null;

			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					'label',
					{ className: "control-label col-md-" + grid_vals[0] },
					(0, _lang.translate)(this.props.label)
				),
				_react2.default.createElement(
					'div',
					{ className: "input-group col-md-" + grid_vals[1],
						style: { "paddingLeft": "15px", "float": "left" } },
					_react2.default.createElement('input', _extends({ className: 'form-control' }, props)),
					_react2.default.createElement(AJXdropdown, { name: this.props.ddname, defaultValue: this.props.ddDef,
						superClass: 'input-group-btn' })
				)
			);
		}

	});

	/**
	 * Creates a Bootstrap-like checkbox followed by a label
	 * All the properties passed to this component will be
	 * passed as attributes of the checkbox.
	 *
	 * @properties: 
	 *	-label: The contents of the label following the checkbox
	 *	-dims : Dimensions following bootstrap's grid system (see Input)
	 * 
	 * Example of use:
	 *	<Checkbox name="colors" label="Print with colors" dims="3" />
	 */
	var Checkbox = exports.Checkbox = _react2.default.createClass({
		displayName: 'Checkbox',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {

			var grid_val = this.props.dims ? this.props.dims : '2';

			return _react2.default.createElement(
				'div',
				{ className: "checkbox col-md-" + grid_val },
				_react2.default.createElement(
					'label',
					null,
					_react2.default.createElement('input', _extends({ type: 'checkbox' }, this.props)),
					(0, _lang.translate)(this.props.label)
				)
			);
		}
	});

	/**
	 * This component occupies empty space on the grid system.
	 * Use it to align the other components if necessary 
	 * 
	 * @properties: 
	 *	-dims : Dimensions following bootstrap's grid system (see Input)
	 */
	var Space = exports.Space = _react2.default.createClass({
		displayName: 'Space',


		render: function render() {
			var grid_val = this.props.dims ? this.props.dims : '1';

			return _react2.default.createElement('div', { className: "col-md-" + grid_val });
		}

	});

	/**
	 * Use this component to wrap other elements if you want them to be
	 * on the same row.
	 *
	 * Example of use:
	 *	   <Row>
	 *		<Input (input props....)  />
	 *		<Dropdown (dropdown props....)>  
	 *			<el> Element 1 </el>
	 *			<el> Element 2 </el>
	 *		</Dropdown>
	 *	   </Row>
	 */

	var Row = exports.Row = _react2.default.createClass({
		displayName: 'Row',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {

			return _react2.default.createElement(
				'div',
				{ className: 'form-group row' },
				this.props.children
			);
		}

	});

	/**
	 * Creates a form. The properties passed to this component are passed
	 * automatically as attributes of the html element <form>
	 * Use it to wrap the other components when creating a form.
	 */
	var Form = exports.Form = _react2.default.createClass({
		displayName: 'Form',


		contextTypes: { lang: _react2.default.PropTypes.string },

		render: function render() {
			return _react2.default.createElement(
				'form',
				_extends({ className: 'form-horizontal', role: 'form'
				}, this.props),
				this.props.children
			);
		}

	});

	/**
	 * Use this component to generate an input field with automatic suggestions.
	 * Note that all the properties of AutoInput will be passed to the imput field.
	 * AutoInput must have a `name` property and it's value must correspond
	 * with the name of an handler contained inside the Prompters (see above).
	 *
	 * @properties: 
	 *	-defaultValue: default value of the input (!= placeholder)
	 *	-name: name of the handler
	 * 
	 * Example of use:
	 *	<AutoInput placeholder="Insert a network address" name="cidr" 
	 *		   className="myclassname" style={{width: "30%"}} 
	 *	/>
	 */
	var AutoInput = exports.AutoInput = _react2.default.createClass({
		displayName: 'AutoInput',


		/* The state contains the current value of the input
	    and an array of suggestions (output of getSuggestions)*/
		getInitialState: function getInitialState() {
			return { value: this.props.defaultValue || '', suggestions: [] };
		},

		/* An AutoInput element must have a name prop */
		propTypes: { name: _react2.default.PropTypes.string.isRequired },

		/* At the very beginning call check for the existens of the
	    prompter and call his init function if it's defined */
		componentWillMount: function componentWillMount() {
			var prompter = _prompters.Prompters[this.props.name];

			if (!prompter) {
				console.error(this.props.name + " is not a prompter!");
			} else if (prompter.init) {
				prompter.init();
			}
		},

		/* Use the function getSuggestions defined by the prompter
	    to get the actual suggestions from the current value */
		getSuggestions: function getSuggestions(value) {
			return _prompters.Prompters[this.props.name].getSuggestions(value);
		},

		/* In this component we consider suggestions to always be strings,
	    this function tells Autosuggest how to map the suggestion to 
	    the input value when the first is selected */
		getSuggestionValue: function getSuggestionValue(suggestions) {
			return suggestions;
		},

		/* As this is controlled Update the state with the new value */
		onChange: function onChange(event, _ref) {
			var newValue = _ref.newValue;

			this.setState({ value: newValue });
		},

		/* */
		onSuggestionsUpdateRequested: function onSuggestionsUpdateRequested(_ref2) {
			var value = _ref2.value;

			this.setState({ suggestions: this.getSuggestions(value) });
		},

		/* Suggestions are rendered wrapping them in a <span> element */
		renderSuggestion: function renderSuggestion(suggestion) {
			return _react2.default.createElement(
				'span',
				null,
				suggestion
			);
		},

		/* Main render */
		render: function render() {

			/* Pass the value and the onChange function to the
	     input. So it will work as a controlled component */
			var inputProps = {
				value: this.state.value,
				onChange: this.onChange
			};

			/* Copy all the properties of AutoInput in order to
	     pass them to Autosuggest */
			$.extend(inputProps, this.props);

			return _react2.default.createElement(_reactAutosuggest2.default, {
				suggestions: this.state.suggestions,
				onSuggestionsUpdateRequested: this.onSuggestionsUpdateRequested,
				getSuggestionValue: this.getSuggestionValue,
				renderSuggestion: this.renderSuggestion,
				inputProps: inputProps
			});
		}
	});

	/**
	 * Creates an input and a dropdown (the latter preceded by a 'or' label), where
	 * only the last used can contain a value.
	 *
	 * @properties:
	 *	-label: Content of the label preceding the input field and the dropdown
	 *	-defaultValue: default value of the dropdown
	 *	-iname, dname: names of input field and dropdown (XXX should I use only one name prop and update an hidden input with the good value? )
	 *	-placeholder:  placeholder attribute of the input field
	 */

	var InputXORdd = exports.InputXORdd = _react2.default.createClass({
		displayName: 'InputXORdd',


		contextTypes: { lang: _react2.default.PropTypes.string },

		getInitialState: function getInitialState() {
			// The state contains the value of the input
			// (Ivalue) and the value of the dropdown (Dvalue)
			return { Ivalue: "", Dvalue: undefined };
		},

		/* An AJXdropdown has a name prop */
		propTypes: { name: _react2.default.PropTypes.string.isRequired },

		/* Update input when the user types */
		handleChange: function handleChange(event) {
			event.preventDefault();
			this.setState({ Ivalue: event.target.value });
		},

		/* Select dropdown value */
		ddChange: function ddChange() {
			this.setState({ Ivalue: "", Dvalue: undefined });
		},

		/* User leaves the input */
		onBlur: function onBlur(event) {
			event.preventDefault();
			this.setState({ Dvalue: this.props.defaultValue || "" });
		},

		render: function render() {

			var grid_vals = this.props.dims ? this.props.dims.split('+') : ['2', '2', '2'];

			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					'label',
					{ className: "control-label col-md-" + grid_vals[0] },
					(0, _lang.translate)(this.props.label)
				),
				_react2.default.createElement(
					'div',
					{ className: "col-md-" + grid_vals[1] },
					_react2.default.createElement('input', { className: 'form-control', value: this.state.Ivalue,
						onChange: this.handleChange, onBlur: this.onBlur,
						name: this.props.name, placeholder: this.props.placeholder })
				),
				_react2.default.createElement(
					'div',
					{ className: "dropdown col-md-" + grid_vals[2] },
					_react2.default.createElement(Adropdown, { label: 'or', onChange: this.ddChange, value: this.state.Dvalue,
						name: this.props.name, defaultValue: this.props.defaultValue })
				)
			);
		}

	});

	/**
	 * Depending on is property `edit` creates a editable text-input field
	 * or a not editable text.
	 * @properties:
	 *	- name: name to pass to the imput when in edit mode
	 *	- edit: if true the component will be editable 
	 */
	var InEdit = exports.InEdit = _react2.default.createClass({
		displayName: 'InEdit',


		/* This will force a rerendering on languae change */
		contextTypes: { lang: _react2.default.PropTypes.string },

		getInitialState: function getInitialState() {
			return { value: this.props.children };
		},

		componentWillReceiveProps: function componentWillReceiveProps(newProps) {
			//this.setState({ value: newProps.children });

		},

		/* As this is controlled Update the state with the new value */
		onChange: function onChange(event) {
			this.setState({ value: event.target.value });
		},

		render: function render() {
			if (this.props.edit === true) {
				return _react2.default.createElement('input', { value: this.state.value, style: { width: "100%" },
					onChange: this.onChange, name: this.props.name });
			} else {
				return _react2.default.createElement(
					'div',
					null,
					' ',
					this.state.value,
					' '
				);
			}
		}
	});

	/**
	 * Depending on is property `edit` creates a editable dropdown
	 * or a not editable text.
	 * @properties:
	 *	- name: name to pass to the dropdown when in edit mode
	 *	- edit: if true the component will be editable 
	 *	- values: either a list (array) either an object containing an attribute 
	 *		  values (a list) and an attribute value (default value), in this 
	 *		  latter case the attribute value will be used as default value of
	 *		  this component.
	 */
	var DdEdit = exports.DdEdit = _react2.default.createClass({
		displayName: 'DdEdit',


		/* This will force a rerendering on languae change */
		contextTypes: { lang: _react2.default.PropTypes.string },

		getInitialState: function getInitialState() {
			if (Array.isArray(this.props.values)) {

				return { value: this.props.values[0],
					values: this.props.values
				};
			} else {

				return { value: this.props.values.value,
					values: this.props.values.values
				};
			}
		},

		/* As this is controlled Update the state with the new value */
		onChange: function onChange(newValue) {
			this.setState({ value: newValue });
		},

		makeOption: function makeOption(val, index) {
			return _react2.default.createElement(
				'el',
				null,
				val
			);
		},

		render: function render() {
			if (this.props.edit === true) {
				return _react2.default.createElement(
					Dropdown_internal,
					{ superClass: 'dropdown',
						onChange: this.onChange, value: this.state.value,
						name: this.props.name },
					this.state.values.map(this.makeOption)
				);
			} else {
				return _react2.default.createElement(
					'div',
					null,
					' ',
					this.state.value,
					' '
				);
			}
		}
	});

	/**
	 * Creates an editable table's row which allows the user to edit the values
	 * and/or save/remove/cancell the row.
	 *
	 * @properties:
	 *	-model	an object which describes the data contained into
	 *		the row (see the component EdiTable). It must have one attribute
	 *		'key' and an attribute 'desc' (see EditTable)
	 *	
	 *	-data,  an object containing a certain number of "name": "value" pairs,
	 *		where "name" correspond to one of the names specified on the model.
	 *	 	If the type specified on the model is "input" and the data for this
	 *		field is not specified then it will be an empty string by default. 
	 *		The data of other types (!= "input") must always be specified.
	 *
	 *	-edit, specify if the row is rendered in edit mode or not
	 *
	 * 	-handler, an object containing a serie of function that can handle the data
	 *		  contained in the row, each of them when called will receive a
	 *		  parameter 'key' which containds the key value referenced by the model
	 *                and a object 'input' which fields rapresent the fields of the row
	 *		  they are named accordingly with the model (required)
	 *
	 *	-onRemove, a function called when the row is removed, the property index
	 *	           passed as parameter
	 *
	 *	-index, value passed to the onRemove function when the row is removed
	 *
	 *	-reactKey, must have the same value as the key used by React for 
	 *		   this component. This will be used as id to idetify the
	 *		   row (required)
	 */

	var Editable_tr = exports.Editable_tr = _react2.default.createClass({
		displayName: 'Editable_tr',


		/* This will force a rerendering on languae change */
		contextTypes: { lang: _react2.default.PropTypes.string },

		getInitialState: function getInitialState() {
			return { edit: this.props.edit || false };
		},

		/**
	  * Used by this.renderChild to render the correct
	  * child depending the description on the model
	  * @param desc, description specified into the model property
	  * @param content, the content of the child to render
	  */
		renderType: function renderType(desc, content) {
			switch (desc[1].toLowerCase()) {

				case "input":
					return _react2.default.createElement(
						InEdit,
						{ edit: this.state.edit,
							name: desc[2]
						},
						content
					);

				case "dropdown":
					return _react2.default.createElement(DdEdit, { edit: this.state.edit,
						values: content,
						name: desc[2]
					});

				default:
					return _react2.default.createElement(
						'div',
						null,
						content
					);
			}
		},

		/**
	         * Render one element of the row (child)
	         * @param desc, the description of the element 
	  * 	   defined into the model props
	  * @param index, number of the child (usually passed directly by .map())
	  */
		renderChild: function renderChild(desc, index) {

			var content = this.props.data[desc[2]];

			return _react2.default.createElement(
				'td',
				{ key: "edr" + index, className: 'col-md-1' },
				this.renderType(desc, content)
			);
		},

		collectValues: function collectValues() {
			var data = {};
			for (var i = 0; i < this.props.model.desc.length; i++) {
				var name = this.props.model.desc[i][2];
				// Use the id specified into the render in order to identify the row
				data[name] = $("#etr" + this.props.reactKey + " [name='" + name + "']").val();
			}
			var uniquekey = this.props.data[this.props.model.key];
			return { key: uniquekey, input: data };
		},

		/* Active/desactive edit mode */
		switchMode: function switchMode() {

			if (this.state.edit == true) {
				var data = this.collectValues();

				if (data.key.toString().startsWith("__")) {
					// Invalid api id (given from the application)
					this.props.handler.save(data.key, data.input);
				} else {
					this.props.handler.update(data.key, data.input);
				}
			}

			this.setState({ edit: !this.state.edit });
		},

		/* Called when the user remove this row */
		deleteRow: function deleteRow() {

			var data = this.collectValues();

			if (this.state.edit == false) {
				this.props.handler.delete(data.key, data.input);
				this.props.onRemove(this.props.index);
			} else if (data.key.toString().startsWith("__")) {
				// Invalid api id (given from the application)
				this.props.onRemove(this.props.index);
			} else {
				this.setState({ edit: !this.state.edit });
			}
		},

		render: function render() {
			return _react2.default.createElement(
				'tr',
				{ id: "etr" + this.props.reactKey },
				this.props.model.desc.map(this.renderChild),
				_react2.default.createElement(
					'td',
					{ className: 'outside' },
					_react2.default.createElement(
						Button,
						{ onClick: this.switchMode },
						this.state.edit ? "Save" : "Edit"
					),
					_react2.default.createElement(
						Button,
						{ onClick: this.deleteRow },
						this.state.edit ? "Cancell" : "Remove"
					)
				)
			);
		}
	});

	/**
	 * Creates an editable table on which the user can remove/add as many rows as 
	 * he wants. The rows can also be edited/saved in any moment.
	 *
	 * @properties:
	 *	-name: the name of the handler
	 *
	 *	-model	an object which describes the data contained into
	 *		the row (see the component EdiTable). It must have one attribute
	 *		'key' and an attribute 'desc':
	 *
	 *		- desc: contains a list of 3-elements arrays, each one describing one field of a
	 *		        row. The 3 elements must be strings representing respectively 
	 *				[Columns label, field type, field name]
	 *			example ["List of addresses", "Input", "address"]
	 *			
	 *		- key: contains the name of an attribute present on the property
	 *	    	       `data` which will be used as identifier for each row. This id
	 *		       is sent to the handler when a row is removed/updated/saved.
	 *		       Example of use: iddhcprange for a table of dhcp ranges
	 *		
	 *		The model should finally look more ore less like this:
	 *		      {key: ... , desc: [ ["field" , "type", "name"], ... ]}
	 * 
	 *	-data,  an object containing a certain number of "name": "value" pairs.
	 *		It must contain all the "names" specified on the model property.
	 *	 	If the type specified on the model is "input" and the data for this
	 *		field is not specified then the value will be an empty string. 
	 *		The data of other types (!= "input") must always be specified.
	 *
	 */
	var Table = exports.Table = _react2.default.createClass({
		displayName: 'Table',


		/* This will force a rerendering on languae change */
		contextTypes: { lang: _react2.default.PropTypes.string },

		/* has a name prop */
		propTypes: { name: _react2.default.PropTypes.string.isRequired },

		getInitialState: function getInitialState() {
			return { values: [] };
		},

		getValues: function getValues() {
			this.setState({ values: _prompters.Prompters[this.props.name].getValues() });
		},

		componentWillMount: function componentWillMount() {
			var prompter = _prompters.Prompters[this.props.name];

			if (!prompter) {
				console.error(this.props.name + " is not a prompter!");
			} else if (prompter.init) {
				prompter.init(this.getValues.bind(this));
			}
		},

		renderHead: function renderHead() {
			function headerEl(mod, index) {
				return _react2.default.createElement(
					'th',
					{ key: "th" + index },
					' ',
					mod[0],
					' '
				);
			}
			return _react2.default.createElement(
				'thead',
				null,
				_react2.default.createElement(
					'tr',
					null,
					this.props.model.desc.map(headerEl)
				)
			);
		},

		renderRow: function renderRow(data, index) {

			var uniqkey = data[this.props.model.key];

			return _react2.default.createElement(Editable_tr, { key: "trw" + uniqkey,
				reactKey: "trw" + uniqkey,
				model: this.props.model,
				data: data,
				edit: data._edit,
				index: index,
				onRemove: this.removeRow,
				handler: _prompters.Prompters[this.props.name]
			});
		},

		removeRow: function removeRow(index) {
			this.state.values.splice(index, 1);
			this.setState({ values: this.state.values });
		},

		emptyRowsCount: 0, // Used to define unique keys when adding empty rows

		addRow: function addRow() {

			var newRow = { _edit: true }; // Add in edit mode

			if (this.state.values.length > 0) {

				/* Use the first row as example */
				newRow = $.extend(newRow, this.state.values[0]);

				for (var i = 0; i < this.props.model.desc.length; i++) {
					/* Leave inputs blanks */
					var type = this.props.model.desc[i][1];
					if (type.toLowerCase() == "input") {
						var field = this.props.model.desc[i][2];
						newRow[field] = "";
					}
				}
			} else if (_prompters.Prompters[this.props.name].getEmptyRow) {
				/* Ask for an empty row to the prompter */
				var emptyRow = _prompters.Prompters[this.props.name].getEmptyRow();
				newRow = $.extend(newRow, emptyRow);
			} else {
				console.error("Cannot fetch an the values of an empty row");
				return;
			}

			// Set an unique key
			newRow[this.props.model.key] = "___NotValidId" + this.emptyRowsCount++;

			// Add to the state	
			this.state.values.push(newRow);
			this.setState({ values: this.state.values });
		},

		render: function render() {
			return _react2.default.createElement(
				'div',
				null,
				_react2.default.createElement(
					'table',
					{ className: 'table table-bordered' },
					this.renderHead(),
					_react2.default.createElement(
						'tbody',
						null,
						this.state.values.map(this.renderRow)
					)
				),
				_react2.default.createElement(
					Button,
					{ onClick: this.addRow },
					'Add'
				)
			);
		}
	});

/***/ },

/***/ 173:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	module.exports = __webpack_require__(174).default;

/***/ },

/***/ 174:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
	  value: true
	});

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _redux = __webpack_require__(175);

	var _reducerAndActions = __webpack_require__(188);

	var _reducerAndActions2 = _interopRequireDefault(_reducerAndActions);

	var _Autosuggest = __webpack_require__(189);

	var _Autosuggest2 = _interopRequireDefault(_Autosuggest);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	function noop() {}

	var defaultTheme = {
	  container: 'react-autosuggest__container',
	  containerOpen: 'react-autosuggest__container--open',
	  input: 'react-autosuggest__input',
	  suggestionsContainer: 'react-autosuggest__suggestions-container',
	  suggestion: 'react-autosuggest__suggestion',
	  suggestionFocused: 'react-autosuggest__suggestion--focused',
	  sectionContainer: 'react-autosuggest__section-container',
	  sectionTitle: 'react-autosuggest__section-title',
	  sectionSuggestionsContainer: 'react-autosuggest__section-suggestions-container'
	};

	function mapToAutowhateverTheme(theme) {
	  var result = {};

	  for (var key in theme) {
	    switch (key) {
	      case 'suggestionsContainer':
	        result['itemsContainer'] = theme[key];
	        break;

	      case 'suggestion':
	        result['item'] = theme[key];
	        break;

	      case 'suggestionFocused':
	        result['itemFocused'] = theme[key];
	        break;

	      case 'sectionSuggestionsContainer':
	        result['sectionItemsContainer'] = theme[key];
	        break;

	      default:
	        result[key] = theme[key];
	    }
	  }

	  return result;
	}

	var AutosuggestContainer = function (_Component) {
	  _inherits(AutosuggestContainer, _Component);

	  function AutosuggestContainer() {
	    _classCallCheck(this, AutosuggestContainer);

	    var _this = _possibleConstructorReturn(this, Object.getPrototypeOf(AutosuggestContainer).call(this));

	    var initialState = {
	      isFocused: false,
	      isCollapsed: true,
	      focusedSectionIndex: null,
	      focusedSuggestionIndex: null,
	      valueBeforeUpDown: null,
	      lastAction: null
	    };

	    _this.store = (0, _redux.createStore)(_reducerAndActions2.default, initialState);

	    _this.saveInput = _this.saveInput.bind(_this);
	    return _this;
	  }

	  _createClass(AutosuggestContainer, [{
	    key: 'saveInput',
	    value: function saveInput(input) {
	      this.input = input;
	    }
	  }, {
	    key: 'render',
	    value: function render() {
	      var _props = this.props;
	      var multiSection = _props.multiSection;
	      var shouldRenderSuggestions = _props.shouldRenderSuggestions;
	      var suggestions = _props.suggestions;
	      var onSuggestionsUpdateRequested = _props.onSuggestionsUpdateRequested;
	      var getSuggestionValue = _props.getSuggestionValue;
	      var renderSuggestion = _props.renderSuggestion;
	      var renderSectionTitle = _props.renderSectionTitle;
	      var getSectionSuggestions = _props.getSectionSuggestions;
	      var inputProps = _props.inputProps;
	      var onSuggestionSelected = _props.onSuggestionSelected;
	      var focusInputOnSuggestionClick = _props.focusInputOnSuggestionClick;
	      var theme = _props.theme;
	      var id = _props.id;


	      return _react2.default.createElement(_Autosuggest2.default, { multiSection: multiSection,
	        shouldRenderSuggestions: shouldRenderSuggestions,
	        suggestions: suggestions,
	        onSuggestionsUpdateRequested: onSuggestionsUpdateRequested,
	        getSuggestionValue: getSuggestionValue,
	        renderSuggestion: renderSuggestion,
	        renderSectionTitle: renderSectionTitle,
	        getSectionSuggestions: getSectionSuggestions,
	        inputProps: inputProps,
	        onSuggestionSelected: onSuggestionSelected,
	        focusInputOnSuggestionClick: focusInputOnSuggestionClick,
	        theme: mapToAutowhateverTheme(theme),
	        id: id,
	        inputRef: this.saveInput,
	        store: this.store });
	    }
	  }]);

	  return AutosuggestContainer;
	}(_react.Component);

	AutosuggestContainer.propTypes = {
	  suggestions: _react.PropTypes.array.isRequired,
	  onSuggestionsUpdateRequested: _react.PropTypes.func,
	  getSuggestionValue: _react.PropTypes.func.isRequired,
	  renderSuggestion: _react.PropTypes.func.isRequired,
	  inputProps: function inputProps(props, propName) {
	    var inputProps = props[propName];

	    if (!inputProps.hasOwnProperty('value')) {
	      throw new Error('\'inputProps\' must have \'value\'.');
	    }

	    if (!inputProps.hasOwnProperty('onChange')) {
	      throw new Error('\'inputProps\' must have \'onChange\'.');
	    }
	  },
	  shouldRenderSuggestions: _react.PropTypes.func,
	  onSuggestionSelected: _react.PropTypes.func,
	  multiSection: _react.PropTypes.bool,
	  renderSectionTitle: _react.PropTypes.func,
	  getSectionSuggestions: _react.PropTypes.func,
	  focusInputOnSuggestionClick: _react.PropTypes.bool,
	  theme: _react.PropTypes.object,
	  id: _react.PropTypes.string
	};
	AutosuggestContainer.defaultProps = {
	  onSuggestionsUpdateRequested: noop,
	  shouldRenderSuggestions: function shouldRenderSuggestions(value) {
	    return value.trim().length > 0;
	  },
	  onSuggestionSelected: noop,
	  multiSection: false,
	  renderSectionTitle: function renderSectionTitle() {
	    throw new Error('`renderSectionTitle` must be provided');
	  },
	  getSectionSuggestions: function getSectionSuggestions() {
	    throw new Error('`getSectionSuggestions` must be provided');
	  },

	  focusInputOnSuggestionClick: true,
	  theme: defaultTheme,
	  id: '1'
	};
	exports.default = AutosuggestContainer;

/***/ },

/***/ 175:
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {'use strict';

	exports.__esModule = true;
	exports.compose = exports.applyMiddleware = exports.bindActionCreators = exports.combineReducers = exports.createStore = undefined;

	var _createStore = __webpack_require__(176);

	var _createStore2 = _interopRequireDefault(_createStore);

	var _combineReducers = __webpack_require__(183);

	var _combineReducers2 = _interopRequireDefault(_combineReducers);

	var _bindActionCreators = __webpack_require__(185);

	var _bindActionCreators2 = _interopRequireDefault(_bindActionCreators);

	var _applyMiddleware = __webpack_require__(186);

	var _applyMiddleware2 = _interopRequireDefault(_applyMiddleware);

	var _compose = __webpack_require__(187);

	var _compose2 = _interopRequireDefault(_compose);

	var _warning = __webpack_require__(184);

	var _warning2 = _interopRequireDefault(_warning);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

	/*
	* This is a dummy function to check if the function name has been altered by minification.
	* If the function has been minified and NODE_ENV !== 'production', warn the user.
	*/
	function isCrushed() {}

	if (process.env.NODE_ENV !== 'production' && typeof isCrushed.name === 'string' && isCrushed.name !== 'isCrushed') {
	  (0, _warning2["default"])('You are currently using minified code outside of NODE_ENV === \'production\'. ' + 'This means that you are running a slower development build of Redux. ' + 'You can use loose-envify (https://github.com/zertosh/loose-envify) for browserify ' + 'or DefinePlugin for webpack (http://stackoverflow.com/questions/30030031) ' + 'to ensure you have the correct code for your production build.');
	}

	exports.createStore = _createStore2["default"];
	exports.combineReducers = _combineReducers2["default"];
	exports.bindActionCreators = _bindActionCreators2["default"];
	exports.applyMiddleware = _applyMiddleware2["default"];
	exports.compose = _compose2["default"];
	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(3)))

/***/ },

/***/ 176:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	exports.__esModule = true;
	exports.ActionTypes = undefined;
	exports["default"] = createStore;

	var _isPlainObject = __webpack_require__(177);

	var _isPlainObject2 = _interopRequireDefault(_isPlainObject);

	var _symbolObservable = __webpack_require__(181);

	var _symbolObservable2 = _interopRequireDefault(_symbolObservable);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

	/**
	 * These are private action types reserved by Redux.
	 * For any unknown actions, you must return the current state.
	 * If the current state is undefined, you must return the initial state.
	 * Do not reference these action types directly in your code.
	 */
	var ActionTypes = exports.ActionTypes = {
	  INIT: '@@redux/INIT'
	};

	/**
	 * Creates a Redux store that holds the state tree.
	 * The only way to change the data in the store is to call `dispatch()` on it.
	 *
	 * There should only be a single store in your app. To specify how different
	 * parts of the state tree respond to actions, you may combine several reducers
	 * into a single reducer function by using `combineReducers`.
	 *
	 * @param {Function} reducer A function that returns the next state tree, given
	 * the current state tree and the action to handle.
	 *
	 * @param {any} [initialState] The initial state. You may optionally specify it
	 * to hydrate the state from the server in universal apps, or to restore a
	 * previously serialized user session.
	 * If you use `combineReducers` to produce the root reducer function, this must be
	 * an object with the same shape as `combineReducers` keys.
	 *
	 * @param {Function} enhancer The store enhancer. You may optionally specify it
	 * to enhance the store with third-party capabilities such as middleware,
	 * time travel, persistence, etc. The only store enhancer that ships with Redux
	 * is `applyMiddleware()`.
	 *
	 * @returns {Store} A Redux store that lets you read the state, dispatch actions
	 * and subscribe to changes.
	 */
	function createStore(reducer, initialState, enhancer) {
	  var _ref2;

	  if (typeof initialState === 'function' && typeof enhancer === 'undefined') {
	    enhancer = initialState;
	    initialState = undefined;
	  }

	  if (typeof enhancer !== 'undefined') {
	    if (typeof enhancer !== 'function') {
	      throw new Error('Expected the enhancer to be a function.');
	    }

	    return enhancer(createStore)(reducer, initialState);
	  }

	  if (typeof reducer !== 'function') {
	    throw new Error('Expected the reducer to be a function.');
	  }

	  var currentReducer = reducer;
	  var currentState = initialState;
	  var currentListeners = [];
	  var nextListeners = currentListeners;
	  var isDispatching = false;

	  function ensureCanMutateNextListeners() {
	    if (nextListeners === currentListeners) {
	      nextListeners = currentListeners.slice();
	    }
	  }

	  /**
	   * Reads the state tree managed by the store.
	   *
	   * @returns {any} The current state tree of your application.
	   */
	  function getState() {
	    return currentState;
	  }

	  /**
	   * Adds a change listener. It will be called any time an action is dispatched,
	   * and some part of the state tree may potentially have changed. You may then
	   * call `getState()` to read the current state tree inside the callback.
	   *
	   * You may call `dispatch()` from a change listener, with the following
	   * caveats:
	   *
	   * 1. The subscriptions are snapshotted just before every `dispatch()` call.
	   * If you subscribe or unsubscribe while the listeners are being invoked, this
	   * will not have any effect on the `dispatch()` that is currently in progress.
	   * However, the next `dispatch()` call, whether nested or not, will use a more
	   * recent snapshot of the subscription list.
	   *
	   * 2. The listener should not expect to see all state changes, as the state
	   * might have been updated multiple times during a nested `dispatch()` before
	   * the listener is called. It is, however, guaranteed that all subscribers
	   * registered before the `dispatch()` started will be called with the latest
	   * state by the time it exits.
	   *
	   * @param {Function} listener A callback to be invoked on every dispatch.
	   * @returns {Function} A function to remove this change listener.
	   */
	  function subscribe(listener) {
	    if (typeof listener !== 'function') {
	      throw new Error('Expected listener to be a function.');
	    }

	    var isSubscribed = true;

	    ensureCanMutateNextListeners();
	    nextListeners.push(listener);

	    return function unsubscribe() {
	      if (!isSubscribed) {
	        return;
	      }

	      isSubscribed = false;

	      ensureCanMutateNextListeners();
	      var index = nextListeners.indexOf(listener);
	      nextListeners.splice(index, 1);
	    };
	  }

	  /**
	   * Dispatches an action. It is the only way to trigger a state change.
	   *
	   * The `reducer` function, used to create the store, will be called with the
	   * current state tree and the given `action`. Its return value will
	   * be considered the **next** state of the tree, and the change listeners
	   * will be notified.
	   *
	   * The base implementation only supports plain object actions. If you want to
	   * dispatch a Promise, an Observable, a thunk, or something else, you need to
	   * wrap your store creating function into the corresponding middleware. For
	   * example, see the documentation for the `redux-thunk` package. Even the
	   * middleware will eventually dispatch plain object actions using this method.
	   *
	   * @param {Object} action A plain object representing “what changed”. It is
	   * a good idea to keep actions serializable so you can record and replay user
	   * sessions, or use the time travelling `redux-devtools`. An action must have
	   * a `type` property which may not be `undefined`. It is a good idea to use
	   * string constants for action types.
	   *
	   * @returns {Object} For convenience, the same action object you dispatched.
	   *
	   * Note that, if you use a custom middleware, it may wrap `dispatch()` to
	   * return something else (for example, a Promise you can await).
	   */
	  function dispatch(action) {
	    if (!(0, _isPlainObject2["default"])(action)) {
	      throw new Error('Actions must be plain objects. ' + 'Use custom middleware for async actions.');
	    }

	    if (typeof action.type === 'undefined') {
	      throw new Error('Actions may not have an undefined "type" property. ' + 'Have you misspelled a constant?');
	    }

	    if (isDispatching) {
	      throw new Error('Reducers may not dispatch actions.');
	    }

	    try {
	      isDispatching = true;
	      currentState = currentReducer(currentState, action);
	    } finally {
	      isDispatching = false;
	    }

	    var listeners = currentListeners = nextListeners;
	    for (var i = 0; i < listeners.length; i++) {
	      listeners[i]();
	    }

	    return action;
	  }

	  /**
	   * Replaces the reducer currently used by the store to calculate the state.
	   *
	   * You might need this if your app implements code splitting and you want to
	   * load some of the reducers dynamically. You might also need this if you
	   * implement a hot reloading mechanism for Redux.
	   *
	   * @param {Function} nextReducer The reducer for the store to use instead.
	   * @returns {void}
	   */
	  function replaceReducer(nextReducer) {
	    if (typeof nextReducer !== 'function') {
	      throw new Error('Expected the nextReducer to be a function.');
	    }

	    currentReducer = nextReducer;
	    dispatch({ type: ActionTypes.INIT });
	  }

	  /**
	   * Interoperability point for observable/reactive libraries.
	   * @returns {observable} A minimal observable of state changes.
	   * For more information, see the observable proposal:
	   * https://github.com/zenparsing/es-observable
	   */
	  function observable() {
	    var _ref;

	    var outerSubscribe = subscribe;
	    return _ref = {
	      /**
	       * The minimal observable subscription method.
	       * @param {Object} observer Any object that can be used as an observer.
	       * The observer object should have a `next` method.
	       * @returns {subscription} An object with an `unsubscribe` method that can
	       * be used to unsubscribe the observable from the store, and prevent further
	       * emission of values from the observable.
	       */

	      subscribe: function subscribe(observer) {
	        if (typeof observer !== 'object') {
	          throw new TypeError('Expected the observer to be an object.');
	        }

	        function observeState() {
	          if (observer.next) {
	            observer.next(getState());
	          }
	        }

	        observeState();
	        var unsubscribe = outerSubscribe(observeState);
	        return { unsubscribe: unsubscribe };
	      }
	    }, _ref[_symbolObservable2["default"]] = function () {
	      return this;
	    }, _ref;
	  }

	  // When a store is created, an "INIT" action is dispatched so that every
	  // reducer returns their initial state. This effectively populates
	  // the initial state tree.
	  dispatch({ type: ActionTypes.INIT });

	  return _ref2 = {
	    dispatch: dispatch,
	    subscribe: subscribe,
	    getState: getState,
	    replaceReducer: replaceReducer
	  }, _ref2[_symbolObservable2["default"]] = observable, _ref2;
	}

/***/ },

/***/ 177:
/***/ function(module, exports, __webpack_require__) {

	var getPrototype = __webpack_require__(178),
	    isHostObject = __webpack_require__(179),
	    isObjectLike = __webpack_require__(180);

	/** `Object#toString` result references. */
	var objectTag = '[object Object]';

	/** Used for built-in method references. */
	var objectProto = Object.prototype;

	/** Used to resolve the decompiled source of functions. */
	var funcToString = Function.prototype.toString;

	/** Used to check objects for own properties. */
	var hasOwnProperty = objectProto.hasOwnProperty;

	/** Used to infer the `Object` constructor. */
	var objectCtorString = funcToString.call(Object);

	/**
	 * Used to resolve the
	 * [`toStringTag`](http://ecma-international.org/ecma-262/6.0/#sec-object.prototype.tostring)
	 * of values.
	 */
	var objectToString = objectProto.toString;

	/**
	 * Checks if `value` is a plain object, that is, an object created by the
	 * `Object` constructor or one with a `[[Prototype]]` of `null`.
	 *
	 * @static
	 * @memberOf _
	 * @since 0.8.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a plain object,
	 *  else `false`.
	 * @example
	 *
	 * function Foo() {
	 *   this.a = 1;
	 * }
	 *
	 * _.isPlainObject(new Foo);
	 * // => false
	 *
	 * _.isPlainObject([1, 2, 3]);
	 * // => false
	 *
	 * _.isPlainObject({ 'x': 0, 'y': 0 });
	 * // => true
	 *
	 * _.isPlainObject(Object.create(null));
	 * // => true
	 */
	function isPlainObject(value) {
	  if (!isObjectLike(value) ||
	      objectToString.call(value) != objectTag || isHostObject(value)) {
	    return false;
	  }
	  var proto = getPrototype(value);
	  if (proto === null) {
	    return true;
	  }
	  var Ctor = hasOwnProperty.call(proto, 'constructor') && proto.constructor;
	  return (typeof Ctor == 'function' &&
	    Ctor instanceof Ctor && funcToString.call(Ctor) == objectCtorString);
	}

	module.exports = isPlainObject;


/***/ },

/***/ 178:
/***/ function(module, exports) {

	/* Built-in method references for those with the same name as other `lodash` methods. */
	var nativeGetPrototype = Object.getPrototypeOf;

	/**
	 * Gets the `[[Prototype]]` of `value`.
	 *
	 * @private
	 * @param {*} value The value to query.
	 * @returns {null|Object} Returns the `[[Prototype]]`.
	 */
	function getPrototype(value) {
	  return nativeGetPrototype(Object(value));
	}

	module.exports = getPrototype;


/***/ },

/***/ 179:
/***/ function(module, exports) {

	/**
	 * Checks if `value` is a host object in IE < 9.
	 *
	 * @private
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a host object, else `false`.
	 */
	function isHostObject(value) {
	  // Many host objects are `Object` objects that can coerce to strings
	  // despite having improperly defined `toString` methods.
	  var result = false;
	  if (value != null && typeof value.toString != 'function') {
	    try {
	      result = !!(value + '');
	    } catch (e) {}
	  }
	  return result;
	}

	module.exports = isHostObject;


/***/ },

/***/ 180:
/***/ function(module, exports) {

	/**
	 * Checks if `value` is object-like. A value is object-like if it's not `null`
	 * and has a `typeof` result of "object".
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is object-like, else `false`.
	 * @example
	 *
	 * _.isObjectLike({});
	 * // => true
	 *
	 * _.isObjectLike([1, 2, 3]);
	 * // => true
	 *
	 * _.isObjectLike(_.noop);
	 * // => false
	 *
	 * _.isObjectLike(null);
	 * // => false
	 */
	function isObjectLike(value) {
	  return !!value && typeof value == 'object';
	}

	module.exports = isObjectLike;


/***/ },

/***/ 181:
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(global) {/* global window */
	'use strict';

	module.exports = __webpack_require__(182)(global || window || this);

	/* WEBPACK VAR INJECTION */}.call(exports, (function() { return this; }())))

/***/ },

/***/ 182:
/***/ function(module, exports) {

	'use strict';

	module.exports = function symbolObservablePonyfill(root) {
		var result;
		var Symbol = root.Symbol;

		if (typeof Symbol === 'function') {
			if (Symbol.observable) {
				result = Symbol.observable;
			} else {
				result = Symbol('observable');
				Symbol.observable = result;
			}
		} else {
			result = '@@observable';
		}

		return result;
	};


/***/ },

/***/ 183:
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {'use strict';

	exports.__esModule = true;
	exports["default"] = combineReducers;

	var _createStore = __webpack_require__(176);

	var _isPlainObject = __webpack_require__(177);

	var _isPlainObject2 = _interopRequireDefault(_isPlainObject);

	var _warning = __webpack_require__(184);

	var _warning2 = _interopRequireDefault(_warning);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

	function getUndefinedStateErrorMessage(key, action) {
	  var actionType = action && action.type;
	  var actionName = actionType && '"' + actionType.toString() + '"' || 'an action';

	  return 'Given action ' + actionName + ', reducer "' + key + '" returned undefined. ' + 'To ignore an action, you must explicitly return the previous state.';
	}

	function getUnexpectedStateShapeWarningMessage(inputState, reducers, action) {
	  var reducerKeys = Object.keys(reducers);
	  var argumentName = action && action.type === _createStore.ActionTypes.INIT ? 'initialState argument passed to createStore' : 'previous state received by the reducer';

	  if (reducerKeys.length === 0) {
	    return 'Store does not have a valid reducer. Make sure the argument passed ' + 'to combineReducers is an object whose values are reducers.';
	  }

	  if (!(0, _isPlainObject2["default"])(inputState)) {
	    return 'The ' + argumentName + ' has unexpected type of "' + {}.toString.call(inputState).match(/\s([a-z|A-Z]+)/)[1] + '". Expected argument to be an object with the following ' + ('keys: "' + reducerKeys.join('", "') + '"');
	  }

	  var unexpectedKeys = Object.keys(inputState).filter(function (key) {
	    return !reducers.hasOwnProperty(key);
	  });

	  if (unexpectedKeys.length > 0) {
	    return 'Unexpected ' + (unexpectedKeys.length > 1 ? 'keys' : 'key') + ' ' + ('"' + unexpectedKeys.join('", "') + '" found in ' + argumentName + '. ') + 'Expected to find one of the known reducer keys instead: ' + ('"' + reducerKeys.join('", "') + '". Unexpected keys will be ignored.');
	  }
	}

	function assertReducerSanity(reducers) {
	  Object.keys(reducers).forEach(function (key) {
	    var reducer = reducers[key];
	    var initialState = reducer(undefined, { type: _createStore.ActionTypes.INIT });

	    if (typeof initialState === 'undefined') {
	      throw new Error('Reducer "' + key + '" returned undefined during initialization. ' + 'If the state passed to the reducer is undefined, you must ' + 'explicitly return the initial state. The initial state may ' + 'not be undefined.');
	    }

	    var type = '@@redux/PROBE_UNKNOWN_ACTION_' + Math.random().toString(36).substring(7).split('').join('.');
	    if (typeof reducer(undefined, { type: type }) === 'undefined') {
	      throw new Error('Reducer "' + key + '" returned undefined when probed with a random type. ' + ('Don\'t try to handle ' + _createStore.ActionTypes.INIT + ' or other actions in "redux/*" ') + 'namespace. They are considered private. Instead, you must return the ' + 'current state for any unknown actions, unless it is undefined, ' + 'in which case you must return the initial state, regardless of the ' + 'action type. The initial state may not be undefined.');
	    }
	  });
	}

	/**
	 * Turns an object whose values are different reducer functions, into a single
	 * reducer function. It will call every child reducer, and gather their results
	 * into a single state object, whose keys correspond to the keys of the passed
	 * reducer functions.
	 *
	 * @param {Object} reducers An object whose values correspond to different
	 * reducer functions that need to be combined into one. One handy way to obtain
	 * it is to use ES6 `import * as reducers` syntax. The reducers may never return
	 * undefined for any action. Instead, they should return their initial state
	 * if the state passed to them was undefined, and the current state for any
	 * unrecognized action.
	 *
	 * @returns {Function} A reducer function that invokes every reducer inside the
	 * passed object, and builds a state object with the same shape.
	 */
	function combineReducers(reducers) {
	  var reducerKeys = Object.keys(reducers);
	  var finalReducers = {};
	  for (var i = 0; i < reducerKeys.length; i++) {
	    var key = reducerKeys[i];
	    if (typeof reducers[key] === 'function') {
	      finalReducers[key] = reducers[key];
	    }
	  }
	  var finalReducerKeys = Object.keys(finalReducers);

	  var sanityError;
	  try {
	    assertReducerSanity(finalReducers);
	  } catch (e) {
	    sanityError = e;
	  }

	  return function combination() {
	    var state = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];
	    var action = arguments[1];

	    if (sanityError) {
	      throw sanityError;
	    }

	    if (process.env.NODE_ENV !== 'production') {
	      var warningMessage = getUnexpectedStateShapeWarningMessage(state, finalReducers, action);
	      if (warningMessage) {
	        (0, _warning2["default"])(warningMessage);
	      }
	    }

	    var hasChanged = false;
	    var nextState = {};
	    for (var i = 0; i < finalReducerKeys.length; i++) {
	      var key = finalReducerKeys[i];
	      var reducer = finalReducers[key];
	      var previousStateForKey = state[key];
	      var nextStateForKey = reducer(previousStateForKey, action);
	      if (typeof nextStateForKey === 'undefined') {
	        var errorMessage = getUndefinedStateErrorMessage(key, action);
	        throw new Error(errorMessage);
	      }
	      nextState[key] = nextStateForKey;
	      hasChanged = hasChanged || nextStateForKey !== previousStateForKey;
	    }
	    return hasChanged ? nextState : state;
	  };
	}
	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(3)))

/***/ },

/***/ 184:
/***/ function(module, exports) {

	'use strict';

	exports.__esModule = true;
	exports["default"] = warning;
	/**
	 * Prints a warning in the console if it exists.
	 *
	 * @param {String} message The warning message.
	 * @returns {void}
	 */
	function warning(message) {
	  /* eslint-disable no-console */
	  if (typeof console !== 'undefined' && typeof console.error === 'function') {
	    console.error(message);
	  }
	  /* eslint-enable no-console */
	  try {
	    // This error was thrown as a convenience so that if you enable
	    // "break on all exceptions" in your console,
	    // it would pause the execution at this line.
	    throw new Error(message);
	    /* eslint-disable no-empty */
	  } catch (e) {}
	  /* eslint-enable no-empty */
	}

/***/ },

/***/ 185:
/***/ function(module, exports) {

	'use strict';

	exports.__esModule = true;
	exports["default"] = bindActionCreators;
	function bindActionCreator(actionCreator, dispatch) {
	  return function () {
	    return dispatch(actionCreator.apply(undefined, arguments));
	  };
	}

	/**
	 * Turns an object whose values are action creators, into an object with the
	 * same keys, but with every function wrapped into a `dispatch` call so they
	 * may be invoked directly. This is just a convenience method, as you can call
	 * `store.dispatch(MyActionCreators.doSomething())` yourself just fine.
	 *
	 * For convenience, you can also pass a single function as the first argument,
	 * and get a function in return.
	 *
	 * @param {Function|Object} actionCreators An object whose values are action
	 * creator functions. One handy way to obtain it is to use ES6 `import * as`
	 * syntax. You may also pass a single function.
	 *
	 * @param {Function} dispatch The `dispatch` function available on your Redux
	 * store.
	 *
	 * @returns {Function|Object} The object mimicking the original object, but with
	 * every action creator wrapped into the `dispatch` call. If you passed a
	 * function as `actionCreators`, the return value will also be a single
	 * function.
	 */
	function bindActionCreators(actionCreators, dispatch) {
	  if (typeof actionCreators === 'function') {
	    return bindActionCreator(actionCreators, dispatch);
	  }

	  if (typeof actionCreators !== 'object' || actionCreators === null) {
	    throw new Error('bindActionCreators expected an object or a function, instead received ' + (actionCreators === null ? 'null' : typeof actionCreators) + '. ' + 'Did you write "import ActionCreators from" instead of "import * as ActionCreators from"?');
	  }

	  var keys = Object.keys(actionCreators);
	  var boundActionCreators = {};
	  for (var i = 0; i < keys.length; i++) {
	    var key = keys[i];
	    var actionCreator = actionCreators[key];
	    if (typeof actionCreator === 'function') {
	      boundActionCreators[key] = bindActionCreator(actionCreator, dispatch);
	    }
	  }
	  return boundActionCreators;
	}

/***/ },

/***/ 186:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	exports.__esModule = true;

	var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

	exports["default"] = applyMiddleware;

	var _compose = __webpack_require__(187);

	var _compose2 = _interopRequireDefault(_compose);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

	/**
	 * Creates a store enhancer that applies middleware to the dispatch method
	 * of the Redux store. This is handy for a variety of tasks, such as expressing
	 * asynchronous actions in a concise manner, or logging every action payload.
	 *
	 * See `redux-thunk` package as an example of the Redux middleware.
	 *
	 * Because middleware is potentially asynchronous, this should be the first
	 * store enhancer in the composition chain.
	 *
	 * Note that each middleware will be given the `dispatch` and `getState` functions
	 * as named arguments.
	 *
	 * @param {...Function} middlewares The middleware chain to be applied.
	 * @returns {Function} A store enhancer applying the middleware.
	 */
	function applyMiddleware() {
	  for (var _len = arguments.length, middlewares = Array(_len), _key = 0; _key < _len; _key++) {
	    middlewares[_key] = arguments[_key];
	  }

	  return function (createStore) {
	    return function (reducer, initialState, enhancer) {
	      var store = createStore(reducer, initialState, enhancer);
	      var _dispatch = store.dispatch;
	      var chain = [];

	      var middlewareAPI = {
	        getState: store.getState,
	        dispatch: function dispatch(action) {
	          return _dispatch(action);
	        }
	      };
	      chain = middlewares.map(function (middleware) {
	        return middleware(middlewareAPI);
	      });
	      _dispatch = _compose2["default"].apply(undefined, chain)(store.dispatch);

	      return _extends({}, store, {
	        dispatch: _dispatch
	      });
	    };
	  };
	}

/***/ },

/***/ 187:
/***/ function(module, exports) {

	"use strict";

	exports.__esModule = true;
	exports["default"] = compose;
	/**
	 * Composes single-argument functions from right to left. The rightmost
	 * function can take multiple arguments as it provides the signature for
	 * the resulting composite function.
	 *
	 * @param {...Function} funcs The functions to compose.
	 * @returns {Function} A function obtained by composing the argument functions
	 * from right to left. For example, compose(f, g, h) is identical to doing
	 * (...args) => f(g(h(...args))).
	 */

	function compose() {
	  for (var _len = arguments.length, funcs = Array(_len), _key = 0; _key < _len; _key++) {
	    funcs[_key] = arguments[_key];
	  }

	  if (funcs.length === 0) {
	    return function (arg) {
	      return arg;
	    };
	  } else {
	    var _ret = function () {
	      var last = funcs[funcs.length - 1];
	      var rest = funcs.slice(0, -1);
	      return {
	        v: function v() {
	          return rest.reduceRight(function (composed, f) {
	            return f(composed);
	          }, last.apply(undefined, arguments));
	        }
	      };
	    }();

	    if (typeof _ret === "object") return _ret.v;
	  }
	}

/***/ },

/***/ 188:
/***/ function(module, exports) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
	  value: true
	});

	var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

	exports.inputFocused = inputFocused;
	exports.inputBlurred = inputBlurred;
	exports.inputChanged = inputChanged;
	exports.updateFocusedSuggestion = updateFocusedSuggestion;
	exports.revealSuggestions = revealSuggestions;
	exports.closeSuggestions = closeSuggestions;
	exports.default = reducer;
	var INPUT_FOCUSED = 'INPUT_FOCUSED';
	var INPUT_BLURRED = 'INPUT_BLURRED';
	var INPUT_CHANGED = 'INPUT_CHANGED';
	var UPDATE_FOCUSED_SUGGESTION = 'UPDATE_FOCUSED_SUGGESTION';
	var REVEAL_SUGGESTIONS = 'REVEAL_SUGGESTIONS';
	var CLOSE_SUGGESTIONS = 'CLOSE_SUGGESTIONS';

	function inputFocused(shouldRenderSuggestions) {
	  return {
	    type: INPUT_FOCUSED,
	    shouldRenderSuggestions: shouldRenderSuggestions
	  };
	}

	function inputBlurred() {
	  return {
	    type: INPUT_BLURRED
	  };
	}

	function inputChanged(shouldRenderSuggestions, lastAction) {
	  return {
	    type: INPUT_CHANGED,
	    shouldRenderSuggestions: shouldRenderSuggestions,
	    lastAction: lastAction
	  };
	}

	function updateFocusedSuggestion(sectionIndex, suggestionIndex, value) {
	  return {
	    type: UPDATE_FOCUSED_SUGGESTION,
	    sectionIndex: sectionIndex,
	    suggestionIndex: suggestionIndex,
	    value: value
	  };
	}

	function revealSuggestions() {
	  return {
	    type: REVEAL_SUGGESTIONS
	  };
	}

	function closeSuggestions(lastAction) {
	  return {
	    type: CLOSE_SUGGESTIONS,
	    lastAction: lastAction
	  };
	}

	function reducer(state, action) {
	  switch (action.type) {
	    case INPUT_FOCUSED:
	      return _extends({}, state, {
	        isFocused: true,
	        isCollapsed: !action.shouldRenderSuggestions
	      });

	    case INPUT_BLURRED:
	      return _extends({}, state, {
	        isFocused: false,
	        focusedSectionIndex: null,
	        focusedSuggestionIndex: null,
	        valueBeforeUpDown: null,
	        isCollapsed: true
	      });

	    case INPUT_CHANGED:
	      return _extends({}, state, {
	        focusedSectionIndex: null,
	        focusedSuggestionIndex: null,
	        valueBeforeUpDown: null,
	        isCollapsed: !action.shouldRenderSuggestions,
	        lastAction: action.lastAction
	      });

	    case UPDATE_FOCUSED_SUGGESTION:
	      {
	        var value = action.value;
	        var sectionIndex = action.sectionIndex;
	        var suggestionIndex = action.suggestionIndex;

	        var valueBeforeUpDown = state.valueBeforeUpDown === null && typeof value !== 'undefined' ? value : state.valueBeforeUpDown;

	        return _extends({}, state, {
	          focusedSectionIndex: sectionIndex,
	          focusedSuggestionIndex: suggestionIndex,
	          valueBeforeUpDown: valueBeforeUpDown
	        });
	      }

	    case REVEAL_SUGGESTIONS:
	      return _extends({}, state, {
	        isCollapsed: false
	      });

	    case CLOSE_SUGGESTIONS:
	      return _extends({}, state, {
	        focusedSectionIndex: null,
	        focusedSuggestionIndex: null,
	        valueBeforeUpDown: null,
	        isCollapsed: true,
	        lastAction: action.lastAction
	      });

	    default:
	      return state;
	  }
	}

/***/ },

/***/ 189:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
	  value: true
	});

	var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _reactRedux = __webpack_require__(190);

	var _reducerAndActions = __webpack_require__(188);

	var _reactAutowhatever = __webpack_require__(203);

	var _reactAutowhatever2 = _interopRequireDefault(_reactAutowhatever);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	function mapStateToProps(state) {
	  return {
	    isFocused: state.isFocused,
	    isCollapsed: state.isCollapsed,
	    focusedSectionIndex: state.focusedSectionIndex,
	    focusedSuggestionIndex: state.focusedSuggestionIndex,
	    valueBeforeUpDown: state.valueBeforeUpDown,
	    lastAction: state.lastAction
	  };
	}

	function mapDispatchToProps(dispatch) {
	  return {
	    inputFocused: function inputFocused(shouldRenderSuggestions) {
	      dispatch((0, _reducerAndActions.inputFocused)(shouldRenderSuggestions));
	    },
	    inputBlurred: function inputBlurred() {
	      dispatch((0, _reducerAndActions.inputBlurred)());
	    },
	    inputChanged: function inputChanged(shouldRenderSuggestions, lastAction) {
	      dispatch((0, _reducerAndActions.inputChanged)(shouldRenderSuggestions, lastAction));
	    },
	    updateFocusedSuggestion: function updateFocusedSuggestion(sectionIndex, suggestionIndex, value) {
	      dispatch((0, _reducerAndActions.updateFocusedSuggestion)(sectionIndex, suggestionIndex, value));
	    },
	    revealSuggestions: function revealSuggestions() {
	      dispatch((0, _reducerAndActions.revealSuggestions)());
	    },
	    closeSuggestions: function closeSuggestions(lastAction) {
	      dispatch((0, _reducerAndActions.closeSuggestions)(lastAction));
	    }
	  };
	}

	var Autosuggest = function (_Component) {
	  _inherits(Autosuggest, _Component);

	  function Autosuggest() {
	    _classCallCheck(this, Autosuggest);

	    var _this = _possibleConstructorReturn(this, Object.getPrototypeOf(Autosuggest).call(this));

	    _this.saveInput = _this.saveInput.bind(_this);
	    return _this;
	  }

	  _createClass(Autosuggest, [{
	    key: 'componentWillReceiveProps',
	    value: function componentWillReceiveProps(nextProps) {
	      if (nextProps.suggestions !== this.props.suggestions) {
	        var suggestions = nextProps.suggestions;
	        var inputProps = nextProps.inputProps;
	        var shouldRenderSuggestions = nextProps.shouldRenderSuggestions;
	        var isCollapsed = nextProps.isCollapsed;
	        var revealSuggestions = nextProps.revealSuggestions;
	        var lastAction = nextProps.lastAction;
	        var value = inputProps.value;


	        if (isCollapsed && lastAction !== 'click' && lastAction !== 'enter' && suggestions.length > 0 && shouldRenderSuggestions(value)) {
	          revealSuggestions();
	        }
	      }
	    }
	  }, {
	    key: 'getSuggestion',
	    value: function getSuggestion(sectionIndex, suggestionIndex) {
	      var _props = this.props;
	      var suggestions = _props.suggestions;
	      var multiSection = _props.multiSection;
	      var getSectionSuggestions = _props.getSectionSuggestions;


	      if (multiSection) {
	        return getSectionSuggestions(suggestions[sectionIndex])[suggestionIndex];
	      }

	      return suggestions[suggestionIndex];
	    }
	  }, {
	    key: 'getFocusedSuggestion',
	    value: function getFocusedSuggestion() {
	      var _props2 = this.props;
	      var focusedSectionIndex = _props2.focusedSectionIndex;
	      var focusedSuggestionIndex = _props2.focusedSuggestionIndex;


	      if (focusedSuggestionIndex === null) {
	        return null;
	      }

	      return this.getSuggestion(focusedSectionIndex, focusedSuggestionIndex);
	    }
	  }, {
	    key: 'getSuggestionValueByIndex',
	    value: function getSuggestionValueByIndex(sectionIndex, suggestionIndex) {
	      var getSuggestionValue = this.props.getSuggestionValue;


	      return getSuggestionValue(this.getSuggestion(sectionIndex, suggestionIndex));
	    }
	  }, {
	    key: 'getSuggestionIndices',
	    value: function getSuggestionIndices(suggestionElement) {
	      var sectionIndex = suggestionElement.getAttribute('data-section-index');
	      var suggestionIndex = suggestionElement.getAttribute('data-suggestion-index');

	      return {
	        sectionIndex: typeof sectionIndex === 'string' ? parseInt(sectionIndex, 10) : null,
	        suggestionIndex: parseInt(suggestionIndex, 10)
	      };
	    }
	  }, {
	    key: 'findSuggestionElement',
	    value: function findSuggestionElement(startNode) {
	      var node = startNode;

	      do {
	        if (node.getAttribute('data-suggestion-index') !== null) {
	          return node;
	        }

	        node = node.parentNode;
	      } while (node !== null);

	      console.error('Clicked element:', startNode); // eslint-disable-line no-console
	      throw new Error('Couldn\'t find suggestion element');
	    }
	  }, {
	    key: 'maybeCallOnChange',
	    value: function maybeCallOnChange(event, newValue, method) {
	      var _props$inputProps = this.props.inputProps;
	      var value = _props$inputProps.value;
	      var onChange = _props$inputProps.onChange;


	      if (newValue !== value) {
	        onChange && onChange(event, { newValue: newValue, method: method });
	      }
	    }
	  }, {
	    key: 'maybeCallOnSuggestionsUpdateRequested',
	    value: function maybeCallOnSuggestionsUpdateRequested(data) {
	      var _props3 = this.props;
	      var onSuggestionsUpdateRequested = _props3.onSuggestionsUpdateRequested;
	      var shouldRenderSuggestions = _props3.shouldRenderSuggestions;


	      if (shouldRenderSuggestions(data.value)) {
	        onSuggestionsUpdateRequested(data);
	      }
	    }
	  }, {
	    key: 'willRenderSuggestions',
	    value: function willRenderSuggestions() {
	      var _props4 = this.props;
	      var suggestions = _props4.suggestions;
	      var inputProps = _props4.inputProps;
	      var shouldRenderSuggestions = _props4.shouldRenderSuggestions;
	      var value = inputProps.value;


	      return suggestions.length > 0 && shouldRenderSuggestions(value);
	    }
	  }, {
	    key: 'saveInput',
	    value: function saveInput(autowhatever) {
	      if (autowhatever !== null) {
	        var input = autowhatever.refs.input;

	        this.input = input;
	        this.props.inputRef(input);
	      }
	    }
	  }, {
	    key: 'render',
	    value: function render() {
	      var _this2 = this;

	      var _props5 = this.props;
	      var suggestions = _props5.suggestions;
	      var renderSuggestion = _props5.renderSuggestion;
	      var inputProps = _props5.inputProps;
	      var shouldRenderSuggestions = _props5.shouldRenderSuggestions;
	      var onSuggestionSelected = _props5.onSuggestionSelected;
	      var multiSection = _props5.multiSection;
	      var renderSectionTitle = _props5.renderSectionTitle;
	      var id = _props5.id;
	      var getSectionSuggestions = _props5.getSectionSuggestions;
	      var focusInputOnSuggestionClick = _props5.focusInputOnSuggestionClick;
	      var theme = _props5.theme;
	      var isFocused = _props5.isFocused;
	      var isCollapsed = _props5.isCollapsed;
	      var focusedSectionIndex = _props5.focusedSectionIndex;
	      var focusedSuggestionIndex = _props5.focusedSuggestionIndex;
	      var valueBeforeUpDown = _props5.valueBeforeUpDown;
	      var inputFocused = _props5.inputFocused;
	      var inputBlurred = _props5.inputBlurred;
	      var inputChanged = _props5.inputChanged;
	      var updateFocusedSuggestion = _props5.updateFocusedSuggestion;
	      var revealSuggestions = _props5.revealSuggestions;
	      var closeSuggestions = _props5.closeSuggestions;
	      var value = inputProps.value;
	      var _onBlur = inputProps.onBlur;
	      var _onFocus = inputProps.onFocus;
	      var _onKeyDown = inputProps.onKeyDown;

	      var isOpen = isFocused && !isCollapsed && this.willRenderSuggestions();
	      var items = isOpen ? suggestions : [];
	      var autowhateverInputProps = _extends({}, inputProps, {
	        onFocus: function onFocus(event) {
	          if (!_this2.justClickedOnSuggestion) {
	            inputFocused(shouldRenderSuggestions(value));
	            _onFocus && _onFocus(event);
	          }
	        },
	        onBlur: function onBlur(event) {
	          _this2.onBlurEvent = event;

	          if (!_this2.justClickedOnSuggestion) {
	            inputBlurred();
	            _onBlur && _onBlur(event);

	            if (valueBeforeUpDown !== null && value !== valueBeforeUpDown) {
	              _this2.maybeCallOnSuggestionsUpdateRequested({ value: value, reason: 'blur' });
	            }
	          }
	        },
	        onChange: function onChange(event) {
	          var value = event.target.value;
	          var shouldRenderSuggestions = _this2.props.shouldRenderSuggestions;


	          _this2.maybeCallOnChange(event, value, 'type');
	          inputChanged(shouldRenderSuggestions(value), 'type');
	          _this2.maybeCallOnSuggestionsUpdateRequested({ value: value, reason: 'type' });
	        },
	        onKeyDown: function onKeyDown(event, data) {
	          switch (event.key) {
	            case 'ArrowDown':
	            case 'ArrowUp':
	              if (isCollapsed) {
	                if (_this2.willRenderSuggestions()) {
	                  revealSuggestions();
	                }
	              } else if (suggestions.length > 0) {
	                var newFocusedSectionIndex = data.newFocusedSectionIndex;
	                var newFocusedItemIndex = data.newFocusedItemIndex;

	                var newValue = newFocusedItemIndex === null ? valueBeforeUpDown : _this2.getSuggestionValueByIndex(newFocusedSectionIndex, newFocusedItemIndex);

	                updateFocusedSuggestion(newFocusedSectionIndex, newFocusedItemIndex, value);
	                _this2.maybeCallOnChange(event, newValue, event.key === 'ArrowDown' ? 'down' : 'up');
	              }
	              event.preventDefault();
	              break;

	            case 'Enter':
	              {
	                var focusedSuggestion = _this2.getFocusedSuggestion();

	                closeSuggestions('enter');

	                if (focusedSuggestion !== null) {
	                  onSuggestionSelected(event, {
	                    suggestion: focusedSuggestion,
	                    suggestionValue: value,
	                    sectionIndex: focusedSectionIndex,
	                    method: 'enter'
	                  });
	                  _this2.maybeCallOnSuggestionsUpdateRequested({ value: value, reason: 'enter' });
	                }
	                break;
	              }

	            case 'Escape':
	              if (isOpen) {
	                // If input.type === 'search', the browser clears the input
	                // when Escape is pressed. We want to disable this default
	                // behaviour so that, when suggestions are shown, we just hide
	                // them, without clearing the input.
	                event.preventDefault();
	              }

	              if (valueBeforeUpDown === null) {
	                // Didn't interact with Up/Down
	                if (!isOpen) {
	                  _this2.maybeCallOnChange(event, '', 'escape');
	                  _this2.maybeCallOnSuggestionsUpdateRequested({ value: '', reason: 'escape' });
	                }
	              } else {
	                // Interacted with Up/Down
	                _this2.maybeCallOnChange(event, valueBeforeUpDown, 'escape');
	              }

	              closeSuggestions('escape');
	              break;
	          }

	          _onKeyDown && _onKeyDown(event);
	        }
	      });
	      var onMouseEnter = function onMouseEnter(event, _ref) {
	        var sectionIndex = _ref.sectionIndex;
	        var itemIndex = _ref.itemIndex;

	        updateFocusedSuggestion(sectionIndex, itemIndex);
	      };
	      var onMouseLeave = function onMouseLeave() {
	        updateFocusedSuggestion(null, null);
	      };
	      var onMouseDown = function onMouseDown() {
	        _this2.justClickedOnSuggestion = true;
	      };
	      var onClick = function onClick(event) {
	        var _getSuggestionIndices = _this2.getSuggestionIndices(_this2.findSuggestionElement(event.target));

	        var sectionIndex = _getSuggestionIndices.sectionIndex;
	        var suggestionIndex = _getSuggestionIndices.suggestionIndex;

	        var clickedSuggestion = _this2.getSuggestion(sectionIndex, suggestionIndex);
	        var clickedSuggestionValue = _this2.props.getSuggestionValue(clickedSuggestion);

	        _this2.maybeCallOnChange(event, clickedSuggestionValue, 'click');
	        onSuggestionSelected(event, {
	          suggestion: clickedSuggestion,
	          suggestionValue: clickedSuggestionValue,
	          sectionIndex: sectionIndex,
	          method: 'click'
	        });
	        closeSuggestions('click');

	        if (focusInputOnSuggestionClick === true) {
	          _this2.input.focus();
	        } else {
	          inputBlurred();
	          _onBlur && _onBlur(_this2.onBlurEvent);
	        }

	        _this2.maybeCallOnSuggestionsUpdateRequested({ value: clickedSuggestionValue, reason: 'click' });

	        setTimeout(function () {
	          _this2.justClickedOnSuggestion = false;
	        });
	      };
	      var itemProps = function itemProps(_ref2) {
	        var sectionIndex = _ref2.sectionIndex;
	        var itemIndex = _ref2.itemIndex;

	        return {
	          'data-section-index': sectionIndex,
	          'data-suggestion-index': itemIndex,
	          onMouseEnter: onMouseEnter,
	          onMouseLeave: onMouseLeave,
	          onMouseDown: onMouseDown,
	          onTouchStart: onMouseDown, // Because on iOS `onMouseDown` is not triggered
	          onClick: onClick
	        };
	      };
	      var renderItem = function renderItem(item) {
	        return renderSuggestion(item, { value: value, valueBeforeUpDown: valueBeforeUpDown });
	      };

	      return _react2.default.createElement(_reactAutowhatever2.default, { multiSection: multiSection,
	        items: items,
	        renderItem: renderItem,
	        renderSectionTitle: renderSectionTitle,
	        getSectionItems: getSectionSuggestions,
	        focusedSectionIndex: focusedSectionIndex,
	        focusedItemIndex: focusedSuggestionIndex,
	        inputProps: autowhateverInputProps,
	        itemProps: itemProps,
	        theme: theme,
	        id: id,
	        ref: this.saveInput });
	    }
	  }]);

	  return Autosuggest;
	}(_react.Component);

	Autosuggest.propTypes = {
	  suggestions: _react.PropTypes.array.isRequired,
	  onSuggestionsUpdateRequested: _react.PropTypes.func.isRequired,
	  getSuggestionValue: _react.PropTypes.func.isRequired,
	  renderSuggestion: _react.PropTypes.func.isRequired,
	  inputProps: _react.PropTypes.object.isRequired,
	  shouldRenderSuggestions: _react.PropTypes.func.isRequired,
	  onSuggestionSelected: _react.PropTypes.func.isRequired,
	  multiSection: _react.PropTypes.bool.isRequired,
	  renderSectionTitle: _react.PropTypes.func.isRequired,
	  getSectionSuggestions: _react.PropTypes.func.isRequired,
	  focusInputOnSuggestionClick: _react.PropTypes.bool.isRequired,
	  theme: _react.PropTypes.object.isRequired,
	  id: _react.PropTypes.string.isRequired,
	  inputRef: _react.PropTypes.func.isRequired,

	  isFocused: _react.PropTypes.bool.isRequired,
	  isCollapsed: _react.PropTypes.bool.isRequired,
	  focusedSectionIndex: _react.PropTypes.number,
	  focusedSuggestionIndex: _react.PropTypes.number,
	  valueBeforeUpDown: _react.PropTypes.string,
	  lastAction: _react.PropTypes.string,

	  inputFocused: _react.PropTypes.func.isRequired,
	  inputBlurred: _react.PropTypes.func.isRequired,
	  inputChanged: _react.PropTypes.func.isRequired,
	  updateFocusedSuggestion: _react.PropTypes.func.isRequired,
	  revealSuggestions: _react.PropTypes.func.isRequired,
	  closeSuggestions: _react.PropTypes.func.isRequired
	};
	exports.default = (0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(Autosuggest);

/***/ },

/***/ 190:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	exports.__esModule = true;
	exports.connect = exports.Provider = undefined;

	var _Provider = __webpack_require__(191);

	var _Provider2 = _interopRequireDefault(_Provider);

	var _connect = __webpack_require__(194);

	var _connect2 = _interopRequireDefault(_connect);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

	exports.Provider = _Provider2["default"];
	exports.connect = _connect2["default"];

/***/ },

/***/ 191:
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {'use strict';

	exports.__esModule = true;
	exports["default"] = undefined;

	var _react = __webpack_require__(1);

	var _storeShape = __webpack_require__(192);

	var _storeShape2 = _interopRequireDefault(_storeShape);

	var _warning = __webpack_require__(193);

	var _warning2 = _interopRequireDefault(_warning);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var didWarnAboutReceivingStore = false;
	function warnAboutReceivingStore() {
	  if (didWarnAboutReceivingStore) {
	    return;
	  }
	  didWarnAboutReceivingStore = true;

	  (0, _warning2["default"])('<Provider> does not support changing `store` on the fly. ' + 'It is most likely that you see this error because you updated to ' + 'Redux 2.x and React Redux 2.x which no longer hot reload reducers ' + 'automatically. See https://github.com/reactjs/react-redux/releases/' + 'tag/v2.0.0 for the migration instructions.');
	}

	var Provider = function (_Component) {
	  _inherits(Provider, _Component);

	  Provider.prototype.getChildContext = function getChildContext() {
	    return { store: this.store };
	  };

	  function Provider(props, context) {
	    _classCallCheck(this, Provider);

	    var _this = _possibleConstructorReturn(this, _Component.call(this, props, context));

	    _this.store = props.store;
	    return _this;
	  }

	  Provider.prototype.render = function render() {
	    var children = this.props.children;

	    return _react.Children.only(children);
	  };

	  return Provider;
	}(_react.Component);

	exports["default"] = Provider;

	if (process.env.NODE_ENV !== 'production') {
	  Provider.prototype.componentWillReceiveProps = function (nextProps) {
	    var store = this.store;
	    var nextStore = nextProps.store;

	    if (store !== nextStore) {
	      warnAboutReceivingStore();
	    }
	  };
	}

	Provider.propTypes = {
	  store: _storeShape2["default"].isRequired,
	  children: _react.PropTypes.element.isRequired
	};
	Provider.childContextTypes = {
	  store: _storeShape2["default"].isRequired
	};
	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(3)))

/***/ },

/***/ 192:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	exports.__esModule = true;

	var _react = __webpack_require__(1);

	exports["default"] = _react.PropTypes.shape({
	  subscribe: _react.PropTypes.func.isRequired,
	  dispatch: _react.PropTypes.func.isRequired,
	  getState: _react.PropTypes.func.isRequired
	});

/***/ },

/***/ 193:
/***/ function(module, exports) {

	'use strict';

	exports.__esModule = true;
	exports["default"] = warning;
	/**
	 * Prints a warning in the console if it exists.
	 *
	 * @param {String} message The warning message.
	 * @returns {void}
	 */
	function warning(message) {
	  /* eslint-disable no-console */
	  if (typeof console !== 'undefined' && typeof console.error === 'function') {
	    console.error(message);
	  }
	  /* eslint-enable no-console */
	  try {
	    // This error was thrown as a convenience so that you can use this stack
	    // to find the callsite that caused this warning to fire.
	    throw new Error(message);
	    /* eslint-disable no-empty */
	  } catch (e) {}
	  /* eslint-enable no-empty */
	}

/***/ },

/***/ 194:
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {'use strict';

	var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

	exports.__esModule = true;
	exports["default"] = connect;

	var _react = __webpack_require__(1);

	var _storeShape = __webpack_require__(192);

	var _storeShape2 = _interopRequireDefault(_storeShape);

	var _shallowEqual = __webpack_require__(195);

	var _shallowEqual2 = _interopRequireDefault(_shallowEqual);

	var _wrapActionCreators = __webpack_require__(196);

	var _wrapActionCreators2 = _interopRequireDefault(_wrapActionCreators);

	var _warning = __webpack_require__(193);

	var _warning2 = _interopRequireDefault(_warning);

	var _isPlainObject = __webpack_require__(197);

	var _isPlainObject2 = _interopRequireDefault(_isPlainObject);

	var _hoistNonReactStatics = __webpack_require__(201);

	var _hoistNonReactStatics2 = _interopRequireDefault(_hoistNonReactStatics);

	var _invariant = __webpack_require__(202);

	var _invariant2 = _interopRequireDefault(_invariant);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var defaultMapStateToProps = function defaultMapStateToProps(state) {
	  return {};
	}; // eslint-disable-line no-unused-vars
	var defaultMapDispatchToProps = function defaultMapDispatchToProps(dispatch) {
	  return { dispatch: dispatch };
	};
	var defaultMergeProps = function defaultMergeProps(stateProps, dispatchProps, parentProps) {
	  return _extends({}, parentProps, stateProps, dispatchProps);
	};

	function getDisplayName(WrappedComponent) {
	  return WrappedComponent.displayName || WrappedComponent.name || 'Component';
	}

	var errorObject = { value: null };
	function tryCatch(fn, ctx) {
	  try {
	    return fn.apply(ctx);
	  } catch (e) {
	    errorObject.value = e;
	    return errorObject;
	  }
	}

	// Helps track hot reloading.
	var nextVersion = 0;

	function connect(mapStateToProps, mapDispatchToProps, mergeProps) {
	  var options = arguments.length <= 3 || arguments[3] === undefined ? {} : arguments[3];

	  var shouldSubscribe = Boolean(mapStateToProps);
	  var mapState = mapStateToProps || defaultMapStateToProps;

	  var mapDispatch = undefined;
	  if (typeof mapDispatchToProps === 'function') {
	    mapDispatch = mapDispatchToProps;
	  } else if (!mapDispatchToProps) {
	    mapDispatch = defaultMapDispatchToProps;
	  } else {
	    mapDispatch = (0, _wrapActionCreators2["default"])(mapDispatchToProps);
	  }

	  var finalMergeProps = mergeProps || defaultMergeProps;
	  var _options$pure = options.pure;
	  var pure = _options$pure === undefined ? true : _options$pure;
	  var _options$withRef = options.withRef;
	  var withRef = _options$withRef === undefined ? false : _options$withRef;

	  var checkMergedEquals = pure && finalMergeProps !== defaultMergeProps;

	  // Helps track hot reloading.
	  var version = nextVersion++;

	  return function wrapWithConnect(WrappedComponent) {
	    var connectDisplayName = 'Connect(' + getDisplayName(WrappedComponent) + ')';

	    function checkStateShape(props, methodName) {
	      if (!(0, _isPlainObject2["default"])(props)) {
	        (0, _warning2["default"])(methodName + '() in ' + connectDisplayName + ' must return a plain object. ' + ('Instead received ' + props + '.'));
	      }
	    }

	    function computeMergedProps(stateProps, dispatchProps, parentProps) {
	      var mergedProps = finalMergeProps(stateProps, dispatchProps, parentProps);
	      if (process.env.NODE_ENV !== 'production') {
	        checkStateShape(mergedProps, 'mergeProps');
	      }
	      return mergedProps;
	    }

	    var Connect = function (_Component) {
	      _inherits(Connect, _Component);

	      Connect.prototype.shouldComponentUpdate = function shouldComponentUpdate() {
	        return !pure || this.haveOwnPropsChanged || this.hasStoreStateChanged;
	      };

	      function Connect(props, context) {
	        _classCallCheck(this, Connect);

	        var _this = _possibleConstructorReturn(this, _Component.call(this, props, context));

	        _this.version = version;
	        _this.store = props.store || context.store;

	        (0, _invariant2["default"])(_this.store, 'Could not find "store" in either the context or ' + ('props of "' + connectDisplayName + '". ') + 'Either wrap the root component in a <Provider>, ' + ('or explicitly pass "store" as a prop to "' + connectDisplayName + '".'));

	        var storeState = _this.store.getState();
	        _this.state = { storeState: storeState };
	        _this.clearCache();
	        return _this;
	      }

	      Connect.prototype.computeStateProps = function computeStateProps(store, props) {
	        if (!this.finalMapStateToProps) {
	          return this.configureFinalMapState(store, props);
	        }

	        var state = store.getState();
	        var stateProps = this.doStatePropsDependOnOwnProps ? this.finalMapStateToProps(state, props) : this.finalMapStateToProps(state);

	        if (process.env.NODE_ENV !== 'production') {
	          checkStateShape(stateProps, 'mapStateToProps');
	        }
	        return stateProps;
	      };

	      Connect.prototype.configureFinalMapState = function configureFinalMapState(store, props) {
	        var mappedState = mapState(store.getState(), props);
	        var isFactory = typeof mappedState === 'function';

	        this.finalMapStateToProps = isFactory ? mappedState : mapState;
	        this.doStatePropsDependOnOwnProps = this.finalMapStateToProps.length !== 1;

	        if (isFactory) {
	          return this.computeStateProps(store, props);
	        }

	        if (process.env.NODE_ENV !== 'production') {
	          checkStateShape(mappedState, 'mapStateToProps');
	        }
	        return mappedState;
	      };

	      Connect.prototype.computeDispatchProps = function computeDispatchProps(store, props) {
	        if (!this.finalMapDispatchToProps) {
	          return this.configureFinalMapDispatch(store, props);
	        }

	        var dispatch = store.dispatch;

	        var dispatchProps = this.doDispatchPropsDependOnOwnProps ? this.finalMapDispatchToProps(dispatch, props) : this.finalMapDispatchToProps(dispatch);

	        if (process.env.NODE_ENV !== 'production') {
	          checkStateShape(dispatchProps, 'mapDispatchToProps');
	        }
	        return dispatchProps;
	      };

	      Connect.prototype.configureFinalMapDispatch = function configureFinalMapDispatch(store, props) {
	        var mappedDispatch = mapDispatch(store.dispatch, props);
	        var isFactory = typeof mappedDispatch === 'function';

	        this.finalMapDispatchToProps = isFactory ? mappedDispatch : mapDispatch;
	        this.doDispatchPropsDependOnOwnProps = this.finalMapDispatchToProps.length !== 1;

	        if (isFactory) {
	          return this.computeDispatchProps(store, props);
	        }

	        if (process.env.NODE_ENV !== 'production') {
	          checkStateShape(mappedDispatch, 'mapDispatchToProps');
	        }
	        return mappedDispatch;
	      };

	      Connect.prototype.updateStatePropsIfNeeded = function updateStatePropsIfNeeded() {
	        var nextStateProps = this.computeStateProps(this.store, this.props);
	        if (this.stateProps && (0, _shallowEqual2["default"])(nextStateProps, this.stateProps)) {
	          return false;
	        }

	        this.stateProps = nextStateProps;
	        return true;
	      };

	      Connect.prototype.updateDispatchPropsIfNeeded = function updateDispatchPropsIfNeeded() {
	        var nextDispatchProps = this.computeDispatchProps(this.store, this.props);
	        if (this.dispatchProps && (0, _shallowEqual2["default"])(nextDispatchProps, this.dispatchProps)) {
	          return false;
	        }

	        this.dispatchProps = nextDispatchProps;
	        return true;
	      };

	      Connect.prototype.updateMergedPropsIfNeeded = function updateMergedPropsIfNeeded() {
	        var nextMergedProps = computeMergedProps(this.stateProps, this.dispatchProps, this.props);
	        if (this.mergedProps && checkMergedEquals && (0, _shallowEqual2["default"])(nextMergedProps, this.mergedProps)) {
	          return false;
	        }

	        this.mergedProps = nextMergedProps;
	        return true;
	      };

	      Connect.prototype.isSubscribed = function isSubscribed() {
	        return typeof this.unsubscribe === 'function';
	      };

	      Connect.prototype.trySubscribe = function trySubscribe() {
	        if (shouldSubscribe && !this.unsubscribe) {
	          this.unsubscribe = this.store.subscribe(this.handleChange.bind(this));
	          this.handleChange();
	        }
	      };

	      Connect.prototype.tryUnsubscribe = function tryUnsubscribe() {
	        if (this.unsubscribe) {
	          this.unsubscribe();
	          this.unsubscribe = null;
	        }
	      };

	      Connect.prototype.componentDidMount = function componentDidMount() {
	        this.trySubscribe();
	      };

	      Connect.prototype.componentWillReceiveProps = function componentWillReceiveProps(nextProps) {
	        if (!pure || !(0, _shallowEqual2["default"])(nextProps, this.props)) {
	          this.haveOwnPropsChanged = true;
	        }
	      };

	      Connect.prototype.componentWillUnmount = function componentWillUnmount() {
	        this.tryUnsubscribe();
	        this.clearCache();
	      };

	      Connect.prototype.clearCache = function clearCache() {
	        this.dispatchProps = null;
	        this.stateProps = null;
	        this.mergedProps = null;
	        this.haveOwnPropsChanged = true;
	        this.hasStoreStateChanged = true;
	        this.haveStatePropsBeenPrecalculated = false;
	        this.statePropsPrecalculationError = null;
	        this.renderedElement = null;
	        this.finalMapDispatchToProps = null;
	        this.finalMapStateToProps = null;
	      };

	      Connect.prototype.handleChange = function handleChange() {
	        if (!this.unsubscribe) {
	          return;
	        }

	        var storeState = this.store.getState();
	        var prevStoreState = this.state.storeState;
	        if (pure && prevStoreState === storeState) {
	          return;
	        }

	        if (pure && !this.doStatePropsDependOnOwnProps) {
	          var haveStatePropsChanged = tryCatch(this.updateStatePropsIfNeeded, this);
	          if (!haveStatePropsChanged) {
	            return;
	          }
	          if (haveStatePropsChanged === errorObject) {
	            this.statePropsPrecalculationError = errorObject.value;
	          }
	          this.haveStatePropsBeenPrecalculated = true;
	        }

	        this.hasStoreStateChanged = true;
	        this.setState({ storeState: storeState });
	      };

	      Connect.prototype.getWrappedInstance = function getWrappedInstance() {
	        (0, _invariant2["default"])(withRef, 'To access the wrapped instance, you need to specify ' + '{ withRef: true } as the fourth argument of the connect() call.');

	        return this.refs.wrappedInstance;
	      };

	      Connect.prototype.render = function render() {
	        var haveOwnPropsChanged = this.haveOwnPropsChanged;
	        var hasStoreStateChanged = this.hasStoreStateChanged;
	        var haveStatePropsBeenPrecalculated = this.haveStatePropsBeenPrecalculated;
	        var statePropsPrecalculationError = this.statePropsPrecalculationError;
	        var renderedElement = this.renderedElement;

	        this.haveOwnPropsChanged = false;
	        this.hasStoreStateChanged = false;
	        this.haveStatePropsBeenPrecalculated = false;
	        this.statePropsPrecalculationError = null;

	        if (statePropsPrecalculationError) {
	          throw statePropsPrecalculationError;
	        }

	        var shouldUpdateStateProps = true;
	        var shouldUpdateDispatchProps = true;
	        if (pure && renderedElement) {
	          shouldUpdateStateProps = hasStoreStateChanged || haveOwnPropsChanged && this.doStatePropsDependOnOwnProps;
	          shouldUpdateDispatchProps = haveOwnPropsChanged && this.doDispatchPropsDependOnOwnProps;
	        }

	        var haveStatePropsChanged = false;
	        var haveDispatchPropsChanged = false;
	        if (haveStatePropsBeenPrecalculated) {
	          haveStatePropsChanged = true;
	        } else if (shouldUpdateStateProps) {
	          haveStatePropsChanged = this.updateStatePropsIfNeeded();
	        }
	        if (shouldUpdateDispatchProps) {
	          haveDispatchPropsChanged = this.updateDispatchPropsIfNeeded();
	        }

	        var haveMergedPropsChanged = true;
	        if (haveStatePropsChanged || haveDispatchPropsChanged || haveOwnPropsChanged) {
	          haveMergedPropsChanged = this.updateMergedPropsIfNeeded();
	        } else {
	          haveMergedPropsChanged = false;
	        }

	        if (!haveMergedPropsChanged && renderedElement) {
	          return renderedElement;
	        }

	        if (withRef) {
	          this.renderedElement = (0, _react.createElement)(WrappedComponent, _extends({}, this.mergedProps, {
	            ref: 'wrappedInstance'
	          }));
	        } else {
	          this.renderedElement = (0, _react.createElement)(WrappedComponent, this.mergedProps);
	        }

	        return this.renderedElement;
	      };

	      return Connect;
	    }(_react.Component);

	    Connect.displayName = connectDisplayName;
	    Connect.WrappedComponent = WrappedComponent;
	    Connect.contextTypes = {
	      store: _storeShape2["default"]
	    };
	    Connect.propTypes = {
	      store: _storeShape2["default"]
	    };

	    if (process.env.NODE_ENV !== 'production') {
	      Connect.prototype.componentWillUpdate = function componentWillUpdate() {
	        if (this.version === version) {
	          return;
	        }

	        // We are hot reloading!
	        this.version = version;
	        this.trySubscribe();
	        this.clearCache();
	      };
	    }

	    return (0, _hoistNonReactStatics2["default"])(Connect, WrappedComponent);
	  };
	}
	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(3)))

/***/ },

/***/ 195:
/***/ function(module, exports) {

	"use strict";

	exports.__esModule = true;
	exports["default"] = shallowEqual;
	function shallowEqual(objA, objB) {
	  if (objA === objB) {
	    return true;
	  }

	  var keysA = Object.keys(objA);
	  var keysB = Object.keys(objB);

	  if (keysA.length !== keysB.length) {
	    return false;
	  }

	  // Test for A's keys different from B.
	  var hasOwn = Object.prototype.hasOwnProperty;
	  for (var i = 0; i < keysA.length; i++) {
	    if (!hasOwn.call(objB, keysA[i]) || objA[keysA[i]] !== objB[keysA[i]]) {
	      return false;
	    }
	  }

	  return true;
	}

/***/ },

/***/ 196:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	exports.__esModule = true;
	exports["default"] = wrapActionCreators;

	var _redux = __webpack_require__(175);

	function wrapActionCreators(actionCreators) {
	  return function (dispatch) {
	    return (0, _redux.bindActionCreators)(actionCreators, dispatch);
	  };
	}

/***/ },

/***/ 197:
/***/ function(module, exports, __webpack_require__) {

	var getPrototype = __webpack_require__(198),
	    isHostObject = __webpack_require__(199),
	    isObjectLike = __webpack_require__(200);

	/** `Object#toString` result references. */
	var objectTag = '[object Object]';

	/** Used for built-in method references. */
	var objectProto = Object.prototype;

	/** Used to resolve the decompiled source of functions. */
	var funcToString = Function.prototype.toString;

	/** Used to check objects for own properties. */
	var hasOwnProperty = objectProto.hasOwnProperty;

	/** Used to infer the `Object` constructor. */
	var objectCtorString = funcToString.call(Object);

	/**
	 * Used to resolve the
	 * [`toStringTag`](http://ecma-international.org/ecma-262/6.0/#sec-object.prototype.tostring)
	 * of values.
	 */
	var objectToString = objectProto.toString;

	/**
	 * Checks if `value` is a plain object, that is, an object created by the
	 * `Object` constructor or one with a `[[Prototype]]` of `null`.
	 *
	 * @static
	 * @memberOf _
	 * @since 0.8.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a plain object,
	 *  else `false`.
	 * @example
	 *
	 * function Foo() {
	 *   this.a = 1;
	 * }
	 *
	 * _.isPlainObject(new Foo);
	 * // => false
	 *
	 * _.isPlainObject([1, 2, 3]);
	 * // => false
	 *
	 * _.isPlainObject({ 'x': 0, 'y': 0 });
	 * // => true
	 *
	 * _.isPlainObject(Object.create(null));
	 * // => true
	 */
	function isPlainObject(value) {
	  if (!isObjectLike(value) ||
	      objectToString.call(value) != objectTag || isHostObject(value)) {
	    return false;
	  }
	  var proto = getPrototype(value);
	  if (proto === null) {
	    return true;
	  }
	  var Ctor = hasOwnProperty.call(proto, 'constructor') && proto.constructor;
	  return (typeof Ctor == 'function' &&
	    Ctor instanceof Ctor && funcToString.call(Ctor) == objectCtorString);
	}

	module.exports = isPlainObject;


/***/ },

/***/ 198:
/***/ function(module, exports) {

	/* Built-in method references for those with the same name as other `lodash` methods. */
	var nativeGetPrototype = Object.getPrototypeOf;

	/**
	 * Gets the `[[Prototype]]` of `value`.
	 *
	 * @private
	 * @param {*} value The value to query.
	 * @returns {null|Object} Returns the `[[Prototype]]`.
	 */
	function getPrototype(value) {
	  return nativeGetPrototype(Object(value));
	}

	module.exports = getPrototype;


/***/ },

/***/ 199:
/***/ function(module, exports) {

	/**
	 * Checks if `value` is a host object in IE < 9.
	 *
	 * @private
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a host object, else `false`.
	 */
	function isHostObject(value) {
	  // Many host objects are `Object` objects that can coerce to strings
	  // despite having improperly defined `toString` methods.
	  var result = false;
	  if (value != null && typeof value.toString != 'function') {
	    try {
	      result = !!(value + '');
	    } catch (e) {}
	  }
	  return result;
	}

	module.exports = isHostObject;


/***/ },

/***/ 200:
/***/ function(module, exports) {

	/**
	 * Checks if `value` is object-like. A value is object-like if it's not `null`
	 * and has a `typeof` result of "object".
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is object-like, else `false`.
	 * @example
	 *
	 * _.isObjectLike({});
	 * // => true
	 *
	 * _.isObjectLike([1, 2, 3]);
	 * // => true
	 *
	 * _.isObjectLike(_.noop);
	 * // => false
	 *
	 * _.isObjectLike(null);
	 * // => false
	 */
	function isObjectLike(value) {
	  return !!value && typeof value == 'object';
	}

	module.exports = isObjectLike;


/***/ },

/***/ 201:
/***/ function(module, exports) {

	/**
	 * Copyright 2015, Yahoo! Inc.
	 * Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
	 */
	'use strict';

	var REACT_STATICS = {
	    childContextTypes: true,
	    contextTypes: true,
	    defaultProps: true,
	    displayName: true,
	    getDefaultProps: true,
	    mixins: true,
	    propTypes: true,
	    type: true
	};

	var KNOWN_STATICS = {
	    name: true,
	    length: true,
	    prototype: true,
	    caller: true,
	    arguments: true,
	    arity: true
	};

	module.exports = function hoistNonReactStatics(targetComponent, sourceComponent, customStatics) {
	    if (typeof sourceComponent !== 'string') { // don't hoist over string (html) components
	        var keys = Object.getOwnPropertyNames(sourceComponent);
	        for (var i = 0; i < keys.length; ++i) {
	            if (!REACT_STATICS[keys[i]] && !KNOWN_STATICS[keys[i]] && (!customStatics || !customStatics[keys[i]])) {
	                try {
	                    targetComponent[keys[i]] = sourceComponent[keys[i]];
	                } catch (error) {

	                }
	            }
	        }
	    }

	    return targetComponent;
	};


/***/ },

/***/ 202:
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {/**
	 * Copyright 2013-2015, Facebook, Inc.
	 * All rights reserved.
	 *
	 * This source code is licensed under the BSD-style license found in the
	 * LICENSE file in the root directory of this source tree. An additional grant
	 * of patent rights can be found in the PATENTS file in the same directory.
	 */

	'use strict';

	/**
	 * Use invariant() to assert state which your program assumes to be true.
	 *
	 * Provide sprintf-style format (only %s is supported) and arguments
	 * to provide information about what broke and what you were
	 * expecting.
	 *
	 * The invariant message will be stripped in production, but the invariant
	 * will remain to ensure logic does not differ in production.
	 */

	var invariant = function(condition, format, a, b, c, d, e, f) {
	  if (process.env.NODE_ENV !== 'production') {
	    if (format === undefined) {
	      throw new Error('invariant requires an error message argument');
	    }
	  }

	  if (!condition) {
	    var error;
	    if (format === undefined) {
	      error = new Error(
	        'Minified exception occurred; use the non-minified dev environment ' +
	        'for the full error message and additional helpful warnings.'
	      );
	    } else {
	      var args = [a, b, c, d, e, f];
	      var argIndex = 0;
	      error = new Error(
	        format.replace(/%s/g, function() { return args[argIndex++]; })
	      );
	      error.name = 'Invariant Violation';
	    }

	    error.framesToPop = 1; // we don't care about invariant's own frame
	    throw error;
	  }
	};

	module.exports = invariant;

	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(3)))

/***/ },

/***/ 203:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
	  value: true
	});

	var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

	var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _sectionIterator = __webpack_require__(204);

	var _sectionIterator2 = _interopRequireDefault(_sectionIterator);

	var _reactThemeable = __webpack_require__(205);

	var _reactThemeable2 = _interopRequireDefault(_reactThemeable);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	function noop() {}

	var Autowhatever = function (_Component) {
	  _inherits(Autowhatever, _Component);

	  function Autowhatever(props) {
	    _classCallCheck(this, Autowhatever);

	    var _this = _possibleConstructorReturn(this, Object.getPrototypeOf(Autowhatever).call(this, props));

	    _this.onKeyDown = _this.onKeyDown.bind(_this);
	    return _this;
	  } // Styles. See: https://github.com/markdalgleish/react-themeable


	  _createClass(Autowhatever, [{
	    key: 'componentDidMount',
	    value: function componentDidMount() {
	      this.ensureFocusedSuggestionIsVisible();
	    }
	  }, {
	    key: 'componentDidUpdate',
	    value: function componentDidUpdate() {
	      this.ensureFocusedSuggestionIsVisible();
	    }
	  }, {
	    key: 'getItemId',
	    value: function getItemId(sectionIndex, itemIndex) {
	      if (itemIndex === null) {
	        return null;
	      }

	      var id = this.props.id;

	      var section = sectionIndex === null ? '' : 'section-' + sectionIndex;

	      return 'react-autowhatever-' + id + '-' + section + '-item-' + itemIndex;
	    }
	  }, {
	    key: 'getItemsContainerId',
	    value: function getItemsContainerId() {
	      var id = this.props.id;


	      return 'react-whatever-' + id;
	    }
	  }, {
	    key: 'renderItemsList',
	    value: function renderItemsList(theme, items, sectionIndex) {
	      var _this2 = this;

	      var _props = this.props;
	      var id = _props.id;
	      var renderItem = _props.renderItem;
	      var focusedSectionIndex = _props.focusedSectionIndex;
	      var focusedItemIndex = _props.focusedItemIndex;

	      var isItemPropsFunction = typeof this.props.itemProps === 'function';

	      return items.map(function (item, itemIndex) {
	        var itemPropsObj = isItemPropsFunction ? _this2.props.itemProps({ sectionIndex: sectionIndex, itemIndex: itemIndex }) : _this2.props.itemProps;
	        var onMouseEnter = itemPropsObj.onMouseEnter;
	        var onMouseLeave = itemPropsObj.onMouseLeave;
	        var onMouseDown = itemPropsObj.onMouseDown;
	        var onClick = itemPropsObj.onClick;


	        var onMouseEnterFn = onMouseEnter ? function (event) {
	          return onMouseEnter(event, { sectionIndex: sectionIndex, itemIndex: itemIndex });
	        } : noop;
	        var onMouseLeaveFn = onMouseLeave ? function (event) {
	          return onMouseLeave(event, { sectionIndex: sectionIndex, itemIndex: itemIndex });
	        } : noop;
	        var onMouseDownFn = onMouseDown ? function (event) {
	          return onMouseDown(event, { sectionIndex: sectionIndex, itemIndex: itemIndex });
	        } : noop;
	        var onClickFn = onClick ? function (event) {
	          return onClick(event, { sectionIndex: sectionIndex, itemIndex: itemIndex });
	        } : noop;
	        var sectionPrefix = sectionIndex === null ? '' : 'section-' + sectionIndex + '-';
	        var itemKey = 'react-autowhatever-' + id + '-' + sectionPrefix + 'item-' + itemIndex;
	        var isFocused = sectionIndex === focusedSectionIndex && itemIndex === focusedItemIndex;
	        var itemProps = _extends({
	          id: _this2.getItemId(sectionIndex, itemIndex),
	          ref: isFocused ? 'focusedItem' : null,
	          role: 'option'
	        }, theme(itemKey, 'item', isFocused && 'itemFocused'), itemPropsObj, {
	          onMouseEnter: onMouseEnterFn,
	          onMouseLeave: onMouseLeaveFn,
	          onMouseDown: onMouseDownFn,
	          onClick: onClickFn
	        });

	        return _react2.default.createElement(
	          'li',
	          itemProps,
	          renderItem(item)
	        );
	      });
	    }
	  }, {
	    key: 'renderSections',
	    value: function renderSections(theme) {
	      var _this3 = this;

	      var _props2 = this.props;
	      var items = _props2.items;
	      var getSectionItems = _props2.getSectionItems;

	      var sectionItemsArray = items.map(function (section) {
	        return getSectionItems(section);
	      });
	      var noItemsExist = sectionItemsArray.every(function (sectionItems) {
	        return sectionItems.length === 0;
	      });

	      if (noItemsExist) {
	        return null;
	      }

	      var _props3 = this.props;
	      var id = _props3.id;
	      var shouldRenderSection = _props3.shouldRenderSection;
	      var renderSectionTitle = _props3.renderSectionTitle;


	      return _react2.default.createElement(
	        'div',
	        _extends({ id: this.getItemsContainerId(),
	          ref: 'itemsContainer',
	          role: 'listbox'
	        }, theme('react-autowhatever-' + id + '-items-container', 'itemsContainer')),
	        items.map(function (section, sectionIndex) {
	          if (!shouldRenderSection(section)) {
	            return null;
	          }

	          var sectionTitle = renderSectionTitle(section);

	          return _react2.default.createElement(
	            'div',
	            theme('react-autowhatever-' + id + '-section-' + sectionIndex + '-container', 'sectionContainer'),
	            sectionTitle && _react2.default.createElement(
	              'div',
	              theme('react-autowhatever-' + id + '-section-' + sectionIndex + '-title', 'sectionTitle'),
	              sectionTitle
	            ),
	            _react2.default.createElement(
	              'ul',
	              theme('react-autowhatever-' + id + '-section-' + sectionIndex + '-items-container', 'sectionItemsContainer'),
	              _this3.renderItemsList(theme, sectionItemsArray[sectionIndex], sectionIndex)
	            )
	          );
	        })
	      );
	    }
	  }, {
	    key: 'renderItems',
	    value: function renderItems(theme) {
	      var items = this.props.items;


	      if (items.length === 0) {
	        return null;
	      }

	      var id = this.props;

	      return _react2.default.createElement(
	        'ul',
	        _extends({ id: this.getItemsContainerId(),
	          ref: 'itemsContainer',
	          role: 'listbox'
	        }, theme('react-autowhatever-' + id + '-items-container', 'itemsContainer')),
	        this.renderItemsList(theme, items, null)
	      );
	    }
	  }, {
	    key: 'onKeyDown',
	    value: function onKeyDown(event) {
	      var _this4 = this;

	      var _props4 = this.props;
	      var inputProps = _props4.inputProps;
	      var focusedSectionIndex = _props4.focusedSectionIndex;
	      var focusedItemIndex = _props4.focusedItemIndex;
	      var onKeyDownFn = inputProps.onKeyDown; // Babel is throwing:
	      //   "onKeyDown" is read-only
	      // on:
	      //   const { onKeyDown } = inputProps;

	      switch (event.key) {
	        case 'ArrowDown':
	        case 'ArrowUp':
	          {
	            var _ret = function () {
	              var _props5 = _this4.props;
	              var multiSection = _props5.multiSection;
	              var items = _props5.items;
	              var getSectionItems = _props5.getSectionItems;

	              var sectionIterator = (0, _sectionIterator2.default)({
	                multiSection: multiSection,
	                data: multiSection ? items.map(function (section) {
	                  return getSectionItems(section).length;
	                }) : items.length
	              });
	              var nextPrev = event.key === 'ArrowDown' ? 'next' : 'prev';

	              var _sectionIterator$next = sectionIterator[nextPrev]([focusedSectionIndex, focusedItemIndex]);

	              var _sectionIterator$next2 = _slicedToArray(_sectionIterator$next, 2);

	              var newFocusedSectionIndex = _sectionIterator$next2[0];
	              var newFocusedItemIndex = _sectionIterator$next2[1];


	              onKeyDownFn(event, { newFocusedSectionIndex: newFocusedSectionIndex, newFocusedItemIndex: newFocusedItemIndex });
	              return 'break';
	            }();

	            if (_ret === 'break') break;
	          }

	        default:
	          onKeyDownFn(event, { focusedSectionIndex: focusedSectionIndex, focusedItemIndex: focusedItemIndex });
	      }
	    }
	  }, {
	    key: 'ensureFocusedSuggestionIsVisible',
	    value: function ensureFocusedSuggestionIsVisible() {
	      if (!this.refs.focusedItem) {
	        return;
	      }

	      var _refs = this.refs;
	      var focusedItem = _refs.focusedItem;
	      var itemsContainer = _refs.itemsContainer;

	      var itemOffsetRelativeToContainer = focusedItem.offsetParent === itemsContainer ? focusedItem.offsetTop : focusedItem.offsetTop - itemsContainer.offsetTop;

	      var scrollTop = itemsContainer.scrollTop; // Top of the visible area

	      if (itemOffsetRelativeToContainer < scrollTop) {
	        // Item is off the top of the visible area
	        scrollTop = itemOffsetRelativeToContainer;
	      } else if (itemOffsetRelativeToContainer + focusedItem.offsetHeight > scrollTop + itemsContainer.offsetHeight) {
	        // Item is off the bottom of the visible area
	        scrollTop = itemOffsetRelativeToContainer + focusedItem.offsetHeight - itemsContainer.offsetHeight;
	      }

	      if (scrollTop !== itemsContainer.scrollTop) {
	        itemsContainer.scrollTop = scrollTop;
	      }
	    }
	  }, {
	    key: 'render',
	    value: function render() {
	      var _props6 = this.props;
	      var id = _props6.id;
	      var multiSection = _props6.multiSection;
	      var focusedSectionIndex = _props6.focusedSectionIndex;
	      var focusedItemIndex = _props6.focusedItemIndex;

	      var theme = (0, _reactThemeable2.default)(this.props.theme);
	      var renderedItems = multiSection ? this.renderSections(theme) : this.renderItems(theme);
	      var isOpen = renderedItems !== null;
	      var ariaActivedescendant = this.getItemId(focusedSectionIndex, focusedItemIndex);
	      var inputProps = _extends({
	        type: 'text',
	        value: '',
	        autoComplete: 'off',
	        role: 'combobox',
	        ref: 'input',
	        'aria-autocomplete': 'list',
	        'aria-owns': this.getItemsContainerId(),
	        'aria-expanded': isOpen,
	        'aria-activedescendant': ariaActivedescendant
	      }, theme('react-autowhatever-' + id + '-input', 'input'), this.props.inputProps, {
	        onKeyDown: this.props.inputProps.onKeyDown && this.onKeyDown
	      });

	      return _react2.default.createElement(
	        'div',
	        theme('react-autowhatever-' + id + '-container', 'container', isOpen && 'containerOpen'),
	        _react2.default.createElement('input', inputProps),
	        renderedItems
	      );
	    }
	  }]);

	  return Autowhatever;
	}(_react.Component);

	Autowhatever.propTypes = {
	  id: _react.PropTypes.string, // Used in aria-* attributes. If multiple Autowhatever's are rendered on a page, they must have unique ids.
	  multiSection: _react.PropTypes.bool, // Indicates whether a multi section layout should be rendered.
	  items: _react.PropTypes.array.isRequired, // Array of items or sections to render.
	  renderItem: _react.PropTypes.func, // This function renders a single item.
	  shouldRenderSection: _react.PropTypes.func, // This function gets a section and returns whether it should be rendered, or not.
	  renderSectionTitle: _react.PropTypes.func, // This function gets a section and renders its title.
	  getSectionItems: _react.PropTypes.func, // This function gets a section and returns its items, which will be passed into `renderItem` for rendering.
	  inputProps: _react.PropTypes.object, // Arbitrary input props
	  itemProps: _react.PropTypes.oneOfType([// Arbitrary item props
	  _react.PropTypes.object, _react.PropTypes.func]),
	  focusedSectionIndex: _react.PropTypes.number, // Section index of the focused item
	  focusedItemIndex: _react.PropTypes.number, // Focused item index (within a section)
	  theme: _react.PropTypes.object };
	Autowhatever.defaultProps = {
	  id: '1',
	  multiSection: false,
	  shouldRenderSection: function shouldRenderSection() {
	    return true;
	  },
	  renderItem: function renderItem() {
	    throw new Error('`renderItem` must be provided');
	  },
	  renderSectionTitle: function renderSectionTitle() {
	    throw new Error('`renderSectionTitle` must be provided');
	  },
	  getSectionItems: function getSectionItems() {
	    throw new Error('`getSectionItems` must be provided');
	  },
	  inputProps: {},
	  itemProps: {},
	  focusedSectionIndex: null,
	  focusedItemIndex: null,
	  theme: {
	    container: 'react-autowhatever__container',
	    containerOpen: 'react-autowhatever__container--open',
	    input: 'react-autowhatever__input',
	    itemsContainer: 'react-autowhatever__items-container',
	    item: 'react-autowhatever__item',
	    itemFocused: 'react-autowhatever__item--focused',
	    sectionContainer: 'react-autowhatever__section-container',
	    sectionTitle: 'react-autowhatever__section-title',
	    sectionItemsContainer: 'react-autowhatever__section-items-container'
	  }
	};
	exports.default = Autowhatever;


/***/ },

/***/ 204:
/***/ function(module, exports) {

	"use strict";

	var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

	module.exports = function (_ref) {
	  var data = _ref.data;
	  var multiSection = _ref.multiSection;

	  function nextNonEmptySectionIndex(sectionIndex) {
	    if (sectionIndex === null) {
	      sectionIndex = 0;
	    } else {
	      sectionIndex++;
	    }

	    while (sectionIndex < data.length && data[sectionIndex] === 0) {
	      sectionIndex++;
	    }

	    return sectionIndex === data.length ? null : sectionIndex;
	  }

	  function prevNonEmptySectionIndex(sectionIndex) {
	    if (sectionIndex === null) {
	      sectionIndex = data.length - 1;
	    } else {
	      sectionIndex--;
	    }

	    while (sectionIndex >= 0 && data[sectionIndex] === 0) {
	      sectionIndex--;
	    }

	    return sectionIndex === -1 ? null : sectionIndex;
	  }

	  function next(position) {
	    var _position = _slicedToArray(position, 2);

	    var sectionIndex = _position[0];
	    var itemIndex = _position[1];


	    if (multiSection) {
	      if (itemIndex === null || itemIndex === data[sectionIndex] - 1) {
	        sectionIndex = nextNonEmptySectionIndex(sectionIndex);

	        if (sectionIndex === null) {
	          return [null, null];
	        }

	        return [sectionIndex, 0];
	      }

	      return [sectionIndex, itemIndex + 1];
	    }

	    if (data === 0 || itemIndex === data - 1) {
	      return [null, null];
	    }

	    if (itemIndex === null) {
	      return [null, 0];
	    }

	    return [null, itemIndex + 1];
	  }

	  function prev(position) {
	    var _position2 = _slicedToArray(position, 2);

	    var sectionIndex = _position2[0];
	    var itemIndex = _position2[1];


	    if (multiSection) {
	      if (itemIndex === null || itemIndex === 0) {
	        sectionIndex = prevNonEmptySectionIndex(sectionIndex);

	        if (sectionIndex === null) {
	          return [null, null];
	        }

	        return [sectionIndex, data[sectionIndex] - 1];
	      }

	      return [sectionIndex, itemIndex - 1];
	    }

	    if (data === 0 || itemIndex === 0) {
	      return [null, null];
	    }

	    if (itemIndex === null) {
	      return [null, data - 1];
	    }

	    return [null, itemIndex - 1];
	  }

	  function isLast(position) {
	    return next(position)[1] === null;
	  }

	  return {
	    next: next,
	    prev: prev,
	    isLast: isLast
	  };
	};


/***/ },

/***/ 205:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, '__esModule', {
	  value: true
	});

	var _slicedToArray = (function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i['return']) _i['return'](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError('Invalid attempt to destructure non-iterable instance'); } }; })();

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

	function _toConsumableArray(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) arr2[i] = arr[i]; return arr2; } else { return Array.from(arr); } }

	var _objectAssign = __webpack_require__(206);

	var _objectAssign2 = _interopRequireDefault(_objectAssign);

	var truthy = function truthy(x) {
	  return x;
	};

	exports['default'] = function (input) {
	  var _ref = Array.isArray(input) && input.length === 2 ? input : [input, null];

	  var _ref2 = _slicedToArray(_ref, 2);

	  var theme = _ref2[0];
	  var classNameDecorator = _ref2[1];

	  return function (key) {
	    for (var _len = arguments.length, names = Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
	      names[_key - 1] = arguments[_key];
	    }

	    var styles = names.map(function (name) {
	      return theme[name];
	    }).filter(truthy);

	    return typeof styles[0] === 'string' || typeof classNameDecorator === 'function' ? { key: key, className: classNameDecorator ? classNameDecorator.apply(undefined, _toConsumableArray(styles)) : styles.join(' ') } : { key: key, style: _objectAssign2['default'].apply(undefined, [{}].concat(_toConsumableArray(styles))) };
	  };
	};

	module.exports = exports['default'];

/***/ },

/***/ 206:
/***/ function(module, exports) {

	'use strict';
	var propIsEnumerable = Object.prototype.propertyIsEnumerable;

	function ToObject(val) {
		if (val == null) {
			throw new TypeError('Object.assign cannot be called with null or undefined');
		}

		return Object(val);
	}

	function ownEnumerableKeys(obj) {
		var keys = Object.getOwnPropertyNames(obj);

		if (Object.getOwnPropertySymbols) {
			keys = keys.concat(Object.getOwnPropertySymbols(obj));
		}

		return keys.filter(function (key) {
			return propIsEnumerable.call(obj, key);
		});
	}

	module.exports = Object.assign || function (target, source) {
		var from;
		var keys;
		var to = ToObject(target);

		for (var s = 1; s < arguments.length; s++) {
			from = arguments[s];
			keys = ownEnumerableKeys(Object(from));

			for (var i = 0; i < keys.length; i++) {
				to[keys[i]] = from[keys[i]];
			}
		}

		return to;
	};


/***/ },

/***/ 207:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	Object.defineProperty(exports, "__esModule", {
		value: true
	});
	exports.Prompters = undefined;

	var _react = __webpack_require__(1);

	var _react2 = _interopRequireDefault(_react);

	var _reactDom = __webpack_require__(38);

	var _reactDom2 = _interopRequireDefault(_reactDom);

	var _common = __webpack_require__(171);

	var C = _interopRequireWildcard(_common);

	function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	/**
	 * Prompters is the object containing all the handlers that link the web
	 * application to the API. Every handler is an object containing one or more 
	 * functions and whathever things it needs in order to manage your suggestions. 
	 * There are few things to know:
	 *
	 * - All the components in form-utils.jsx use their name property to identify the
	 *   name of the handler that must be used. So make sure that handler exists (if not
	 *   just write a new one) and it has all the functions required by the component.
	 * 
	 * - Here is a list of the functions needed and the components that need them.
	 *
	 *	- function { components }
	 *
	 *	- init(callback) { all }
	 *		this function will be called once when the element
	 *		is about to be mounted. Use it to retrive the initial
	 *		data from the API and call the callback once you are done
	 *
	 *	- getSuggestions(value) {AutoInput}
	 *		this function take the actual value of the input and 
	 *		must return an array of strings (suggestions).
	 *		
	 * 	- getValues() {AJXdropdown, Adropdown, Table}
	 *		returns a list of all the possible values (ex. all the domains)
	 *		For a dropdown it must be a list of strings, for a table it must
	 *		return a list of objects where each object represent a row of that
	 *		table, according with the `model` property of the table.
	 *	- getEmptyRow() { Table }
	 *		when a table will create a new empty row, it will ask to this function
	 *		what should be the content of that new row
	 *
	 *	- save/update/delete(key, input) { Table }
	 *		this functions create the link with the API to perform the action
	 *		of saving/updating/deleting a given entity.
	 *		The entity is identified by the argument key (ex: iddhpprof)
	 *		and the data (if any) resides into the object input.
	 *
	 *		
	 */

	var Prompters = exports.Prompters = {

		/*************************  Handler name="cidr" ***********************/
		cidr: {
			/* Here will be stored all the network addresses */
			networks: [],

			/* Fill the networks array with the API answer */
			init: function init(callback) {
				C.getJSON(C.APIURL + '/networks', function (response) {
					var networks = [];
					for (var i = 0; i < response.length; i++) {
						networks.push(response[i]["addr4"]);
						networks.push(response[i]["addr6"]);
					}
					this.networks = networks;
				}.bind(this), callback);
			},

			/* Case-insensitive suggestions based on the 
	     beginning of the addresses*/
			getSuggestions: function getSuggestions(value, callback) {
				var inputValue = value.trim().toLowerCase();
				var inputLength = inputValue.length;

				if (inputLength === 0) return [];

				return this.networks.filter(function (network) {
					return network.toLowerCase().slice(0, inputLength) === inputValue;
				});
			},

			getValues: function getValues() {
				return this.networks;
			}
		},

		/*************************  Handler name="hinfos" ***********************/

		hinfos: {
			machines: [],

			/* Fill the machines array with the API answer */
			init: function init(callback) {
				C.getJSON(C.APIURL + '/hinfos', function (response) {
					this.machines = response.filter(function (e) {
						return e.present;
					}).map(function (e) {
						return e.name;
					});
				}.bind(this), callback);
			},

			/* Gives all the machines */
			getValues: function getValues() {
				return this.machines;
			}
		},

		/*************************  Handler name="domain" ***********************/

		domain: {
			domains: [], // [{iddom: .. name: ..} , ...]
			_domains: [], // [ "domain1", "domain2", ... ]

			init: function init(callback) {
				C.getJSON(C.APIURL + '/domains', function (response) {
					this.domains = response;
					response.forEach(function (val) {
						this._domains.push(val.name);
					}.bind(this));
				}.bind(this), callback);
			},

			getValues: function getValues() {
				return this._domains;
			},

			id2Name: function id2Name(id) {
				for (var i = 0; i < this.domains.length; i++) {
					if (this.domains[i].iddom == id) {
						return this.domains[i].name;
					}
				}
			},

			name2Id: function name2Id(name) {
				for (var i = 0; i < this.domains.length; i++) {
					if (this.domains[i].name == name) {
						return this.domains[i].iddom;
					}
				}
			}
		},

		/*************************  Handler name="addr" ***********************/

		addr: {
			addrs: [],

			makeIpv6: function makeIpv6(cidr) {
				return cidr + "#TODO";
			},

			makeIpv4: function makeIpv4(cidr) {
				var c_m = cidr.split("/");
				return C.add_to_IPv4(c_m[0], 1);
			},

			init: function init(callback) {
				Prompters.cidr.init(function () {
					var cidrs = Prompters.cidr.getValues();
					for (var i = 0; i < cidrs.length; i++) {
						var addr;
						if (cidrs[i].search(':') > 0) {
							addr = this.makeIpv6(cidrs[i]);
						} else {
							addr = this.makeIpv4(cidrs[i]);
						}
						this.addrs.push(addr);
					}
				}.bind(this));
				console.log(this.addrs);
			},

			getSuggestions: function getSuggestions(value) {
				var inputValue = value.trim().toLowerCase();
				var inputLength = inputValue.length;

				if (inputLength === 0) return [];

				return this.addrs.filter(function (addr) {
					return addr.toLowerCase().slice(0, inputLength) === inputValue;
				});
			},

			/* Gives all the addresses */
			getValues: function getValues() {
				return this.addrs;
			}
		},

		/*************************  Handler name="dhcprange" *******************/

		dhcprange: {

			dhcpranges: [],

			init: function init(callback) {
				var cidr = "172.16.0.0/16"; //XXX retrive this value externally
				C.getJSON(C.APIURL + '/dhcpranges?cidr=' + cidr, function (response) {
					this.dhcpranges = response;
				}.bind(this), callback);
			},

			/* Gives all the addresses */
			getValues: function getValues() {
				return this.dhcpranges;
			}

		},

		/*************************  Handler name="dhcp" *******************/

		dhcp: {

			/** TODO **/
			dhcp: [],

			init: function init(callback) {
				var _callback = function () {
					this._combine(callback);
				}.bind(this);

				var c = new CallbackCountdown(_callback, 2); /* XXX This will be 3 */

				Prompters.domain.init(c.callback);
				Prompters.dhcprange.init(c.callback);
			},

			_combine: function _combine(callback) {
				var dhcpranges = Prompters.dhcprange.getValues();
				var domains = Prompters.domain.getValues();
				for (var i = 0; i < dhcpranges.length; i++) {

					var value = Prompters.domain.id2Name(dhcpranges[i].iddom);
					var doms = { 'values': domains, 'value': value };
					var cpy = $.extend({ 'domain': doms }, dhcpranges[i]);
					this.dhcp.push(cpy);
				}

				callback();
			},

			/* Gives all the addresses */
			getValues: function getValues() {
				return this.dhcp;
			},

			getEmptyRow: function getEmptyRow() {
				return { 'domain': Prompters.domain.getValues() };
			},

			save: function save(key, input) {
				var iddom = Prompters.domain.name2Id(input.domain);
				var data_req = $.extend({ iddom: iddom }, input);
				delete data_req.domain;
				console.log("--------- SAVE ----------");
				console.log("POST /api/dhcprange " + JSON.stringify(data_req));
				$.ajax({
					method: 'POST',
					url: C.APIURL + "/dhcpranges",
					data: JSON.stringify(data_req),
					contentType: 'application/json'
				});
			},

			update: function update(key, input) {
				var iddom = Prompters.domain.name2Id(input.domain);
				var data_req = $.extend({ iddom: iddom }, input);
				delete data_req.domain;
				console.log("--------- UPDATE ----------");
				console.log("PUT /api/dhcpranges/" + key + " " + JSON.stringify(data_req));
				$.ajax({
					method: 'PUT',
					url: C.APIURL + "/dhcpranges/" + key,
					data: JSON.stringify(data_req),
					contentType: 'application/json'
				});
			},

			delete: function _delete(key, input) {
				console.log("--------- DELETE ----------");
				console.log("DELETE /api/dhcpranges/" + key);
				return;
				$.ajax({
					method: 'DELETE',
					url: C.APIURL + "/dhcpranges/" + key
				});
			}

		}

	};

	var CallbackCountdown = function CallbackCountdown(callback, n) {
		this.count = 0;
		this.n = n;
		this._callback = callback;
		this.callback = function () {
			this.count++;
			if (this.count >= this.n) {
				return this._callback.apply(this, arguments);
			}
		}.bind(this);
	};

/***/ }

});