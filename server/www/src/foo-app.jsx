import React from 'react' ;
import ReactDOM from 'react-dom' ;
import {Translator, updateTranslations} from './lang.jsx' ;
import * as F from './bootstrap-lib/form-utils.jsx' ;
import * as C from './common.js' ;

/*
 * Top-level menu
 * Holds state: result of the /menus API
 */

var TopMenu = React.createClass ({
    getInitialState: function () {
	return {
	    left: [],
	    search: null,
	    user: null,
	    lang: {
		title: "[en]",
		items: []
	    }
	} ;
    },

    componentDidMount: function () {
	this.serverReqest = C.reqJSON ({
	    url: C.APIURL + "/menus",
	    success: function (result) {
		    this.setState (result) ;
		}.bind (this)
	}) ;
    },

    componentWillUnmount: function () {
	this.serverRequest.abort () ;
    },

    render: function () {
	var left = [] ;
	this.state.left.forEach (function (menu) {
		left.push (<MenuDropdown
				title={menu.title}
				items={menu.items}
				iconClass={""}
				/>) ;
	    }.bind (this)
	) ;

	return (
	    <div
		className="collapse navbar-collapse"
		id="nm-navbar-collapse-1">
	      <ul className="nav navbar-nav">
		<li>
		  <a href="#">
		    <span className="glyphicon glyphicon-home"
			aria-hidden="true"
			/>
		    <span className="sr-only">
			Home
		    </span>
		  </a>
		</li>
		{left}
	      </ul>
	      <SearchBar item={this.state.search} />
	      <ul className="nav navbar-nav navbar-right">
		<UserMenu item={this.state.user} />
		<LangMenu item={this.state.lang} />
	      </ul>
	    </div>
	) ;
    }
}) ;

/*
 * A single dropdown in a top-level menu
 * props: 
 * - iconClass: empty string or icon class
 * - title: title of dropdown
 * - items: items for the dropdown
 */

var MenuDropdown = React.createClass ({
    render: function () {
	var icon ;
	var menuitems = [] ;

	if (this.props.iconClass == "") {
	    icon = <span /> ;
	} else {
	    /* leave a space between icon and text */
	    icon = <span className={this.props.iconClass} /> ;
	}

	this.props.items.forEach (function (item) {
		var js = "" ;
		if (item.title == "") {
		    menuitems.push (<li role="separator"
					className="divider" />) ;
		} else if (item.title == "Disconnect") {
		    menuitems.push (<MenuDisconnect />) ;
		} else {

		    if (item.js == "") {
			js = ' onclick="' + item.js + '"' ;
		    }
		    menuitems.push (<li>
				      <a href={item.url}>
					{item.title}
				      </a>
				    </li>
		    ) ;
		}
	    }.bind (this)
	) ;

	return (
	    <li className="dropdown">
	      <a href="#"
		  className="dropdown-toggle"
		  data-toggle="dropdown"
		  role="button"
		  aria-haspopup="true"
		  aria-expanded="false"
		  >
		{icon} {this.props.title}
		<span className="caret" />
	      </a>
	      <ul className="dropdown-menu">
		{menuitems}
	      </ul>
	    </li>
	) ;
    }
}) ;

var MenuDisconnect = React.createClass ({
    handleClick: function () {
	document.cookie = 'session=;Path=' + C.APIURL + '/;Expires=Thu, 01 Jan 1970 00:00:01 GMT;'  ;
	document.location.reload (true) ;
    },
    render: function () {
	return (
		<li>
		  <a href="#">
		    <p onClick={this.handleClick}>
		      Disconnect
		    </p>
		  </a>
		</li>
		) ;
    }
}) ;



/*
 * Search bar
 * props: 
 * - item: null or {title: ..., url=..., js=...}
 */

var SearchBar = React.createClass ({
    render: function () {
	var bar ;

	if (this.props.item == null) {
	    bar = <span /> ;
	} else {
	    bar = <form className="navbar-form navbar-left"
			role="search">
		    <div className="form-group">
		      <input type="text"
			  className="form-control"
			  placeholder={this.props.item.title}
			  aria-label="Search"
			  />
		    </div>
		    <button type="submit" className="btn btn-default">
		      <span className="glyphicon glyphicon-search"
			  aria-label="Submit"
			  />
		    </button>
		  </form>
		  ;
	}

	return bar ;
    }
}) ;


/*
 * User menu
 * props: 
 * - items: null or {title: ..., items: [...] }
 */

var UserMenu = React.createClass ({
    render: function () {
	var u ;

	if (this.props.item == null) {
	    u = <li>
		  <p className="navbar-text">
		    Not connected
		  </p>
		</li>
		;
	} else {
	    u = <MenuDropdown
		    title={this.props.item.title}
		    items={this.props.item.items}
		    iconClass="glyphicon glyphicon-user"
		    />
		;
	}

	return u ;
    }
}) ;


/*
 * Language menu
 * props: 
 * - items: {title: ..., items: [...] }
 */

var LangMenu = React.createClass ({
    render: function () {
	return (<MenuDropdown
		    title={this.props.item.title}
		    items={this.props.item.items}
		    iconClass=""
		    />
		) ;
    }
}) ;


/*
 * Search Results
 */

var SearchResultItem = React.createClass ({
    render: function () {
	return (
	    <li>
		<a href="{this.props.link}">
		    {this.props.type}
		</a>
	    </li>
	) ;
    }
}) ;

var SearchResults = React.createClass ({
    render: function () {
	var rows = [] ;
	var r ;
	this.props.items.forEach (function (item) {
	    rows.push (<SearchResultItem
			    link={item.link}
			    type={item.type}
			    />
			) ;
	}) ;
	return (<ul>{rows}</ul>) ;
    }
}) ;

var dom_menus = document.getElementById ('topmenus') ;
ReactDOM.render (<Translator><TopMenu /></Translator>, dom_menus) ;


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
