import React from 'react';
import ReactDOM from 'react-dom';
import {translate} from '../lang.jsx';
import Autosuggest from 'react-autosuggest';
import {Prompters} from './prompters.jsx';



/** 
 * Creates an uncontrolled Bootstrap-like input field preceded by a label.
 * Every property passed to this object is passed to the input field.
 *
 * @properties:
 *	-label: defines the contents of the label (required) //TODO make it optional
 *	-dims : defines the dimensions of this component following the
 *		Bootstrap grid system. Use the following syntax: "x+y"
 *		where x is the space reserved for the label and y is the
 *		space reserved for the input field.
 *	  
 * @note:  to fill the input with a default value use the React-specific prop 
 *	   'defaultValue' and not the prop 'value'.
 *	    more infos: https://facebook.github.io/react/docs/forms.html#uncontrolled-components
 */

export var Input = React.createClass({
	
 	contextTypes : {lang: React.PropTypes.string},
	
	render: function(){
		
		/* The default value of dims is "2+3" */
		var grid_vals = this.props.dims ? 
			this.props.dims.split('+') : ['2','3'];
			
		return (
			<div>
				<label className={"control-label col-md-"+grid_vals[0]}>
				{translate(this.props.label)}
				</label>
				<div className={"col-md-"+grid_vals[1]}>
					<input {...this.props} className="form-control" />
				</div>
			</div>
		);
		
	}

});





/**
 * Same as Input but uses the component AutoInput to perform live-suggestions.
 * Use the html attribute 'name' to link this component the correct
 * handler contained inside the object Propmters.
 *
 * @properties: (same as Input)
 * @see Input, AutoInput
 */

export var Ainput = React.createClass({
	
 	contextTypes : {lang: React.PropTypes.string},
	
	render: function(){
		var grid_vals = this.props.dims ? 
			this.props.dims.split('+') : ['2','3'];
			
		return (
			<div>
				<label className={"control-label col-md-"+grid_vals[0]}>
				{translate(this.props.label)}
				</label>
				<div className={"col-md-"+grid_vals[1]}>
					<AutoInput {...this.props} className="form-control" />
				</div>
			</div>
		);
		
	}

});


/**
 * Simple Bootstrap-like button. Every property passed to this button is 
 * passed as an attribute to the html button node. 
 * Use this component as a normal button to wrap some text.
 *
 * @properties:
 *	-dims : space reserved to the button following the Bootstrap grid system
 *		(ex. dims="3")
 *	
 * @prec this component should have only text as a child
 */
export var Button = React.createClass({
	
 	contextTypes : {lang: React.PropTypes.string},
	
	render: function(){

		/* By default dims="2" */
		var grid_val = this.props.dims ? 
			this.props.dims : '2';

		return (
			<button className={"btn btn-default col-md-"+grid_val} 
			 {...this.props} >
				{translate(this.props.children)}
			</button>
		);
	}

});



/**
 * This component creates a simple bootstrap-like dropdown using the 
 * contents of the children as list element. The children can contain only
 * text. You can use whatever html tag to indicate the children (by convention
 * I suggest you to use the tag <el> </el> as it is short and descriptive).
 * All the properties passed to theis component are passed directly to the
 * button element as attributes
 *
 * @properties:
 *	-superClass: Is the same of className but it will affect the whole
 *		     component and not only the internal button
 *	-defaultValue: force the initial value
 *	-value: force the value
 * 
 * Example of use:
 *	<Dropdown_internal superClass="beautiful_dropdown" >
 *		<el> element 1 </el> 
 *		<el> element 2 </el> 
 *		<el> element 3 </el> 
 * 	</Dropdown_internal>
 */
