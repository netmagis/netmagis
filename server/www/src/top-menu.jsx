import React from 'react' ;
import ReactDOM from 'react-dom' ;
import cookie from 'react-cookie' ;
import * as C from './common.js' ;
import {Translator, translate, updateTranslations} from './lang.jsx' ;

/*
 * Top-level menu
 * Holds state: result of the /menus API
 *
 * TopMenu
 *  `--- MenuDropDown []
 *  `--- SearchBar
 *  `--- UserMenu
 *  |     `--- MenuDropDown
 *  |           `--- MenuDisconnect		XXX SPECIAL CASE TO REMOVE
 *  `--- LangMenu
 *        `--- MenuDropDown
 *  |           `--- MenuLang			XXX SPECIAL CASE TO REMOVE
 */

export var TopMenu = React.createClass ({
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
	this.serverRequest = C.reqJSON ({
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
	  <Translator>

	    <nav className="navbar navbar-default">
	      <div className="container-fluid">
		<div className="navbar-header">
		  <button type="button"
		      className="navbar-toggle collapsed"
		      data-toggle="collapse"
		      data-target="#nm-navbar-collapse-1"
		      aria-expanded="false">
		    <span className="sr-only">
		      Toggle navigation
		    </span>
		    <span className="icon-bar" />
		    <span className="icon-bar" />
		    <span className="icon-bar" />
		  </button>
		  <a className="logo" rel="home" href="http://www.netmagis.org">
		    <img alt="Netmagis" src="logo-transp.png" height="50px" />
		  </a>
		</div>

		<div className="collapse navbar-collapse"
		    id="nm-navbar-collapse-1"
		    >
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
	      </div>
	    </nav>

	    <div className="container-fluid">
	      <div className="row">
		<div className="col-md-12">
		  {this.props.children}
		</div>
	      </div>
	    </div>

	  </Translator>
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
		} else if (item.title == "[en]") {
		    menuitems.push (<MenuLang lang="en" />) ;
		} else if (item.title == "[fr]") {
		    menuitems.push (<MenuLang lang="fr" />) ;
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
	cookie.remove ('session', { path: C.APIURL}) ;
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


var MenuLang = React.createClass ({
    handleClick: function (l) {
	cookie.save ('lang', l, { path: C.APIURL }) ;
	document.location.reload (true) ;
    },

    render: function () {
	return (
		<li>
		  <a href="#">
		    <p onClick={this.handleClick.bind (this, this.props.lang)}>
		      [{this.props.lang}]
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
