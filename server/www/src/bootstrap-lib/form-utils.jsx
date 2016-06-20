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
 *
 * @warning: <el>{ my_var }</el> Ok! 
 * 	     <el> { my_var } </el> Avoid it! 
 *	  Apparently in the latter case React generates an array of 3 elements
 *	  with leading and trailing white spaces strings. This works still fine
 *	  for the rendering but could cause some problem when the value 
 *	  must be retrieved using .val() 
 *				 
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
			if ( this.state.value == undefined) {
				
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
			var newValue = child.props.children;//[1];	// <el> ... </el> generates trailing and leading empty strings
			this.setState({value: newValue});
			if (this.props.onChange) this.props.onChange(newValue);
			
	},


	/* Creates an element of the dropdown containing the text inside
	   the given child (so make sure the child contains only text) */
	makeOption: function(child, index){
			return (
				<li key={"dopt"+index}>
					<a href="#" onClick={this.handleClick.bind(this,child)} >
	 				{/*<el> ... </el> generates trailing and leading empty strings */}
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
			return (<el key={"ajd"+index} >{val}</el>); 
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
 * Creates an input and a dropdown (the latter preceded by a 'or' label), where
 * only the last used can contain a value.
 * @properties:
 *	-label: Content of the label preceding the input field and the dropdown
 *	-defaultValue: default value of the dropdown
 *	-iname, dname: names of input field and dropdown (XXX should I use only one name prop and update an hidden input with the good value? )
 *	-placeholder:  placeholder attribute of the input field
 */

export var InputXORdd = React.createClass({
	
        contextTypes : {lang: React.PropTypes.string},

	getInitialState: function(){
		// state: { input value , dropdown value }
		return {Ivalue: "", Dvalue: undefined };
	},

	/* An AJXdropdown has a name prop */
	propTypes: { name: React.PropTypes.string.isRequired },	

	/* Update input when the user types */
	handleChange: function(event) {
		event.preventDefault();
		this.setState({Ivalue: event.target.value });
	},

	/* Select dropdown value */	
	ddChange: function() {
		this.setState({Ivalue: "", Dvalue: undefined});
	},

	/* User leaves the input */
	onBlur: function(event) {
		event.preventDefault();
		this.setState({Dvalue: this.props.defaultValue || ""});
		
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
					<Adropdown label="or" onChange={this.ddChange} value={this.state.Dvalue}
					 name={this.props.name} defaultValue={this.props.defaultValue}  />
				</div>
			</div>
		);
	}

});




/**
 * Returns an object all the values of the form with the given id. The
 * keys are the name attributes of the fields of the form 
 */
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







/* Div <--> Input (prop edit) 
 * Editable input field 
 */
var InEdit = React.createClass({

	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},

	getInitialState: function(){
		return { value: this.props.children }
	},
	componentWillReceiveProps: function(newProps){
		//this.setState({ value: newProps.children });
		
	},
	/* As this is controlled Update the state with the new value */
	onChange: function (event) {
		this.setState({value: event.target.value});
	},

	render: function(){
		if (this.props.edit === true) {
			return (<input value={this.state.value} style={{width: "100%"}}
				 onChange={this.onChange} name={this.props.name} />
			);
		} else {
			return (<div> {this.state.value} </div>);
		}
	}
});

/* 
 * Editable dropdown
 * props:
 *	-values: either a list either an object containing an attribute values (a list) and an attribute value (default value)
 */
var DdEdit = React.createClass({

	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},

	getInitialState: function(){
		if (Array.isArray(this.props.values)) {

			return { value: this.props.values[0],
				 values: this.props.values
			       };
		} else {

			return { value: this.props.values.value,
				 values: this.props.values.values
			       }
		}
	},

	/* As this is controlled Update the state with the new value */
	onChange: function (newValue) {
		this.setState({	value: newValue });
	},

	makeOption: function (val, index){
		return (<el>{val}</el>);
	},

	render: function(){
		if (this.props.edit === true) {
			return (<Dropdown_internal superClass="dropdown" 
				 onChange={this.onChange} value={this.state.value}
				 name={this.props.name}  >
					{this.state.values.map(this.makeOption)}
				</Dropdown_internal>
			);
		} else {
			return (<div > {this.state.value} </div>);
		}
	}
});


















/**
 * An editable table's row, allows the user to edit the values
 * and/or save/remove the row.
 * @properties:
 *	-model, contains the descriptionof the data contained into
 *		the row (see the component EdiTable)
 *		(ex: {key: ... , desc: [ ["field" , "type", "name"], ... ]} )
 *	-data,  an object containing a certain number of "name": "value" pairs,
 *		where "name" correspond to one of the names specified on the model.
 *	 	If the type specified on the model is "input" and the data for this
 *		field is not specified then it will be an empty string by default. 
 *		The data of other types (!= "input") must always be specified.
 *	TODO complete
 *	-onRemove
 *	-onSave
 *	-on...
 */
