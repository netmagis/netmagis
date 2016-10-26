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

		    <li className={"dropdown" + this.showIf ('logged')}>
		      <a href="#"
			  className="dropdown-toggle"
			  data-toggle="dropdown"
			  role="button"
			  aria-haspopup="true"
			  aria-expanded="false"
			  >
			{S.mc ('DNS')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="dns1">
			  <a href="#">{S.mc ('Consult')}</a>
			</li>
			<li key="dns2">
			  <a href="#">
			    <p onClick={this.gotoApp.bind (this, 'add')}>
			      {S.mc ('Add')}
			    </p>
			  </a>
			</li>
			<li key="dns3">
			  <a href="#">{S.mc ('Delete')}</a>
			</li>
			<li key="dns4">
			  <a href="#">{S.mc ('Modify')}</a>
			</li>
			<li key="dns5">
			  <a href="#">{S.mc ('Mail roles')}</a>
			</li>
			<li key="dns6">
			  <a href="#">
			    <p onClick={this.gotoApp.bind (this, 'dhcprange')}>
			      {S.mc ('DHCP ranges')}
			    </p>
			  </a>
			</li>
			<li key="dns7" className={this.showIf ('pgauth')}>
			  <a href="#">{S.mc ('Password')}</a>
			</li>
			<li key="dns8">
			  <a href="#">{S.mc ('Where am I?')}</a>
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
			{S.mc ('Topo')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="topo1">
			  <a href="#">{S.mc ('Equipments')}</a>
			</li>
			<li key="topo2">
			  <a href="#">{S.mc ('Vlans')}</a>
			</li>
			<li key="topo3">
			  <a href="#">{S.mc ('Networks')}</a>
			</li>
			<li key="topo4" className={this.showIf ('genl')}>
			  <a href="#">{S.mc ('Link number')}</a>
			</li>
			<li key="topo5" className={this.showIf ('admin')}>
			  <a href="#">{S.mc ('Status')}</a>
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
			{S.mc ('MAC')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="mac1">
			  <a href="macindex">{S.mc ('Index')}</a>
			</li>
			<li key="mac2">
			  <a href="mac">{S.mc ('Search')}</a>
			</li>
			<li key="mac3">
			  <a href="ipinact">{S.mc ('Inactive addr.')}</a>
			</li>
			<li key="mac4">
			  <a href="macstat">{S.mc ('Stats')}</a>
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
			{S.mc ('Admin')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="admin1">
			  <a href="admlmx">{S.mc ('List MX')}</a>
			</li>
			<li key="admin2">
			  <a href="lnet">{S.mc ('List networks')}</a>
			</li>
			<li key="admin3">
			  <a href="lusers">{S.mc ('List users')}</a>
			</li>
			<li key="admin4">
			  <a href="who?action=now">{S.mc ('Connected users')}</a>
			</li>
			<li key="admin5">
			  <a href="who?action=last">{S.mc ('Last connections')}</a>
			</li>
			<li key="admin6">
			  <a href="#">{S.mc ('Status')}</a>
			</li>
			<li key="admin7">
			  <a href="admref?type=org">{S.mc ('Modify organizations')}</a>
			</li>
			<li key="admin8">
			  <a href="admref?type=comm">{S.mc ('Modify communities')}</a>
			</li>
			<li key="admin9">
			  <a href="admref?type=hinfo">{S.mc ('Modify machine types')}</a>
			</li>
			<li key="admin10">
			  <a href="admref?type=net">{S.mc ('Modify networks')}</a>
			</li>
			<li key="admin11">
			  <a href="admref?type=domain">{S.mc ('Modify domains')}</a>
			</li>
			<li key="admin12">
			  <a href="admmrel">{S.mc ('Modify mailhost')}</a>
			</li>
			<li key="admin13">
			  <a href="admmx">{S.mc ('Modify MX')}</a>
			</li>
			<li key="admin14">
			  <a href="admref?type=view">{S.mc ('Modify views')}</a>
			</li>
			<li key="admin15">
			  <a href="admref?type=zone">{S.mc ('Modify zones')}</a>
			</li>
			<li key="admin16">
			  <a href="admref?type=zone4">{S.mc ('Modify rev IPv4 zones')}</a>
			</li>
			<li key="admin17">
			  <a href="admref?type=zone6">{S.mc ('Modify rev IPv6 zones')}</a>
			</li>
			<li key="admin18">
			  <a href="admref?type=dhcpprof">{S.mc ('Modify DHCP profiles')}</a>
			</li>
			<li key="admin19">
			  <a href="admref?type=vlan">{S.mc ('Modify Vlans')}</a>
			</li>
			<li key="admin20">
			  <a href="admref?type=eqtype">{S.mc ('Modify equipment types')}</a>
			</li>
			<li key="admin21">
			  <a href="admref?type=eq">{S.mc ('Modify equipments')}</a>
			</li>
			<li key="admin22">
			  <a href="admref?type=confcmd">{S.mc ('Modify configuration commands')}</a>
			</li>
			<li key="admin23">
			  <a href="admref?type=dotattr">{S.mc ('Modify Graphviz attributes')}</a>
			</li>
			<li key="admin24">
			  <a href="admgrp">{S.mc ('Modify users and groups')}</a>
			</li>
			<li key="admin25">
			  <a href="admzgen">{S.mc ('Force zone generation')}</a>
			</li>
			<li key="admin26">
			  <a href="admpar">{S.mc ('Application parameters')}</a>
			</li>
			<li key="admin27">
			  <a href="statuser">{S.mc ('Statistics by user')}</a>
			</li>
			<li key="admin28">
			  <a href="statorg">{S.mc ('Statistics by organization')}</a>
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
			{S.mc ('Auth')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="pgadmin1">
			  <a href="pgaacc?action=list">{S.mc ('List accounts')}</a>
			</li>
			<li key="pgadmin2">
			  <a href="pgaacc?action=print">{S.mc ('Print accounts')}</a>
			</li>
			<li key="pgadmin3">
			  <a href="pgaacc?action=add">{S.mc ('Add account')}</a>
			</li>
			<li key="pgadmin4">
			  <a href="pgaacc?action=mod">{S.mc ('Modify account')}</a>
			</li>
			<li key="pgadmin5">
			  <a href="pgaacc?action=del">{S.mc ('Remove account')}</a>
			</li>
			<li key="pgadmin6">
			  <a href="pgaacc?action=passwd">{S.mc ('Change account password')}</a>
			</li>
			<li key="pgadmin7">
			  <a href="pgarealm?action=list">{S.mc ('List realms')}</a>
			</li>
			<li key="pgadmin8">
			  <a href="pgarealm?action=add">{S.mc ('Add realm')}</a>
			</li>
			<li key="pgadmin9">
			  <a href="pgarealm?action=mod">{S.mc ('Modify realm')}</a>
			</li>
			<li key="pgadmin10">
			  <a href="pgarealm?action=del">{S.mc ('Remove realm')}</a>
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
			&nbsp; {this.context.nm.user}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="user1">
			  <a href="profile.html">{S.mc ('Profile')}</a>
			</li>
			<li key="user2">
			  <a href="sessions.html">{S.mc ('Sessions')}</a>
			</li>
			<li key="user3" role="separator"
			    className={"divider" + this.showIf ('admin')}
			    />
			<li key="user4" className={this.showIf ('admin')}>
			  <a href="sudo.html">{S.mc ('Sudo')}</a>
			</li>
			<li key="user5" className={this.showIf ('setuid')}>
			  <a href="sudo.html">{S.mc ('Back to my id')}</a>
			</li>
			<li key="user6" role="separator" className="divider"
			    />
			<li key="user7">
			  <a href="#">
			    <p onClick={S.disconnect}>
			      {S.mc ('Disconnect')}
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
			{S.mc ('[en]')}
			<span className="caret" />
		      </a>
		      <ul className="dropdown-menu">
			<li key="lang-en">
			  <a href="#">
			    <p onClick={S.changeLang.bind (this, 'en')}>[en]</p>
			  </a>
			</li>
			<li key="lang-fr">
			  <a href="#">
			    <p onClick={S.changeLang.bind (this, 'fr')}>[fr]</p>
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
		   <NMRouter app={this.state.curApp} p1={this.state.p1} />
		</div>
	      </div>
	    </div>
	  </div>
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