export var Dropdown_internal = React.createClass({ /*TODO change name */


 	contextTypes : {lang: React.PropTypes.string},


	/* The state contains an attribute value which indicate
	   the current (selected) contents of the dropdown */

	getInitialState: function(){
	
		/* If defaultValue is defined use it as initial
 		   value, otherwise use the contents of the first
		   child */	

		if (this.props.defaultValue != undefined ) 
			return {value: this.props.defaultValue};
		
		else if (this.props.value != undefined ) 
			return {value: this.props.value};

		else if (this.props.children.length > 0 )
			return {value: this.props.children[0].props.children};

		else
			return {value: undefined};
		
	},



	/* At every update if possible use the props value as state or the 
	   contents of the first child as value if the value is not defined 
	   or there are new children (see filter dropdown)  */

	componentWillReceiveProps: function(newprops) {
		
		if (newprops.value != undefined )
				this.setState({value: newprops.value });	

		else if (newprops.children.length > 0) {
			if ( this.state.value == undefined /*|| 
			     this.props.children != newprops.children*/){ //TODO FIX
				
				this.setState(
					{value: newprops.children[0].props.children}
				);
			}
		}
	},

	
	
	/* Set the contents of the child that has been clicked as value 
	   and execute the onChange callback */
	handleClick: function(child, event){
			event.preventDefault();
			this.setState({value: child.props.children});
			if (this.props.onChange) this.props.onChange();
			
	},


	/* Creates an element of the dropdown containing the text inside
	   the given child (so make sure the child contains only text) */
	makeOption: function(child, index){
			return (
				<li key={"dopt"+index}>
					<a href="#" onClick={this.handleClick.bind(this,child)} >
					{translate(child.props.children)}
					</a>
				</li>
			);
	},


	/* Main render */
	render: function(){

		return (
			<div className={this.props.superClass}>
				<button className="btn btn-default dropdown-toggle" 
				 type="button"  data-toggle="dropdown" aria-haspopup="true"
				 aria-expanded="true" {...this.props} >
					{translate(this.state.value)}
					<span className="caret"></span>
				</button>
				<ul className="dropdown-menu" >
					{this.props.children.map(this.makeOption)}
				</ul>
			</div>
		);
	}
});









/**
 * Creates a Bootstrap-like dropdown which element will be charged
 * automatically trough async ajax request using the proper hanlder.
 *
 * @properties: same as Dropdown_internal, plus
 *	-name: defines the name of the handler
 * 
 * Example of use:
 *	 <AJXdropdown name="foods" superClass="foodSelector" />
 *	
 */
export var AJXdropdown = React.createClass({
	
        contextTypes : {lang: React.PropTypes.string},


	/* An AJXdropdown has a name prop */
	propTypes: { name: React.PropTypes.string.isRequired },	

	componentWillMount: function () {
		var prompter = Prompters[this.props.name];

		if (!prompter) {
			console.error(this.props.name+" is not a prompter!");

		} else if (prompter.init) {
			prompter.init(function(){this.forceUpdate();}.bind(this));
			
		}
	},

	render: function(){
		var values = Prompters[this.props.name].getValues();

		function makeElement(val, index) { 
			return (<el key={"ajd"+index} > {val} </el>); 
		}
		
		return (
			<Dropdown_internal {...this.props}  >
				{values.map(makeElement)}
			</ Dropdown_internal>
		);
	}


});














/**
 * Creates a Bootstrap-like dropdown preceded by a label.
 * For more infos see Dropdown_internal.
 * 
 * @properties: sames ad Dropdown_internal, plus
 *	-label: The contents of the label preceding the dropdown
 *	-dims : Dimensions following bootstrap's grid system (see Input)
 *
 * Example of use: 
 *	<Dropdown dims="2+2" label="Select an animal" />
 *		<el> Lyon </el>
 *		<el> Fox  </el>
 *		<el> Dog  </el>
 * 	</Dropdown>
 */
export var Dropdown = React.createClass({

 	contextTypes : {lang: React.PropTypes.string},

	render: function(){

		var grid_vals = this.props.dims ? 
			this.props.dims.split('+') : ['2','3'];

		return (
			<div>
				<label className={"control-label col-md-"+grid_vals[0]}>
				{translate(this.props.label)}
				</label>
				<div className={"dropdown col-md-"+grid_vals[1]}>
					<Dropdown_internal {...this.props} />
				</div>
			</div>
		);
	}
});










/**
 * Same as Dropdown but with a list of elements charged trough 
 * async AJAX call (see AJXdropdown).
 * 
 * @properties:
 *	-label: The contents of the label preceding the dropdown
 *	-dims : Dimensions following bootstrap's grid system (see Input)
 *	-name : Name of the handler (see AJXdropdown)
 *
 * Example of use:
 * 	<Adropdown name="animals" label="Select an animal" dims="3+2" />
 */