var Editable_tr = React.createClass({

	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},

	getInitialState: function(){
		return { edit: this.props.edit || false };
	},


	/**
	 * Used by this.renderChild to render the correct
	 * child depending the description on the model
	 * @param desc, description specified into the model property
	 * @param content, the content of the child to render
	 */
	renderType: function (desc, content){
		switch ( desc[1].toLowerCase() ) {

			case "input" :
				return (
					<InEdit edit={this.state.edit}
						name={desc[2]}
					>
						{content}
					</InEdit>
				);

			case "dropdown":
				return (
					<DdEdit edit={this.state.edit} 
						values={content}
						name={desc[2]}
					/>
				);
				
			default: return (<div> {content} </div>);
		}
				
				
	},


	/**
         * Render one element of the row (child)
         * @param desc, the description of the element 
	 * 	   defined into the model props
	 * @param index, number of the child (usually passed directly by .map())
	 */
	renderChild: function (desc, index) {

		var content = this.props.data[desc[2]];

		return (
			<td key={"edr"+index} className="col-md-1" > 
				{this.renderType(desc, content)}
			</td>
		);
			
	},



	collectValues: function(){
		var data = {};
		for (var i = 0; i < this.props.model.desc.length; i++){
			var name = this.props.model.desc[i][2];
			// Use the id specified into the render in order to identify the row
			data[name] = $("#etr"+this.props.reactKey+" [name='"+name+"']").val();
		}
		var uniquekey = this.props.data[this.props.model.key];
		return {key:  uniquekey, data: data };
	},
			
	/* Active/desactive edit mode */	
	switchMode: function(){

		if (this.state.edit == true){
			var data = this.collectValues();

			if (data.key.toString().startsWith("__")) { // Invalid api id (given from the application)
				this.props.handler.saveNewRow(data);
			} else {
				this.props.handler.updateRow(data);
			}
		}

		this.setState({ edit: !this.state.edit });
	},

	/* Called when the user remove this row */
	deleteRow: function(){
		// XXX do stuffs here
		var data = this.collectValues();
		if (this.state.edit == false) {
			this.props.handler.deleteRow(data);
			this.props.onRemove(this.props.index);
		} else if (data.key.toString().startsWith("__")) { // Invalid api id (given from the application)
			this.props.onRemove(this.props.index);
		} else {
			this.setState({ edit: !this.state.edit });
		}
	},
	
	render: function(){
		return (
			<tr id={"etr"+this.props.reactKey} >
				{this.props.model.desc.map(this.renderChild)}
				<td className="outside">
					<Button onClick={this.switchMode}>
						{ this.state.edit ? "Save" : "Edit" }
					</Button>
					<Button onClick={this.deleteRow}>
						{ this.state.edit ? "Cancell" : "Remove" }
					</Button>
				</td>
			</tr>
		);
	}
});


/* props: model [ ["field" , "type", "name"], ... ]
 * name: prompter
 */
var Table = React.createClass({

	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},

	/* has a name prop */
	propTypes: { name: React.PropTypes.string.isRequired },	

	getInitialState: function (){ return {values : [] }; },

	getValues: function(){
		this.setState({values: Prompters[this.props.name].getValues()})
	},


	componentWillMount: function () {
		var prompter = Prompters[this.props.name];

		if (!prompter) {
			console.error(this.props.name+" is not a prompter!");

		} else if (prompter.init) {
			prompter.init(this.getValues.bind(this));
			
		}
	},

	renderHead: function(){
		function headerEl(mod,index){ return (<th key={"th"+index}> {mod[0]} </th>);}
		return (
			<thead>
				<tr>
				{this.props.model.desc.map(headerEl)}
				</tr>
			</thead>
		);
	},

	renderRow: function (data , index){

		var uniqkey = data[this.props.model.key];

		return ( <Editable_tr key={"trw"+uniqkey}
				      reactKey={"trw"+uniqkey}
				      model={this.props.model} 
				      data={data}
				      edit={data._edit}
				      index={index}
				      onRemove={this.removeRow}
				      handler={Prompters[this.props.name]}
			/>
		);

	},
	
	removeRow: function (index) {
		this.state.values.splice(index,1);
		this.setState({values: this.state.values});
	},

	emptyRowsCount: 0, // Used to define unique keys when adding empty rows

	addRow: function (){

		var newRow = { _edit: true }; // Add in edit mode
			
		if (this.state.values.length > 0){	

			/* Use the first row as example */
			newRow = $.extend(newRow,this.state.values[0]);
		
			for (var i = 0; i < this.props.model.desc.length; i++){
				/* Leave inputs blanks */
				var type = this.props.model.desc[i][1];
				if ( type.toLowerCase() == "input"){
					var field = this.props.model.desc[i][2];
					newRow[field] = "";
				}
			}

		} else if (Prompters[this.props.name].getEmptyRow) {
			/* Ask for an empty row to the prompter */
			var emptyRow = Prompters[this.props.name].getEmptyRow();
			newRow = $.extend(newRow,emptyRow);

		} else {
			console.error("Cannot fetch an the values of an empty row");
			return;
		}

		// Set an unique key
		newRow[this.props.model.key] = "___NotValidId"+this.emptyRowsCount++;

		// Add to the state	
		this.state.values.push(newRow);
		this.setState({ values: this.state.values });
		
	},

	render: function(){
		return (
			<div>
				<table className="table table-bordered">
					{this.renderHead()}
					<tbody>
						{this.state.values.map(this.renderRow)}
					</tbody>
				</table>
				<Button onClick={this.addRow}>
					Button
				</Button>
			</div>
		);
	}
});
