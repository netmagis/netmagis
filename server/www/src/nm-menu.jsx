import React from "react";
// import PropTypes from 'prop-types' ;
import { withUser, UserContext } from "./user-context.jsx";
//internationalization
import { injectIntl, formatMessage, FormattedMessage } from "react-intl";
import { api } from "./netmagis.jsx";
import { BrowserRouter as Router, Link, Route } from "react-router-dom";


// import * as S from './nm-state.jsx' ;
// import * as C from './common.js' ;
// import {Login}		from './app-login.jsx' ;
// import {Add}		from './app-add.jsx' ;
// import {DHCPRange}	from './app-dhcprange.jsx' ;
// import {Sessions}	from './app-sessions.jsx' ;

/*
 * Display or hide a Bootstrap 4 component according to the current
 * capabilities (using class "d-none" or "" for Bootstrap).
 * cap: current capability array
 * cond: condition (i.e. 'logged', 'admin', or any capability)
 */

function showIf(cap, cond) {
    return cond == undefined ? "" : cap[cond] ? "" : " d-none";
}

/******************* NOT USED NOW */
function handleSearchForm(event) {
    event.preventDefault();
    var srch = this.refs.topsearch.value;
    if (srch != "") {
        this.setState({
            curApp: "search",
            p1: srch
        });
    }
}

function gotoApp(t) {}

/*
 * Short-hand to help defining menu items
 * props:
 * - k: key
 * - show (optional): 'hidden' or nothing
 * - js: javascript to call when clicked //not used anymore
 * - title: title for this menu item (usually message id or any text if 'tranlate' = false)
 * - translate (optional): do not translate the title (default=true)
 * - pDropdown: string to identify from which dropdown menu this item comes from
 */

function RawNMItem(props) {
    const { cap, title, translate, show, js, pDropdown, intl } = props;
    var tr = translate == false ? false : true;
    //console.log("Current pathname=" + props.pathname);
    return (
        <Link
            className={"dropdown-item" + showIf(cap, show)}
            /*temporary solution to url problem*/
            to={`${title.split("/")[1]}`}
        >
            {tr ? intl.formatMessage({ id: title }) : title}
        </Link>
        /*
        <a
            className={"dropdown-item" + showIf(cap, show)}
            href="#"
            onClick={js}
        >
            {tr ? intl.formatMessage({ id: title }) : title}
        </a>
        */
    );
}

//returns an internationalized menu item
const NMItem = injectIntl(withUser(RawNMItem));

/*
 * Short-hand to help defining a menu item separator
 * props:
 * - k: key
 * - show (optional): 'hidden' or nothing
 */

function RawNMISep(props) {
    const { cap, show } = props;
    return <div className={"dropdown-divider" + showIf(cap, show)} />;
}

const NMISep = injectIntl(withUser(RawNMISep));

/*
 * Short-hand to help defining menu dropdowns
 * props:
 * - k: key
 * - show (optional): 'hidden' or nothing
 * - align (optional): 'right' to align items to the right of dropdown
 * - title: menu title (usually message id or any text if 'tranlate' = false)
 * - translate (optional): translate title (default=true)
 * - icon (optional): set of classes (e.g. "fa fa-user") or nothing
 */

function RawNMDropdown(props) {
    const { cap, title, translate, show, align, icon, intl, children } = props;
    var ic = icon == "" ? "d-none" : icon;
    var dir = align == "right" ? " dropdown-menu-right" : "";
    var tr = translate === undefined ? true : translate;
    return (
        <li className={"nav-item dropdown" + showIf(cap, show)}>
            <a
                href="#"
                id={"nbdd" + title}
                className="nav-link dropdown-toggle"
                data-toggle="dropdown"
                role="button"
                aria-haspopup="true"
                aria-expanded="false"
            >
                <span>
                    <i className={ic} />
                    &nbsp;
                    {tr ? intl.formatMessage({ id: title }) : title}
                </span>
            </a>
            <div
                className={"dropdown-menu" + dir}
                aria-labelledby={"nbdd" + title}
            >
                {children}
            </div>
        </li>
    );
}

export const NMDropdown = injectIntl(withUser(RawNMDropdown));

/*
 * Pop-up with a login form
 */

