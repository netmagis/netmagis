import React from 'react' ;
import ReactDOM from 'react-dom' ;
import * as S from './nm-state.jsx' ;
import * as C from './common.js' ;
import {Login}		from './app-login.jsx' ;
import {Add}		from './app-add.jsx' ;
import {DHCPRange}	from './app-dhcprange.jsx' ;

export var NMMenu = React.createClass ({
    // Enforce a rerendering on language/capability change
    contextTypes: {nm: React.PropTypes.object},

    getInitialState: function () {
	return {
	    curApp: 'index',
	    p1: '',
	    p2: '',
	} ;
    },

    gotoApp: function (app, p1, p2) {
	this.setState ({curApp: app, p1: p1, p2: p2}) ;
    },

    handleSearchForm: function (event) {
	event.preventDefault () ;
	var srch = this.refs.topsearch.value ;
	if (srch != '') {
	    this.setState ({
		curApp: 'search',
		p1: srch
	    }) ;
	}
    },

    // hide (with bootstrap class) an element:
    // http://getbootstrap.com/css/#helper-classes-show-hide
    showIf: function (c) {
	return this.context.nm.cap [c] ? "" : " hidden" ;
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
		    <img alt="Netmagis" src="files/logo-transp.png" height="50px" />
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

		    <NMDropdown k="dns" t={S.mc ('DNS')} show={this.showIf ('logged')}>
		      <NMItem k="dns1" js={this.gotoApp.bind (this, 'consult')} t={S.mc ('Consult')} />
		      <NMItem k="dns2" js={this.gotoApp.bind (this, 'add')} t={S.mc ('Add')} />
		      <NMItem k="dns3" js={this.gotoApp.bind (this, 'del')} t={S.mc ('Delete')} />
		      <NMItem k="dns4" js={this.gotoApp.bind (this, 'mod')} t={S.mc ('Modify')} />
		      <NMItem k="dns5" js={this.gotoApp.bind (this, 'mailrole')} t={S.mc ('Mail roles')} />
		      <NMItem k="dns6" js={this.gotoApp.bind (this, 'dhcprange')} t={S.mc ('DHCP ranges')} />
		      <NMItem k="dns7" js={this.gotoApp.bind (this, 'pgpasswd')} t={S.mc ('Password')} show={this.showIf ('pgauth')} />
		      <NMItem k="dns8" js={this.gotoApp.bind (this, 'where')} t={S.mc ('Where am I?')} />
		    </NMDropdown>

		    <NMDropdown k="topo" t={S.mc ('Topo')} show={this.showIf ('topo')}>
		      <NMItem k="topo1" js={this.gotoApp.bind (this, 'eq')} t={S.mc ('Equipments')} />
		      <NMItem k="topo2" js={this.gotoApp.bind (this, 'l2')} t={S.mc ('Vlans')} />
		      <NMItem k="topo3" js={this.gotoApp.bind (this, 'l3')} t={S.mc ('Networks')} />
		      <NMItem k="topo4" js={this.gotoApp.bind (this, 'genl')} t={S.mc ('Link number')} show={this.showIf ('genl')} />
		      <NMItem k="topo5" js={this.gotoApp.bind (this, 'topotop')} t={S.mc ('Status')} show={this.showIf ('admin')} />
		    </NMDropdown>

		    <NMDropdown k="mac" t={S.mc ('MAC')} show={this.showIf ('mac')}>
		      <NMItem k="mac1" js={this.gotoApp.bind (this, 'macindex')} t={S.mc ('Index')} />
		      <NMItem k="mac2" js={this.gotoApp.bind (this, 'mac')} t={S.mc ('Search')} />
		      <NMItem k="mac3" js={this.gotoApp.bind (this, 'ipinact')} t={S.mc ('Inactive addr.')} />
		      <NMItem k="mac4" js={this.gotoApp.bind (this, 'macstat')} t={S.mc ('Stats')} />
		    </NMDropdown>

		    <NMDropdown k="admin" t={S.mc ('Admin')} show={this.showIf ('admin')}>
		      <NMItem k="admin1" js={this.gotoApp.bind (this, 'admlmx')} t={S.mc ('List MX')} />
		      <NMItem k="admin2" js={this.gotoApp.bind (this, 'lnet')} t={S.mc ('List networks')} />
		      <NMItem k="admin3" js={this.gotoApp.bind (this, 'lusers')} t={S.mc ('List users')} />
		      <NMItem k="admin4" js={this.gotoApp.bind (this, 'who?action=now')} t={S.mc ('Connected users')} />
		      <NMItem k="admin5" js={this.gotoApp.bind (this, 'who?action=last')} t={S.mc ('Last connections')} />
		      <NMItem k="admin6" js={this.gotoApp.bind (this, '#')} t={S.mc ('Status')} />
		      <NMItem k="admin7" js={this.gotoApp.bind (this, 'admref?type=org')} t={S.mc ('Modify organizations')} />
		      <NMItem k="admin8" js={this.gotoApp.bind (this, 'admref?type=comm')} t={S.mc ('Modify communities')} />
		      <NMItem k="admin9" js={this.gotoApp.bind (this, 'admref?type=hinfo')} t={S.mc ('Modify machine types')} />
		      <NMItem k="admin10" js={this.gotoApp.bind (this, 'admref?type=net')} t={S.mc ('Modify networks')} />
		      <NMItem k="admin11" js={this.gotoApp.bind (this, 'admref?type=domain')} t={S.mc ('Modify domains')} />
		      <NMItem k="admin12" js={this.gotoApp.bind (this, 'admmrel')} t={S.mc ('Modify mailhost')} />
		      <NMItem k="admin13" js={this.gotoApp.bind (this, 'admmx')} t={S.mc ('Modify MX')} />
		      <NMItem k="admin14" js={this.gotoApp.bind (this, 'admref?type=view')} t={S.mc ('Modify views')} />
		      <NMItem k="admin15" js={this.gotoApp.bind (this, 'admref?type=zone')} t={S.mc ('Modify zones')} />
		      <NMItem k="admin16" js={this.gotoApp.bind (this, 'admref?type=zone4')} t={S.mc ('Modify rev IPv4 zones')} />
		      <NMItem k="admin17" js={this.gotoApp.bind (this, 'admref?type=zone6')} t={S.mc ('Modify rev IPv6 zones')} />
		      <NMItem k="admin18" js={this.gotoApp.bind (this, 'admref?type=dhcpprof')} t={S.mc ('Modify DHCP profiles')} />
		      <NMItem k="admin19" js={this.gotoApp.bind (this, 'admref?type=vlan')} t={S.mc ('Modify Vlans')} />
		      <NMItem k="admin20" js={this.gotoApp.bind (this, 'admref?type=eqtype')} t={S.mc ('Modify equipment types')} />
		      <NMItem k="admin21" js={this.gotoApp.bind (this, 'admref?type=eq')} t={S.mc ('Modify equipments')} />
		      <NMItem k="admin22" js={this.gotoApp.bind (this, 'admref?type=confcmd')} t={S.mc ('Modify configuration commands')} />
		      <NMItem k="admin23" js={this.gotoApp.bind (this, 'admref?type=dotattr')} t={S.mc ('Modify Graphviz attributes')} />
		      <NMItem k="admin24" js={this.gotoApp.bind (this, 'admgrp')} t={S.mc ('Modify users and groups')} />
		      <NMItem k="admin25" js={this.gotoApp.bind (this, 'admzgen')} t={S.mc ('Force zone generation')} />
		      <NMItem k="admin26" js={this.gotoApp.bind (this, 'admpar')} t={S.mc ('Application parameters')} />
		      <NMItem k="admin27" js={this.gotoApp.bind (this, 'statuser')} t={S.mc ('Statistics by user')} />
		      <NMItem k="admin28" js={this.gotoApp.bind (this, 'statorg')} t={S.mc ('Statistics by organization')} />
		    </NMDropdown>

		    <NMDropdown k="pgadmin" t={S.mc ('Auth')} show={this.showIf ('pgadmin')}>
		      <NMItem k="pgadmin1" js={this.gotoApp.bind (this, 'pgaacc?action=list')} t={S.mc ('List accounts')} />
		      <NMItem k="pgadmin2" js={this.gotoApp.bind (this, 'pgaacc?action=print')} t={S.mc ('Print accounts')} />
		      <NMItem k="pgadmin3" js={this.gotoApp.bind (this, 'pgaacc?action=add')} t={S.mc ('Add account')} />
		      <NMItem k="pgadmin4" js={this.gotoApp.bind (this, 'pgaacc?action=mod')} t={S.mc ('Modify account')} />
		      <NMItem k="pgadmin5" js={this.gotoApp.bind (this, 'pgaacc?action=del')} t={S.mc ('Remove account')} />
		      <NMItem k="pgadmin6" js={this.gotoApp.bind (this, 'pgaacc?action=passwd')} t={S.mc ('Change account password')} />
		      <NMItem k="pgadmin7" js={this.gotoApp.bind (this, 'pgarealm?action=list')} t={S.mc ('List realms')} />
		      <NMItem k="pgadmin8" js={this.gotoApp.bind (this, 'pgarealm?action=add')} t={S.mc ('Add realm')} />
		      <NMItem k="pgadmin9" js={this.gotoApp.bind (this, 'pgarealm?action=mod')} t={S.mc ('Modify realm')} />
		      <NMItem k="pgadmin10" js={this.gotoApp.bind (this, 'pgarealm?action=del')} t={S.mc ('Remove realm')} />
		    </NMDropdown>

		  </ul>

		  <span className={this.showIf ('logged')}>
		    <form className="navbar-form navbar-left"
			  role="search"
			  action=""
			  onSubmit={this.handleSearchForm}>
		      <div className="form-group">
			<input type="text"
			    className="form-control"
			    placeholder={S.mc ('Enter text')}
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

		    <li className={this.context.nm.cap ['logged'] ? 'hidden' : 'show'}
			key="notconnected"
			>
		      <p className="navbar-text">
			{S.mc ('Not connected')}
		      </p>
		    </li>
		    <NMDropdown k="user" t={this.context.nm.user} i="glyphicon glyphicon-user" show={this.showIf ('logged')}>
			<NMItem k="user1" js={this.gotoApp.bind (this, 'profile')} t={S.mc ('Profile')} />
			<NMItem k="user2" js={this.gotoApp.bind (this, 'sessions')} t={S.mc ('Sessions')} />
			<NMISep k="user3" show={this.showIf ('admin')} />
			<NMItem k="user4" js={this.gotoApp.bind (this, 'sudo')} t={S.mc ('Sudo')} show={this.showIf ('admin')} />
			<NMItem k="user5" js={this.gotoApp.bind (this, 'sudoback')} t={S.mc ('Back to my id')} show={this.showIf ('setuid')} />
			<NMISep k="user6" />
			<NMItem k="user7" js={S.disconnect} t={S.mc ('Disconnect')} />
		    </NMDropdown>

		    <NMDropdown k="lang" t={S.mc ('[en]')}>
			<NMItem k="lang-en" js={S.changeLang.bind (this, 'en')} t="[en]" />
			<NMItem k="lang-fr" js={S.changeLang.bind (this, 'fr')} t="[fr]" />
		    </NMDropdown>

		  </ul>
		</div>
	      </div>
	    </nav>

	    <div className="container-fluid">
	      <div className="row">
		<div className="col-md-12">
		   <NMRouter app={this.state.curApp} p1={this.state.p1} />
		</div>
	      </div>
	    </div>
	  </div>
	) ;
    }
}) ;