export var Adropdown = React.createClass({

 	contextTypes : {lang: React.PropTypes.string},

	render: function(){

		var grid_vals = this.props.dims ? 
			this.props.dims.split('+') : ['2','3'];

		return (
			<div>
				<label className={"control-label col-md-"+grid_vals[0]}>
				{translate(this.props.label)}
				</label>
				<div className={"dropdown col-md-"+grid_vals[1]}>
					<AJXdropdown {...this.props} />
				</div>
			</div>
		);
	}
});




/**
 * Creates an input field which ends with a dropdown, everything preceded
 * by a label. All the properties are passed directly as attributes of the 
 * input field. For more infos see Input and Dropdown_internal.
 *
 * @properties:
 *	-label: The contents of the label preceding the dropdown
 *	-dims : Dimensions following bootstrap's grid system (see Input)
 *	-ddname:  The attribute name to pass to the dropdown
 *	-ddDef: The default value of the dropdown
 * 
 * Example of use:
 *	<Inputdrop label="Create your e-mail" ddname="availableDomains" ddDef="Select a domain">
 *		<el> @toto.fr </el>
 *		<el> @truc.eu </el>
 *		<el> @foo.com </el>
 *	</Inputdrop>
 */

export var Inputdrop = React.createClass({

 	contextTypes : {lang: React.PropTypes.string},

	render: function(){

		var grid_vals = this.props.dims ? 
			this.props.dims.split('+') : ['2','3'];

		/* Make a copy of the props without the children */
		var props = {};
		$.extend(props,this.props);
		props.children = null;

		return (
			<div>
				<label className={"control-label col-md-"+grid_vals[0]}>
				{translate(this.props.label)}
				</label>
				<div className={"input-group col-md-"+grid_vals[1]}
				     style={{"paddingLeft": "15px", "float": "left"}} >
					<input className="form-control" {...props} />
					<Dropdown_internal name={this.props.ddname} defaultValue={this.props.ddDef}
					 superClass="input-group-btn" >
						{this.props.children}
					</Dropdown_internal>
				</div>
			</div>
		);
	}

});



/**
 * Same as Inputdrop but with a list of elements charged trough 
 * async AJAX call (see AJXdropdown).
 */

export var InputAdrop = React.createClass({

 	contextTypes : {lang: React.PropTypes.string},

	render: function(){

		var grid_vals = this.props.dims ? 
			this.props.dims.split('+') : ['2','3'];

		/* Make a copy of the props without the children */
		var props = {};
		$.extend(props,this.props);
		props.children = null;

		return (
			<div>
				<label className={"control-label col-md-"+grid_vals[0]}>
				{translate(this.props.label)}
				</label>
				<div className={"input-group col-md-"+grid_vals[1]}
				     style={{"paddingLeft": "15px", "float": "left"}} >
					<input className="form-control" {...props} />
					<AJXdropdown name={this.props.ddname} defaultValue={this.props.ddDef}
					  superClass="input-group-btn" />
				</div>
			</div>
		);
	}

});

/**
 * Creates a Bootstrap-like checkbox followed by a label
 * All the properties passed to this component will be
 * passed as attributes of the checkbox.
 *
 * @properties: 
 *	-label: The contents of the label following the checkbox
 *	-dims : Dimensions following bootstrap's grid system (see Input)
 * 
 * Example of use:
 *	<Checkbox name="colors" label="Print with colors" dims="3" />
 */
export var Checkbox = React.createClass({
	
 	contextTypes : {lang: React.PropTypes.string},

	render: function(){

		var grid_val = this.props.dims ? 
			this.props.dims : '2';

		return (
			<div className={"checkbox col-md-"+grid_val}>
				<label>
					<input type="checkbox" {...this.props} /> 
					{translate(this.props.label)}
				</label>
  			</div>
		);
	}
});


/**
 * This component occupies empty space on the grid system.
 * Use it to align the other components if necessary 
 * 
 * @properties: 
 *	-dims : Dimensions following bootstrap's grid system (see Input)
 */