class LoginForm extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            login: "",
            password: ""
        };

        //used to keep the binding
        this.handleChange = this.handleChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }

    handleChange(ev) {
        const target = ev.target;
        const name = target.name;
        const value = target.value;

        this.setState({
            [name]: value
        });
        ev.preventDefault();
    }

    nullhandler(ev) {
        ev.preventDefault();
    }

    handleSubmit(ev) {
        console.log("login=", this.state.login, ", pass=", this.state.password);
        const body = {
            login: this.state.login,
            password: this.state.password
        };
        api("POST", "sessions", body, this.nullhandler.bind(ev));
        ev.preventDefault();
    }

    render() {
        return (
            <div
                className="modal"
                id={this.props.modalid}
                tabIndex="-1"
                role="dialog"
            >
                <div className="modal-dialog" role="document">
                    <div className="modal-content">
                        <div className="modal-header">
                            <h2 className="modal-title">Please login</h2>
                            <button
                                type="button"
                                className="close"
                                data-dismiss="modal"
                                aria-label="Close"
                            >
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div className="modal-body">
                            <form onSubmit={this.handleSubmit}>
                                <input
                                    type="text"
                                    className="form-control"
                                    name="login"
                                    placeholder="Username"
                                    autoComplete="username"
                                    required=""
                                    autoFocus=""
                                    onChange={this.handleChange}
                                />
                                <input
                                    type="password"
                                    className="form-control"
                                    name="password"
                                    placeholder="Password"
                                    autoComplete="current-password"
                                    required=""
                                    onChange={this.handleChange}
                                />
                                <button
                                    className="btn btn-lg btn-primary btn-block"
                                    type="submit"
                                >
                                    Login
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        );
    }
}

//str pour la traduction ?
function toto(s) {
    return () => {
        return "toto";
    };
}

