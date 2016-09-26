import React from 'react' ;
import ReactDOM from 'react-dom' ;
import * as S from './nm-state.jsx' ;
import * as F from './bootstrap-lib/form-utils.jsx' ;
import * as C from './common.js' ;

export var Login = React.createClass ({
    // To enforce a rerendering on language change
    contextTypes: {nm: React.PropTypes.object},

    getInitialState: function () {
	return {message : "", color: ""} ;
    },

    signIn: function (event) {
	event.preventDefault () ;
	$.ajax ({
	    method: 'POST',
	    url: C.APIURL + '/sessions',
	    contentType: 'application/json',
	    data: JSON.stringify ({
		login: this.refs.username.value,
		password: this.refs.passwd.value
	    }),
	    success: function (response) { 
		this.setState ({message: response, color: "green"}) ;
		S.updateCap () ;
		// window.location = "welcome.html" ;
	    }.bind (this),
	    error: function (jqXHR) {
		this.setState ({message: jqXHR.responseText, color: "red"}) ;
	    }.bind (this)
	}) ;
    },

    render: function () {
	return (
	    <div>
	      <form className="form-horizontal"
		  role="form"
		  action=""
		  onSubmit={this.signIn}>
		<div className="form-group">
		  <label className="control-label col-sm-2" htmlFor="username">
		    {S.mc ('Username')}
		  </label>
		  <div className="col-sm-8">
		    <input type="text"
			className="form-control"
			id="username"
			ref="username"
			placeholder={S.mc ('Enter username')}
			/>
		  </div>
		</div>
		<div className="form-group">
		  <label className="control-label col-sm-2" htmlFor="passwd">
		    {S.mc ('Password')}
		  </label>
		  <div className="col-sm-8">
		    <input type="password"
		      className="form-control"
		      id="passwd"
		      ref="passwd"
		      placeholder={S.mc ('Enter password')}
		      />
		  </div>
		</div>
		<div className="form-group">
		  <div className="col-sm-offset-2 col-sm-8">
		    <button type="submit" className="btn btn-default">
		      {S.mc ('Sign in')}
		    </button>
		  </div>
		</div>
	      </form>
	      <p style={{color: this.state.color}}> {this.state.message} </p>
	    </div>
	) ;
    }
}) ;