export var Space = React.createClass({

	render: function(){
		var grid_val = this.props.dims ? 
			this.props.dims : '1';

		return (
			<div className={"col-md-"+grid_val} />
		);
	}

});



/**
 * Use this component to wrap other elements if you want them to be
 * on the same row.
 *
 * Example of use:
 *	   <Row>
 *		<Input (input props....)  />
 *		<Dropdown (dropdown props....)>  
 *			<el> Element 1 </el>
 *			<el> Element 2 </el>
 *		</Dropdown>
 *	   </Row>
 */

export var Row = React.createClass({

	contextTypes : {lang: React.PropTypes.string},

	render: function(){

		return (
			<div className="form-group row">
				{this.props.children}
			</div>
		);
	}

});


/**
 * Creates a form. The properties passed to this component are passed
 * automatically as attributes of the html element <form>
 * Use it to wrap the other components when creating a form.
 */
export var Form = React.createClass({
	
 	contextTypes : {lang: React.PropTypes.string},

	render: function(){
		return (
			<form className="form-horizontal" role="form"
			 {...this.props} >
				{this.props.children}
			</form>
		);
	}
	
});




/**
 * Use this component to generate an input field with automatic suggestions.
 * Note that all the properties of AutoInput will be passed to the imput field.
 * AutoInput must have a `name` property and it's value must correspond
 * with the name of an handler contained inside the Prompters (see above).
 * 
 * Example of use:
 *
 *	ReactDOM.render(
 *		<AutoInput placeholder="Insert a network address" name="cidr" 
 *		   className="myclassname" style={{width: "30%"}} />, 
 *		document.getElementById('app')
 * 	);
 */
export var AutoInput = React.createClass({


	/* The state contains the current value of the input
	   and an array of suggestions (output of getSuggestions)*/
	getInitialState: function(){
		return { value: this.props.defaultValue || '', suggestions: [] };
	},




	/* An AutoInput element must have a name prop */
	propTypes: { name: React.PropTypes.string.isRequired },	



	/* At the very beginning call check for the existens of the
	   prompter and call his init function if it's defined */
	componentWillMount: function () {
		var prompter = Prompters[this.props.name];

		if (!prompter) {
			console.error(this.props.name+" is not a prompter!");

		} else if (prompter.init) {
			prompter.init();
			
		}
	},

	/* Use the function getSuggestions defined by the prompter
	   to get the actual suggestions from the current value */
	getSuggestions: function (value) {
		return Prompters[this.props.name].getSuggestions(value);
	},



	/* In this component we consider suggestions to always be strings,
	   this function tells Autosuggest how to map the suggestion to 
	   the input value when the first is selected */
	getSuggestionValue:(suggestions) => suggestions,



	/* As this is controlled Update the state with the new value */
	onChange: function (event, {newValue}) {
		this.setState({value: newValue});
	},

	/* */
	onSuggestionsUpdateRequested: function ({value}) {
		this.setState({suggestions: this.getSuggestions(value)});
	},


	/* Suggestions are rendered wrapping them in a <span> element */
	renderSuggestion: (suggestion) => (<span>{suggestion}</span>),

	
	/* Main render */
	render: function () {

		/* Pass the value and the onChange function to the
		   input. So it will work as a controlled component */
		var inputProps = {
			value : this.state.value,
			onChange : this.onChange
		};

		/* Copy all the properties of AutoInput in order to
		   pass them to Autosuggest */
		$.extend(inputProps, this.props);

		return ( 
			<Autosuggest 
			suggestions = {this.state.suggestions} 
			onSuggestionsUpdateRequested = {this.onSuggestionsUpdateRequested}
			getSuggestionValue = {this.getSuggestionValue}
			renderSuggestion = {this.renderSuggestion}
			inputProps = {inputProps}
			/>
		);
	}
});