function RawNMMenu(props) {
    const { user, cap, disconnect, lang, changeLang, intl } = props;
    return (
        <Router>
            <div>
                <nav className="navbar navbar-expand-lg navbar-light bg-light">
                    <a
                        className="navbar-brand"
                        rel="home"
                        href="http://www.netmagis.org"
                    >
                        <img
                            alt="Netmagis"
                            src="files/logo-transp.png"
                            height="50px"
                        />
                    </a>
                    <button
                        className="navbar-toggler"
                        type="button"
                        data-toggle="collapse"
                        data-target="#navbarSupportedContent"
                        aria-controls="navbarSupportedContent"
                        aria-expanded="false"
                        aria-label="Toggle navigation"
                    >
                        <span className="navbar-toggler-icon" />
                    </button>

                    <div
                        className="collapse navbar-collapse"
                        id="navbarSupportedContent"
                    >
                        <ul className="navbar-nav mr-auto">
                            <li className="nav-item">
                                <Link
                                    className={"nav-link"}
                                    /*temporary solution to url problem*/
                                    to={props.pathname} //global const declared in netmagis.jsx
                                >
                                    Home
                                    <span className="sr-only">(current)</span>
                                </Link>
                            </li>

                            <NMDropdown
                                key="dns"
                                title="menu/dns"
                                show="logged"
                            >
                                <NMItem
                                    key="dns1"
                                    title="menu/consult"
                                    //js={toto.bind("consult")}
                                />
                                <NMItem
                                    key="dns2"
                                    title="menu/add"
                                    //js={toto.bind("add")}
                                />
                                <NMItem
                                    key="dns3"
                                    title="menu/del"
                                    //js={toto.bind("del")}
                                />
                                <NMItem
                                    key="dns4"
                                    title="menu/mod"
                                    //js={toto.bind("mod")}
                                />
                                <NMItem
                                    key="dns5"
                                    title="menu/mailrole"
                                    //js={toto.bind("mailrole")}
                                />
                                <NMItem
                                    key="dns6"
                                    title="menu/dhcprange"
                                    //js={toto.bind("dhcprange")}
                                />
                                <NMItem
                                    key="dns7"
                                    title="menu/pgpassword"
                                    show="pgauth"
                                    //js={toto.bind("pgpassword")}
                                />
                                <NMItem
                                    key="dns8"
                                    title="menu/where"
                                    show="pgauth"
                                    //js={toto.bind("where")}
                                />
                            </NMDropdown>

                            <NMDropdown
                                key="topo"
                                title="menu/topo"
                                show="topo"
                            >
                                <NMItem
                                    key="topo1"
                                    title="menu/eq"
                                    js={toto.bind("eq")}
                                />
                                <NMItem
                                    key="topo2"
                                    title="menu/l2"
                                    js={toto.bind("l2")}
                                />
                                <NMItem
                                    key="topo3"
                                    title="menu/l3"
                                    js={toto.bind("l3")}
                                />
                                <NMItem
                                    key="topo4"
                                    title="menu/genl"
                                    show="genl"
                                    js={toto.bind("genl")}
                                />
                                <NMItem
                                    key="topo5"
                                    title="menu/topotop"
                                    show="admin"
                                    js={toto.bind("topotop")}
                                />
                            </NMDropdown>

                            <NMDropdown key="mac" title="menu/mac" show="mac">
                                <NMItem
                                    key="mac1"
                                    title="menu/macindex"
                                    js={toto.bind("macindex")}
                                />
                                <NMItem
                                    key="mac2"
                                    title="menu/macsearch"
                                    js={toto.bind("mac")}
                                />
                                <NMItem
                                    key="mac3"
                                    title="menu/ipinact"
                                    js={toto.bind("ipinact")}
                                />
                                <NMItem
                                    key="mac4"
                                    title="menu/macstat"
                                    show="genl"
                                    js={toto.bind("macstat")}
                                />
                            </NMDropdown>

                            <NMDropdown
                                key="admin"
                                title="menu/admin"
                                show="admin"
                            >
                                <NMItem
                                    key="admin1"
                                    title="menu/admlmx"
                                    //js={toto.bind("admlmx")}
                                />
                                <NMItem
                                    key="admin2"
                                    title="menu/lnet"
                                    //js={toto.bind("lnet")}
                                />
                                <NMItem
                                    key="admin3"
                                    title="menu/lusers"
                                    //js={toto.bind("lusers")}
                                />
                                <NMItem
                                    key="admin4"
                                    title="menu/who?action=now"
                                    //js={toto.bind("who?action=now")}
                                />
                                <NMItem
                                    key="admin5"
                                    title="menu/who?action=last"
                                    //js={toto.bind("who?action=last")}
                                />
                                <NMItem
                                    key="admin6"
                                    title="menu/status"
                                    //js={toto.bind("status")}
                                />
                                <NMItem
                                    key="admin7"
                                    title="menu/admref?type=org"
                                    //js={toto.bind("admref?type=org")}
                                />
                                <NMItem
                                    key="admin8"
                                    title="menu/admref?type=comm"
                                    //js={toto.bind("admref?type=comm")}
                                />
                                <NMItem
                                    key="admin9"
                                    title="menu/admref?type=hinfo"
                                    //js={toto.bind("admref?type=hinfo")}
                                />
                                <NMItem
                                    key="admina"
                                    title="menu/admref?type=net"
                                    //js={toto.bind("admref?type=net")}
                                />
                                <NMItem
                                    key="adminb"
                                    title="menu/admref?type=domain"
                                    //js={toto.bind("admref?type=domain")}
                                />
                                <NMItem
                                    key="adminc"
                                    title="menu/admmrel"
                                    //js={toto.bind("admmrel")}
                                />
                                <NMItem
                                    key="admind"
                                    title="menu/admmx"
                                    //js={toto.bind("admmx")}
                                />
                                <NMItem
                                    key="admine"
                                    title="menu/admref?type=view"
                                    //js={toto.bind("admref?type=view")}
                                />
                                <NMItem
                                    key="adminf"
                                    title="menu/admref?type=zone"
                                    //js={toto.bind("admref?type=zone")}
                                />
                                <NMItem
                                    key="adming"
                                    title="menu/admref?type=zone4"
                                    //js={toto.bind("admref?type=zone4")}
                                />
                                <NMItem
                                    key="adminh"
                                    title="menu/admref?type=zone6"
                                    //js={toto.bind("admref?type=zone6")}
                                />
                                <NMItem
                                    key="admini"
                                    title="menu/admref?type=dhcpprof"
                                    //js={toto.bind("admref?type=dhcpprof")}
                                />
                                <NMItem
                                    key="adminj"
                                    title="menu/admref?type=vlan"
                                    //js={toto.bind("admref?type=vlan")}
                                />
                                <NMItem
                                    key="admink"
                                    title="menu/admref?type=eqtype"
                                    //js={toto.bind("admref?type=eqtype")}
                                />
                                <NMItem
                                    key="adminl"
                                    title="menu/admref?type=eq"
                                    //js={toto.bind("admref?type=eq")}
                                />
                                <NMItem
                                    key="adminm"
                                    title="menu/admref?type=confcmd"
                                    //js={toto.bind("admref?type=confcmd")}
                                />
                                <NMItem
                                    key="adminn"
                                    title="menu/admref?type=dotattr"
                                    //js={toto.bind("admref?type=dotattr")}
                                />
                                <NMItem
                                    key="admino"
                                    title="menu/admgrp"
                                    //js={toto.bind("admgrp")}
                                />
                                <NMItem
                                    key="adminp"
                                    title="menu/admzgen"
                                    //js={toto.bind("admzgen")}
                                />
                                <NMItem
                                    key="adminq"
                                    title="menu/admpar"
                                    //js={toto.bind("admpar")}
                                />
                                <NMItem
                                    key="adminr"
                                    title="menu/statuser"
                                    //js={toto.bind("statuser")}
                                />
                                <NMItem
                                    key="admins"
                                    title="menu/statorg"
                                    //js={toto.bind("statorg")}
                                />
                            </NMDropdown>

                            <NMDropdown
                                key="pgadmin"
                                title="menu/auth"
                                show="pgadmin"
                            >
                                <NMItem
                                    key="pgadmin1"
                                    title="menu/pgaacc?action=list"
                                    js={toto.bind("pgaacc?action=list")}
                                />
                                <NMItem
                                    key="pgadmin2"
                                    title="menu/pgaacc?action=print"
                                    js={toto.bind("pgaacc?action=print")}
                                />
                                <NMItem
                                    key="pgadmin3"
                                    title="menu/pgaacc?action=add"
                                    js={toto.bind("pgaacc?action=add")}
                                />
                                <NMItem
                                    key="pgadmin4"
                                    title="menu/pgaacc?action=mod"
                                    js={toto.bind("pgaacc?action=mod")}
                                />
                                <NMItem
                                    key="pgadmin5"
                                    title="menu/pgaacc?action=del"
                                    js={toto.bind("pgaacc?action=del")}
                                />
                                <NMItem
                                    key="pgadmin6"
                                    title="menu/pgaacc?action=passwd"
                                    js={toto.bind("pgaacc?action=passwd")}
                                />
                                <NMItem
                                    key="pgadmin7"
                                    title="menu/pgarealm?action=list"
                                    js={toto.bind("pgarealm?action=list")}
                                />
                                <NMItem
                                    key="pgadmin8"
                                    title="menu/pgarealm?action=add"
                                    js={toto.bind("pgarealm?action=add")}
                                />
                                <NMItem
                                    key="pgadmin9"
                                    title="menu/pgarealm?action=mod"
                                    js={toto.bind("pgarealm?action=mod")}
                                />
                                <NMItem
                                    key="pgadmina"
                                    title="menu/pgarealm?action=del"
                                    js={toto.bind("pgarealm?action=del")}
                                />
                            </NMDropdown>

                            <li>
                                <form
                                    className={
                                        "form-inline my-1 my-lg-0" +
                                        showIf(cap, "logged")
                                    }
                                    role="search"
                                    action=""
                                    onSubmit={handleSearchForm}
                                    onChange={props.searchChange}
                                >
                                    <div className="input-group">
                                        <input
                                            className="form-control py-2"
                                            type="search"
                                            placeholder={intl.formatMessage({
                                                id: "menu/searchbox"
                                            })}
                                            aria-label="Search"
                                        />
                                        <span className="input-group-append">
                                            <button
                                                className="btn btn-outline-secondary border-left0 border"
                                                aria-label="Submit"
                                                type="button"
                                            >
                                                <i className="fas fa-search" />
                                            </button>
                                        </span>
                                    </div>
                                </form>
                            </li>
                        </ul>

                        <ul className="navbar-nav">
                            <li
                                className={cap["logged"] ? "d-none" : "show"}
                                key="notconnected"
                            >
                                <p
                                    className="navbar-text"
                                    data-toggle="modal"
                                    data-target="#loginform"
                                >
                                    <FormattedMessage id="menu/notconnected" />
                                </p>
                                <LoginForm modalid="loginform" />
                            </li>

                            <NMDropdown
                                key="user"
                                title={user == "" ? "???" : user}
                                translate={false}
                                show="logged"
                                align="right"
                                icon="fas fa-user"
                            >
                                <NMItem
                                    key="user1"
                                    title="menu/profile"
                                    js={toto.bind("profile")}
                                />
                                <NMItem
                                    key="user2"
                                    title="menu/sessions"
                                    js={toto.bind("sessions")}
                                />
                                <NMISep key="user3" show="admin" />
                                <NMItem
                                    key="user4"
                                    title="menu/sudo"
                                    js={toto.bind("sudo")}
                                    show="admin"
                                />
                                <NMItem
                                    key="user5"
                                    title="menu/sudoback"
                                    js={toto.bind("sudoback")}
                                    show="setuid"
                                />
                                <NMISep key="user6" />
                                <NMItem
                                    key="user7"
                                    title="menu/logout"
                                    js={disconnect}
                                />
                            </NMDropdown>

                            <NMDropdown
                                key="lang"
                                title="menu/curlang"
                                align="right"
                            >
                                <NMItem
                                    key="lang1"
                                    title="[en]"
                                    translate={false}
                                    js={changeLang.bind(this, "en")}
                                />
                                <NMItem
                                    key="lang2"
                                    title="[fr]"
                                    translate={false}
                                    js={changeLang.bind(this, "fr")}
                                />
                            </NMDropdown>
                        </ul>
                    </div>
                </nav>

                <Route path="*/netmagis/add" component={Add} />
                <Route path="*/netmagis/consult" component={Consult} />

                <Route exact={true} path="*/netmagis/" component={Welcome}/>
            </div>
        </Router>
    );
}

