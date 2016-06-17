import React from 'react';
import ReactDOM from 'react-dom';
import {Translator, updateTranslations} from './lang.jsx';
import * as F from './bootstrap-lib/form-utils.jsx';
import {Prompters} from  './bootstrap-lib/prompters.jsx';

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
			return (<F.Dropdown_internal superClass="dropdown" 
				 onChange={this.onChange} value={this.state.value}
				 name={this.props.name}  >
					{this.state.values.map(this.makeOption)}
				</F.Dropdown_internal>
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
					<F.Button onClick={this.switchMode}>
						{ this.state.edit ? "Save" : "Edit" }
					</F.Button>
					<F.Button onClick={this.deleteRow}>
						{ this.state.edit ? "Cancell" : "Remove" }
					</F.Button>
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
				<F.Button onClick={this.addRow}>
					Button
				</F.Button>
			</div>
		);
	}
});



	
/** 
 * The input fields can be not defined ---> they will be rendered as empty
 */
var App = React.createClass({


	/* This will force a rerendering on languae change */
 	contextTypes : {lang: React.PropTypes.string},

	model: { key: "iddhcprange",
		 desc: [ 
				[ "Min" , "Input" , "min"],
				[ "Max" , "Input" , "max"],
				[ "Domain" , "Dropdown" , "domain"],
				[ "Default lease duration", "Input", "default_lease_time"],
				[ "Maximum lease duration", "Input", "max_lease_time"]
			/*      [ "DHCP profile", "Dropdown", "dhcpprof"] XXX dhcpprof could be in conflict*/ 
		]
	},
		
	render: function () {
		return ( 
			<Table model={this.model} name="dhcp" > </Table>
		);

	}
});


/* Rendering the app on the node with id = 'app'
   change in case of conflict */
var dom_node = document.getElementById('app');

ReactDOM.render( <Translator> <App /> </Translator>, dom_node);



