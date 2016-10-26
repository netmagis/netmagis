import React from 'react' ;
import ReactDOM from 'react-dom' ;
import * as S from './nm-state.jsx' ;
import * as C from './common.js' ;
import * as F from './bootstrap-lib/form-utils.jsx' ;
import {Prompters} from './bootstrap-lib/prompters.jsx' ;
import {Tabs, Pane} from './lib-tabs.jsx' ;

/**
 * This app provides the user with a series of tabs each of them supplying a
 * form/app related to the "add" operation.
 *
 * List of the panels:
 *	- Add_single: simple form to add a single host (default)
 *	- Add_multi: step-by-step style app to add multiple hosts
 *	- Add_alias: step-by-step style app to add multiple hosts
 */

export var Add = React.createClass ( {
    /* This will force a rerendering on language/capability change */
    contextTypes: {nm: React.PropTypes.object},

    render: function () {
	return (
	    <Tabs>
	      <Pane label={S.mc ('Add single host')} >
		  <AddSingle id="form-add-single" />
	      </Pane>
	      <Pane label={S.mc ('Add several hosts')} >
		  <AddMulti />
	      </Pane>
	      <Pane label={S.mc ('Add alias')} >
		  <AddAlias id="form-add-alias"/>
	      </Pane>
	    </Tabs>
	) ;
    }
}) ;


/* prop id required */
var AddSingle = React.createClass ({
    /* This will force a rerendering on language/capability change */
    contextTypes: {nm: React.PropTypes.object},

    propTypes: {id: React.PropTypes.string.isRequired},

    handleClick: function (event) {
	event.preventDefault () ;
	var elts = F.form2obj (this.props.id) ;
	alert ("submit " + JSON.stringify (elts)) ;
	if (this.props.submtCallback)
	    this.props.submtCallback (elts) ;
    },

    render: function () {
	var d = this.props.defaultValues || {} ;

	return (
	    <div>
	      <F.Form id={this.props.id}>
		<F.Row>
		  <F.InputAdrop label={S.mc ('Name')}
		      name ="name"
		      ddname="domain"
		      defaultValue={d ["name"]}
		      ddDef={d ["domain"]}
		      />
		  <F.Input label={S.mc ('TTL')}
		      name="ttl"
		      dims="2+1"
		      defaultValue={d ["ttl"]}
		      />
		</F.Row>
		<F.Row>
		  <F.Ainput label={S.mc ('IP address')}
		      name="addr"
		      defaultValue={d["addr"]}
		      />
		  <F.Dropdown label={S.mc ('View')}
		      name="view" defaultValue={d["view"]}
		      >
		    <el>external</el>
		    <el>internal</el>
		  </F.Dropdown>
		</F.Row>
		<F.Row>
		  <F.Input label={S.mc ('MAC address')} name="mac"/>
		  <F.Space dims="2" />
		  <F.Checkbox label={S.mc ('Use SMTP')}
		      name="smtp"
		      defaultChecked={d["smtp"]}
		      />
		</F.Row>
		<F.Row>
		  <F.Adropdown label={S.mc ('Host type')}
		      name="hinfos_present"
		      defaultValue={d["machines"]}
		      />
		</F.Row>
		<F.Row>
		  <F.Input label={S.mc ('Comment')} name="comment" />
		</F.Row>
		<F.Row>
		  <F.Input label={S.mc ('Responsible (name)')}
		      name="rname"
		      defaultValue={d["rname"]}
		      />
		  <F.Input label={S.mc ('Responsible (mail)')}
		      name="rmail"
		      defaultValue={d["rmail"]}
		      />
		</F.Row>
	      </F.Form>
	      <F.Row>
		<F.Space dims="5" />
		<F.Button dims="1" onClick={this.handleClick}>
		  {S.mc ('Add')}
		</F.Button>
	      </F.Row>
	    </div>
	) ;
    }
}) ;

