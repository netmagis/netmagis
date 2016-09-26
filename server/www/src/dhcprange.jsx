import React from 'react' ;
import ReactDOM from 'react-dom' ;
import * as S from './nm-state.jsx' ;
import * as F from './bootstrap-lib/form-utils.jsx' ;
// import {TopMenu} from './top-menu.jsx' ;

/*
 * The input fields can be not defined ---> they will be rendered as empty
 */

export var DHCPRange = React.createClass({
    /* This will force a rerendering on language/capability change */
    contextTypes: {nm: React.PropTypes.object},

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
	var table = "" ;

	if (this.state.cidr != "") {
	    table = (
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
			label={S.mc ('Select network')}
			defaultValue="Unspecified"
			/>
		</F.Form>
		{table}
	    </div>
	);
    }
}) ;
