import React from 'react' ;
import ReactDOM from 'react-dom' ;
import * as S from './nm-state.jsx' ;
import * as C from './common.js' ;
import {Tabs, Pane} from './lib-tabs.jsx' ;

export var Sessions = React.createClass ({
    // To enforce a rerendering on language change
    contextTypes: {nm: React.PropTypes.object},

    render: function () {
	return (
	      <Tabs>
		<Pane label={S.mc ('Active sessions')}>
		  <SessionsActive />
		</Pane>
		<Pane label={S.mc ('Expired sessions')}>
		  <SessionsExpired />
		</Pane>
		<Pane label={S.mc ('API keys')}>
		  <SessionsAPI />
		</Pane>
	      </Tabs>
	    ) ;
    }
}) ;

var SessionsActive = React.createClass ({
    // To enforce a rerendering on language change
    contextTypes: {nm: React.PropTypes.object},

    model: {
	key: "sessions",
	desc: [
	    [ "Address", "Input",  "ip" ],
	]
    },


    render: function () {
	return ( <span>active</span> ) ;
    }

}) ;

var SessionsExpired = React.createClass ({
    // To enforce a rerendering on language change
    contextTypes: {nm: React.PropTypes.object},

    render: function () {
	return ( <span>expired</span> ) ;
    }

}) ;

var SessionsAPI = React.createClass ({
    // To enforce a rerendering on language change
    contextTypes: {nm: React.PropTypes.object},

    render: function () {
	return ( <span>api</span> ) ;
    }

}) ;