/*  Some basic components to demonstrate the usability of the routes*/
const Welcome = ({match}) => (
    <div>
        <p> Bienvenue ! </p>
    </div>
);

const Add = ({ match }) => (
    <div>
        <p> Add component </p>
    </div>
);

const Consult_ = ({ match }) => {

    return (
        <div>
            <h4> Consult component simple</h4>
        </div>
    );
}

const Consult = ({ match }) => {

    const queryString = require('query-string');
    const parsed = queryString.parse(location.search);
    console.log("N keys: " + Object.keys(parsed));

    return (
        <div>
            <h4> Consult component + args</h4>
            {
                Object.keys(parsed).length>0 ? (
                    <div>
                        {parsed.net ?
                                <p> Infos about <b>{parsed.net}</b> </p>
                                : <p>No network specified</p>
                        }
                    </div>

                )
                : ( <p> Generic page</p> )


            }

        </div>
    );
}



/*
class NMRouter extends React.Component {
    render() {
        switch (this.props.app) {
            case "index":
                if (this.context.nm.cap.logged) {
                    return (
                        <div>
                            {" "}
                            <p>here is the index</p>{" "}
                        </div>
                    );
                } else {
                    return <Login />;
                }
            case "search":
                return (
                    <div>
                        <p>Searching {this.props.p1}</p>
                    </div>
                );
            case "add":
                return <Add />;
            case "dhcprange":
                return <DHCPRange />;
            case "sessions":
                return <Sessions />;
            case "foo":
                return (
                    <div>
                        <p>Foo!</p>
                    </div>
                );
            default:
                return (
                    <div>
                        <p>Default</p>
                    </div>
                );
        }
    }
}

class NMRouterX extends React.Component {
    render() {
        return (
            <pre>
                this.props: {JSON.stringify(this.props)}
                this.state: {JSON.stringify(this.state)}
            </pre>
        );
    }
}
*/

export const NMMenu = injectIntl(withUser(RawNMMenu));