/**
 * Generates a dropdown which elements are charged dinamically trough ajax
 * requestm, preceded by an imput field that can be use to filter out the
 * elements of the dropdown. Everything is preceded by a label.
 * 
 * FIXME when all the elements are filtered out the dropdown keeps
 * the previous value.
 *
 * @properties: 
 *	-name : Name of the handler (see AJXdropdown)
 *	-label: Contents of the label preceding the input field and the dropdown
 *	-dims : Dimensions following bootstrap's grid system (see Input)
 * Example of use:
 *	  <FilteredDd name="contacts" label="select a contact" dims="3+2+1" />
 */

export var FilteredDd = React.createClass({
	
        contextTypes : {lang: React.PropTypes.string},

	getInitialState: function(){
		return {value: ""};
	},


	/* An AJXdropdown has a name prop */
	propTypes: { name: React.PropTypes.string.isRequired },	

	componentWillMount: function () {
		var prompter = Prompters[this.props.name];

		if (!prompter) {
			console.error(this.props.name+" is not a prompter!");

		} else if (prompter.init) {
			prompter.init(function(){this.forceUpdate();}.bind(this));
			
		}
	},
	handleChange: function(event) {
		this.setState({value: event.target.value});
	},
	
	getValues: function(){
		var values = Prompters[this.props.name].getValues();
		var inputValue = this.state.value.trim().toLowerCase();
		var inputLength = inputValue.length;

		if (inputLength === 0) return values;

		return values.filter(function (val) {
	    		return val.toLowerCase().slice(0, inputLength) === inputValue;
		 });
		
	},

	render: function(){

		var values = this.getValues();

		var grid_vals = this.props.dims ? 
			this.props.dims.split('+') : ['2','2','2'];

		function makeElement(val, index) { 
			return (<el key={"ajd"+index} > {val} </el>); 
		}
		
		return (
			<div>
				<label className={"control-label col-md-"+grid_vals[0]}>
				{translate(this.props.label)}
				</label>
				<div className={"col-md-"+grid_vals[1]}>
					<input className="form-control" value={this.state.value} onChange={this.handleChange} />
				</div>
				<div className={"dropdown col-md-"+grid_vals[2]}>
					<Dropdown_internal {...this.props}  >
						{values.map(makeElement)}
					</ Dropdown_internal>
				</div>
			</div>
		);
	}

});




/**
 * @properties:
 *	-label:
 *	-defaultValue:
 *	-iname, dname:
 *	-placeholder:
 */

export var InputXORdd = React.createClass({
	
        contextTypes : {lang: React.PropTypes.string},

	getInitialState: function(){
		return {Ivalue: "", Dvalue: undefined };
	},

	/* An AJXdropdown has a name prop */
	propTypes: { name: React.PropTypes.string.isRequired },	

	handleChange: function(event) {
		event.preventDefault();
		this.setState({Ivalue: event.target.value });
	},
	
	ddChange: function() {
		this.setState({Ivalue: "", Dvalue: undefined});
	},

	onBlur: function(event) {
		event.preventDefault();
		this.setState({Dvalue: ""});
		
	},
	
	render: function(){


		var grid_vals = this.props.dims ? 
			this.props.dims.split('+') : ['2','2','2'];

		
		return (
			<div>
				<label className={"control-label col-md-"+grid_vals[0]}>
				{translate(this.props.label)}
				</label>
				<div className={"col-md-"+grid_vals[1]}>
					<input className="form-control" value={this.state.Ivalue} 
					 onChange={this.handleChange} onBlur={this.onBlur}
					 name={this.props.name}  placeholder={this.props.placeholder} />
				</div>
				<div className={"dropdown col-md-"+grid_vals[2]}>
					<AJXdropdown onChange={this.ddChange} value={this.state.Dvalue}
					 name={this.props.name} defaultValue={this.props.defaultValue}  />
				</div>
			</div>
		);
	}

});





export function form2obj(id){
	var elements = document.getElementById(id).elements;
	
	var obj = {};

	for (var i = 0; i < elements.length; i++){
		
		var value;	
		var el = elements[i];
		var tag = el.tagName.toLowerCase();

		switch (tag) {
			
			case "input":	if (el.type.toLowerCase() == "text")
						value = el.value;
					else if (el.type.toLowerCase() == "checkbox")
						value = el.checked;
				break;

			case "button": value = el.textContent;
			
		}
		
		obj[elements[i].name] = value;
	}

	return obj;
}
