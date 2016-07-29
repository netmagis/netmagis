import React from 'react' ;
import ReactDOM from 'react-dom' ;
import {Translator, translate, updateTranslations} from './lang.jsx' ;
import * as F from './bootstrap-lib/form-utils.jsx' ;
import {TopMenu} from './top-menu.jsx' ;

/*
 * The input fields can be not defined ---> they will be rendered as empty
 */

var App = React.createClass({
    /* This will force a rerendering on language change */
    contextTypes: {lang: React.PropTypes.string},

    getInitialState: function () {
	return {cidr: ""};
    },

    model: {
	key: "iddhcprange",
	desc: [
	    [ "Min",			"Input",	"min"],
	    [ "Max",			"Input",	"max"],
	    [ "Domain",			"Dropdown",	"domain"],
	    [ "Default lease duration",	"Input",	"default_lease_time"],
	    [ "Maximum lease duration",	"Input",	"max_lease_time"],
	    [ "DHCP profile",		"Dropdown",	"dhcpprof"]
	]
    },

    changeNetwork: function (cidr) {
	this.setState ({cidr: cidr})
    },

    render: function () {
	var r ;

	if (this.state.cidr == "") {
	    r = (
		  <span>
		    {translate ('Select network first')}
		  </span>
		) ;
	} else {
	    r = (
		  <F.Table model={this.model}
		      name="row_dhcprange"
		      params={{cidr: this.state.cidr}}
		  />
		) ;
	}
	return (
	    <div>
		<F.Form>
		    <F.Adropdown name="cidr"
			onChange={this.changeNetwork}
			label={translate ('Select network')}
			defaultValue="Unspecified"
			/>
		</F.Form>
		{r}
	    </div>
	);
    }
}) ;

/* Render the app on the element with id #app */
var dom_node = document.getElementById ('app') ;
/* ReactDOM.render (<App />, dom_node) ; */
ReactDOM.render (<TopMenu><App /></TopMenu>, dom_node) ;