var SelectBlock = React.createClass ({
    /* This will force a rerendering on language/capability change */
    contextTypes: {nm: React.PropTypes.object},

    getInitialState: function () {
	return { blocks: undefined} ;
    },

    handleSearch: function (event) {
	event.preventDefault () ;
	function update () {
	    this.setState ( {blocks: Prompters ['freeblocks'].getValues ()}) ;
	}
	var params = F.form2obj ('Search_block') ;
	Prompters ['freeblocks'].init (update.bind (this), params) ;
    },

    search_form: function () {
	return (
	    <F.Form id='Search_block'>
		<F.Row>
		    <F.InputXORdd label="Network"
		     name="cidr" defaultValue="Select one" />
		    <F.Input label="Address count" name="size" dims="1+1"/>
		    <F.Space dims="1" />
		    <F.Button name="_dontUse" dims="1" onClick={this.handleSearch}  >
			Search
		    </F.Button>
		</F.Row>
	    </F.Form>
	) ;
    },

    select_form: function () {
	if (! this.state.blocks)
	    return null ;

	function makeEl ({addr, size}, i) {
	    return (<el key={i+"elsf"}>
			{addr + " (size: " + size + ")"}
		    </el>
		) ;
	}

	function onSelect (event) {
	    event.preventDefault () ;
	    var value = $('#SelectBlock [name="block"]').text ().trim ().split (' ') [0] ;
	    this.props.onSelect (value) ;
	}

	return (
	    <F.Form id='SelectBlock'>
		<F.Row>
		    <F.Dropdown label="Block" name="block">
			{this.state.blocks.map (makeEl)}
		    </F.Dropdown>
		    <F.Space dims="1" />
		    <F.Button dims="1" onClick={onSelect.bind (this)}>
			Select
		    </F.Button>
		</F.Row>
	    </F.Form>
	) ;
    },

    render: function () {
	return (
	    <div>
		{this.search_form ()}
		{this.select_form ()}
	    </div>
	) ;
    }
}) ;


var AddMulti = React.createClass ( {
    /* This will force a rerendering on language/capability change */
    contextTypes: {nm: React.PropTypes.object},

    getInitialState: function () {
	return {contents: 0, defaultAddHost: {} } ;
    },

    handleSelect: function (value) {
	this.setState ( {contents: 1, defaultAddHost: {addr: value}}) ;
    },

    addNext: function (oldValues) {
	oldValues ["name"] = oldValues ["name"].replace (/[0-9][0-9]*$/,function (x) { return parseInt (x)+1 ; })
	oldValues ["addr"] = C.IPv4_intA_to_dotquadA (
				C.IPv4_dotquadA_to_intA (oldValues["addr"])+1
			    ) ;
	this.setState ({contents: 2, defaultAddHost: oldValues}) ;
    },

    componentDidUpdate: function () {
	if (this.state.contents == 2)
	    this.setState ({contents: 1}) ;
    },

    render: function () {
	switch (this.state.contents) {
	    case 0: return (
			<SelectBlock onSelect={this.handleSelect} />
		    ) ;
	    case 1: return (
			<Add_host id="Addblk_addh"
			     defaultValues={this.state.defaultAddHost}
			     submtCallback={this.addNext}
			     />
		    ) ;
	    case 2: return (<div></div>) ;	// Little hack to rerender
	}
    }
}) ;

var AddAlias = React.createClass ( {
    /* This will force a rerendering on language/capability change */
    contextTypes: {nm: React.PropTypes.object},

    propTypes: {id: React.PropTypes.string.isRequired},

    handleClick: function (event) {
	event.preventDefault () ;
	var elts = F.form2obj (this.props.id) ;
	alert ("submit " + JSON.stringify (elts)) ;
	if (this.props.submtCallback)
	    this.props.submtCallback (elts) ;
    },

    render: function () {
	var d = this.props.defaultValues || {} ;

	return (
	    <div>
	      <F.Form id={this.props.id}>
		<F.Row>
		  <F.InputAdrop label={S.mc ('Alias name')}
		      name ="name"
		      ddname="domain"
		      defaultValue={d ["name"]}
		      ddDef={d ["domain"]}
		      />
		</F.Row>
		<F.Row>
		  <F.InputAdrop label={S.mc ('Reference host')}
		      name ="nameref"
		      ddname="domain"
		      defaultValue={d ["name"]}
		      ddDef={d ["domain"]}
		      />
		</F.Row>
	      </F.Form>
	      <F.Row>
		<F.Space dims="5" />
		<F.Button dims="1" onClick={this.handleClick}>
		  {S.mc ('Add')}
		</F.Button>
	      </F.Row>
	    </div>
	) ;
    }
}) ;