/*
 * Short-hand to help defining menu dropdowns
 * props:
 * - k: key
 * - show (optional): 'hidden' or nothing
 * - t: text for this menu
 # - i (optional): icon
 */

var NMDropdown = React.createClass ({
    render: function () {
	var icon = 'hidden' ;
	if (this.props.i) {
	    icon = this.props.i
	}
	return (
		<li className={"dropdown" + this.props.show}>
		  <a href="#"
		      className="dropdown-toggle"
		      data-toggle="dropdown"
		      role="button"
		      aria-haspopup="true"
		      aria-expanded="false"
		      >
		    <span className={icon}>&nbsp;</span>
		    {this.props.t}
		    <span className="caret" />
		  </a>
		  <ul className="dropdown-menu">
		    {this.props.children}
		  </ul>
		</li>
	    ) ;
    }
}) ;

/*
 * Short-hand to help defining menu items
 * props:
 * - k: key
 * - show (optional): 'hidden' or nothing
 * - js: javascript to call when clicked
 * - t: text for this menu item
 */

var NMItem = React.createClass ({
    render: function () {
	return (
		<li key={this.props.k} className={this.props.show}>
		  <a href="#" onClick={this.props.js}>
		    {this.props.t}
		  </a>
		</li>
	    ) ;
    }
}) ;

/*
 * Short-hand to help defining a menu item separator
 * props:
 * - k: key
 * - show (optional): 'hidden' or nothing
 */

var NMISep = React.createClass ({
    render: function () {
	return (
		<li key={this.props.k}
		    role="separator"
		    className={'divider ' + this.props.show}
		    />
	    ) ;
    }
}) ;

var NMRouter = React.createClass ({
    // Enforce a rerendering on language/capability change
    contextTypes: {nm: React.PropTypes.object},

    render: function () {
	switch (this.props.app) {
	    case 'index' :
		if (this.context.nm.cap.logged) {
		    return ( <div> <p>here is the index</p> </div>) ;
		} else {
		    return (<Login />) ;
		}
	    case 'search' :
		return (
			<div>
			  <p>Searching {this.props.p1}</p>
			</div>
		    ) ;
	    case 'add' :
		return (<Add />) ;
	    case 'dhcprange' :
		return (<DHCPRange />) ;
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

var NMRouterX = React.createClass ({
    render: function () {
	return (
		    <pre>
			this.props: {JSON.stringify (this.props)}
			this.state: {JSON.stringify (this.state)}
		    </pre>
		) ;
    }
}) ;
