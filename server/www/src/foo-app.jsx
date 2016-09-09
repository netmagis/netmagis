import React from 'react' ;
import ReactDOM from 'react-dom' ;
import cookie from 'react-cookie' ;
import {Translator, translate, updateTranslations} from './lang.jsx' ;
import * as F from './bootstrap-lib/form-utils.jsx' ;
import * as C from './common.js' ;

/*
 * Top-level Netmagis menu
 * Holds state: result of the /cap API
 */

export var TopLevel = React.createClass ({
    // To enforce a rerendering on language change
    contextTypes: {lang: React.PropTypes.string},

    // current user capabilities (extracted from /cap API)
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

    getInitialState: function () {
	return {
	    curApp: 'index',
	    p1: '',
	    p2: '',
	    cap: [],
	    user: '',
	} ;
    },

    componentDidMount: function () {
	this.serverRequest = C.reqJSON ({
	    url: C.APIURL + "/cap",
	    success: function (result) {
		    var rc ;
		    for (var c in this.cap) {
			this.cap [c] = false ;
		    }
		    for (var ic in result.cap) {
			rc = result.cap [ic] ;
			if (this.cap [rc] != undefined) {
			    this.cap [rc] = true ;
			}
		    }
		    this.setState ({
			cap: result.cap,
			user: result.user,
		    }) ;
		}.bind (this)
	}) ;
    },

    componentWillUnmount: function () {
	this.serverRequest.abort () ;
    },

    handleDisconnect: function () {
	cookie.remove ('session', {path: C.APIURL}) ;
	document.location.reload (true) ;
    },

    handleSearchForm: function (event) {
	event.preventDefault () ;
	var srch = this.refs.topsearch.value ;
	if (srch != '') {
	    this.setState ({
		curApp: 'search',
		p1: srch,
		p2: ''
	    }) ;
	}
    },

    handleLang: function (l) {
	// console.log ('handleLang : l=', l, ', C.APIURL=', C.APIURL)
	cookie.save ('lang', l, {path: C.APIURL}) ;
	updateTranslations () ;
    },

    handleLangEn: function () {
	this.handleLang ('en') ;
    },

    handleLangFr: function () {
	this.handleLang ('fr') ;
    },

    // hide (with bootstrap class) an element:
    // http://getbootstrap.com/css/#helper-classes-show-hide
    showIf: function (c) {
	return this.cap [c] ? "" : " hidden" ;
    },

    render: function () {
	return (
	  <div>
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

		    <li className={"dropdown" + this.showIf ('logged')}>
		      <a href="#"
			  className="dropdown-toggle"
			  data-toggle="dropdown"
			  role="button"
			  aria-haspopup="true"
			  aria-expanded="false"
			  >
			{translate ('DNS')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="dns1">
			  <a href="#">{translate ('Consult')}</a>
			</li>
			<li key="dns2">
			  <a href="#">{translate ('Add')}</a>
			</li>
			<li key="dns3">
			  <a href="#">{translate ('Delete')}</a>
			</li>
			<li key="dns4">
			  <a href="#">{translate ('Modify')}</a>
			</li>
			<li key="dns5">
			  <a href="#">{translate ('Mail roles')}</a>
			</li>
			<li key="dns6">
			  <a href="#">{translate ('DHCP ranges')}</a>
			</li>
			<li key="dns7" className={this.showIf ('pgauth')}>
			  <a href="#">{translate ('Password')}</a>
			</li>
			<li key="dns8">
			  <a href="#">{translate ('Where am I?')}</a>
			</li>
		      </ul>
		    </li>

		    <li className={"dropdown" + this.showIf ('topo')}>
		      <a href="#"
			  className="dropdown-toggle"
			  data-toggle="dropdown"
			  role="button"
			  aria-haspopup="true"
			  aria-expanded="false"
			  >
			{translate ('Topo')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="topo1">
			  <a href="#">{translate ('Equipments')}</a>
			</li>
			<li key="topo2">
			  <a href="#">{translate ('Vlans')}</a>
			</li>
			<li key="topo3">
			  <a href="#">{translate ('Networks')}</a>
			</li>
			<li key="topo4" className={this.showIf ('genl')}>
			  <a href="#">{translate ('Link number')}</a>
			</li>
			<li key="topo5" className={this.showIf ('admin')}>
			  <a href="#">{translate ('Status')}</a>
			</li>
		      </ul>
		    </li>

		    <li className={"dropdown" + this.showIf ('mac')}>
		      <a href="#"
			  className="dropdown-toggle"
			  data-toggle="dropdown"
			  role="button"
			  aria-haspopup="true"
			  aria-expanded="false"
			  >
			{translate ('MAC')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="mac1">
			  <a href="macindex">{translate ('Index')}</a>
			</li>
			<li key="mac2">
			  <a href="mac">{translate ('Search')}</a>
			</li>
			<li key="mac3">
			  <a href="ipinact">{translate ('Inactive addr.')}</a>
			</li>
			<li key="mac4">
			  <a href="macstat">{translate ('Stats')}</a>
			</li>
		      </ul>
		    </li>

		    <li className={"dropdown" + this.showIf ('admin')}>
		      <a href="#"
			  className="dropdown-toggle"
			  data-toggle="dropdown"
			  role="button"
			  aria-haspopup="true"
			  aria-expanded="false"
			  >
			{translate ('Admin')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="admin1">
			  <a href="admlmx">{translate ('List MX')}</a>
			</li>
			<li key="admin2">
			  <a href="lnet">{translate ('List networks')}</a>
			</li>
			<li key="admin3">
			  <a href="lusers">{translate ('List users')}</a>
			</li>
			<li key="admin4">
			  <a href="who?action=now">{translate ('Connected users')}</a>
			</li>
			<li key="admin5">
			  <a href="who?action=last">{translate ('Last connections')}</a>
			</li>
			<li key="admin6">
			  <a href="#">{translate ('Status')}</a>
			</li>
			<li key="admin7">
			  <a href="admref?type=org">{translate ('Modify organizations')}</a>
			</li>
			<li key="admin8">
			  <a href="admref?type=comm">{translate ('Modify communities')}</a>
			</li>
			<li key="admin9">
			  <a href="admref?type=hinfo">{translate ('Modify machine types')}</a>
			</li>
			<li key="admin10">
			  <a href="admref?type=net">{translate ('Modify networks')}</a>
			</li>
			<li key="admin11">
			  <a href="admref?type=domain">{translate ('Modify domains')}</a>
			</li>
			<li key="admin12">
			  <a href="admmrel">{translate ('Modify mailhost')}</a>
			</li>
			<li key="admin13">
			  <a href="admmx">{translate ('Modify MX')}</a>
			</li>
			<li key="admin14">
			  <a href="admref?type=view">{translate ('Modify views')}</a>
			</li>
			<li key="admin15">
			  <a href="admref?type=zone">{translate ('Modify zones')}</a>
			</li>
			<li key="admin16">
			  <a href="admref?type=zone4">{translate ('Modify rev IPv4 zones')}</a>
			</li>
			<li key="admin17">
			  <a href="admref?type=zone6">{translate ('Modify rev IPv6 zones')}</a>
			</li>
			<li key="admin18">
			  <a href="admref?type=dhcpprof">{translate ('Modify DHCP profiles')}</a>
			</li>
			<li key="admin19">
			  <a href="admref?type=vlan">{translate ('Modify Vlans')}</a>
			</li>
			<li key="admin20">
			  <a href="admref?type=eqtype">{translate ('Modify equipment types')}</a>
			</li>
			<li key="admin21">
			  <a href="admref?type=eq">{translate ('Modify equipments')}</a>
			</li>
			<li key="admin22">
			  <a href="admref?type=confcmd">{translate ('Modify configuration commands')}</a>
			</li>
			<li key="admin23">
			  <a href="admref?type=dotattr">{translate ('Modify Graphviz attributes')}</a>
			</li>
			<li key="admin24">
			  <a href="admgrp">{translate ('Modify users and groups')}</a>
			</li>
			<li key="admin25">
			  <a href="admzgen">{translate ('Force zone generation')}</a>
			</li>
			<li key="admin26">
			  <a href="admpar">{translate ('Application parameters')}</a>
			</li>
			<li key="admin27">
			  <a href="statuser">{translate ('Statistics by user')}</a>
			</li>
			<li key="admin28">
			  <a href="statorg">{translate ('Statistics by organization')}</a>
			</li>
		      </ul>
		    </li>

		    <li className={"dropdown" + this.showIf ('pgadmin')}>
		      <a href="#"
			  className="dropdown-toggle"
			  data-toggle="dropdown"
			  role="button"
			  aria-haspopup="true"
			  aria-expanded="false"
			  >
			{translate ('Auth')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="pgadmin1">
			  <a href="pgaacc?action=list">{translate ('List accounts')}</a>
			</li>
			<li key="pgadmin2">
			  <a href="pgaacc?action=print">{translate ('Print accounts')}</a>
			</li>
			<li key="pgadmin3">
			  <a href="pgaacc?action=add">{translate ('Add account')}</a>
			</li>
			<li key="pgadmin4">
			  <a href="pgaacc?action=mod">{translate ('Modify account')}</a>
			</li>
			<li key="pgadmin5">
			  <a href="pgaacc?action=del">{translate ('Remove account')}</a>
			</li>
			<li key="pgadmin6">
			  <a href="pgaacc?action=passwd">{translate ('Change account password')}</a>
			</li>
			<li key="pgadmin7">
			  <a href="pgarealm?action=list">{translate ('List realms')}</a>
			</li>
			<li key="pgadmin8">
			  <a href="pgarealm?action=add">{translate ('Add realm')}</a>
			</li>
			<li key="pgadmin9">
			  <a href="pgarealm?action=mod">{translate ('Modify realm')}</a>
			</li>
			<li key="pgadmin10">
			  <a href="pgarealm?action=del">{translate ('Remove realm')}</a>
			</li>
		      </ul>
		    </li>

		  </ul>

		  <span className={this.showIf ('logged')}>
		    <form className="navbar-form navbar-left"
			  role="search"
			  action=""
			  onSubmit={this.handleSearchForm}>
		      <div className="form-group">
			<input type="text"
			    className="form-control"
			    placeholder={translate ('Enter text')}
			    ref="topsearch"
			    aria-label="Search"
			    />
		      </div>
		      <button type="submit" className="btn btn-default"
			    >
			<span className="glyphicon glyphicon-search"
			    aria-label="Submit"
			    />
		      </button>
		    </form>
		  </span>

		  <ul className="nav navbar-nav navbar-right">

		    <li className={this.cap ['logged'] ? 'hidden' : 'show'}
			key="notconnected"
			>
		      <p className="navbar-text">
			{translate ('Not connected')}
		      </p>
		    </li>
		    <li className={"dropdown" + this.showIf ('logged')}
			key="user"
			>
		      <a href="#" className="dropdown-toggle"
				data-toggle="dropdown"
				role="button"
				aria-haspopup="true"
				aria-expanded="false"
				>
			<span className="glyphicon glyphicon-user" />
			&nbsp; {this.state.user}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="user1">
			  <a href="profile.html">{translate ('Profile')}</a>
			</li>
			<li key="user2">
			  <a href="sessions.html">{translate ('Sessions')}</a>
			</li>
			<li key="user3" role="separator"
			    className={"divider" + this.showIf ('admin')}
			    />
			<li key="user4" className={this.showIf ('admin')}>
			  <a href="sudo.html">{translate ('Sudo')}</a>
			</li>
			<li key="user5" className={this.showIf ('setuid')}>
			  <a href="sudo.html">{translate ('Back to my id')}</a>
			</li>
			<li key="user6" role="separator" className="divider"
			    />
			<li key="user7">
			  <a href="#">
			    <p onClick={this.handleDisconnect}>
			      {translate ('Disconnect')}
			    </p>
			  </a>
			</li>
		      </ul>
		    </li>

		    <li className="dropdown">
		      <a href="#"
			  className="dropdown-toggle"
			  data-toggle="dropdown"
			  role="button"
			  aria-haspopup="true"
			  aria-expanded="false"
			  >
			{translate ('[en]')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="lang-en">
			  <a href="#">
			    <p onClick={this.handleLangEn}>[en]</p>
			  </a>
			</li>
			<li key="lang-fr">
			  <a href="#">
			    <p onClick={this.handleLangFr}>[fr]</p>
			  </a>
			</li>
		      </ul>
		    </li>

		  </ul>
		</div>
	      </div>
	    </nav>

	    <div className="container-fluid">
	      <div className="row">
		<div className="col-md-12">
		  <App app={this.state.curApp} p1={this.state.p1} />
		</div>
	      </div>
	    </div>
	  </div>
	) ;
    }
}) ;

var App = React.createClass ({
    // To enforce a rerendering on language change
    contextTypes: {lang: React.PropTypes.string},

    getInitialState: function () {
	return {message : "", color: ""}; 
    },

    render: function () {
	switch (this.props.app) {
	    case 'index' :
		return (
			<div>
			  <p>here is the index</p>
			</div>
		    ) ;
	    case 'search' :
		return (
			<div>
			  <p>Searching {this.props.p1}</p>
			</div>
		    ) ;
	    case 'foo' :
		return (
		    <div>
			<p>Foo!</p>
		    </div>
		) ;
	    default :
		return (
			<div>
			  <p>Default</p>
			</div>
		    ) ;
	}
    }
}) ;


/* Render the app on the element with id #app */
var dom_node = document.getElementById ('app') ;

ReactDOM.render (<Translator><TopLevel /></Translator>, dom_node) ;
