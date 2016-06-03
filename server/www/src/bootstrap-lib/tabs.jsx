import React from 'react';
import ReactDOM from 'react-dom';
import {translate} from '../lang.jsx';




/** 
 * Use this element to specify the different contents inside
 * a Tabs component (see below), the contents must be put inside 
 * a Pane. A Pane takes also a `label` property which names 
 * the current tab.
 * @note: this component just wrap his children inside a <div>
 *	  his properties are used by the component Tabs.
 *
 * example of use: 
 *	<Pane label="Zoo"> <ListOfAnimals /> </Pane>
 */

export var Pane = React.createClass({
	
 	//contextTypes : {lang: React.PropTypes.string},
	
	render: function () {
		return ( 
			<div> {this.props.children} </div>
		);
	}
});







/**
 * Use this component togheter with one or more Panes (see above)
 * to create a series of toggling tabs. A Tabs takes an optional
 * property `selected` to specify the preselected panel (the panels 
 * are enumerated starting from 0, which is the default `selected` value)
 * 
 * Example of use:
 *
 * ReactDOM.render(
 *	<Tabs selected=1 >
 *		<Pane label="Tab 0">
 *			<First content />
 *		</Pane>
 *		<Pane label="Tab 1 (preselected)">
 *			<Second content />
 *		</Pane>
 *	</Tabs> , mount_node
 * );
 *
 */

export var Tabs = React.createClass({

	/* Use context in order to update on language changes */
 	contextTypes : {lang: React.PropTypes.string},



	/* The first tab is the one active by default */
	getInitialState: function () {
		return { selected: this.props.selected || 0 };
	},



	/* Update selected panel */
	handleClick: function (index, event) {
		event.preventDefault(); // Stop other things from happening
		this.setState({selected: index});
	},



	/* Render the navigation bar */
	_renderTitles: function () {

		function labels(child, index) {

			/* Label is active if selected */
			var activeClass = (this.state.selected === index) ? 'active' : '' ;
			
			return ( 
				<li key={"tlab"+index} className={activeClass}>
					<a href = "#" 
					 onClick={this.handleClick.bind(this,index)}>
						{translate(child.props.label)} 
					</a> 
				</li>
			);
		}

		return ( 
			<ul className = "nav nav-tabs" >
				{this.props.children.map(labels.bind(this))}
			</ul>
		);
	},






	/* Render the content of the children hiding the not-selected children */
	_renderContent: function () {

		function contents(child, index) {
			var show = (index == this.state.selected)? '' : 'none';
			return 	(
				<div key={"tcon"+index} style={{display: show}}> 
					{this.props.children[index]} 
				</div>
			);
		}

		return ( 
			<div className= "tabs-content" > 
			{this.props.children.map(contents.bind(this))}
			</div>
		
		);




		/**
		 * Old version: renders only the selected contents
		 * (note that the user-content on the other panels
		 * will be erased as the component will be re-mounted)
		 *
		 *	return (
		 *		<div className= "tabs-content" > 
		 *		{this.props.children[this.state.selected]}
		 *		</div>
		 *	);
		 *
		 */

	},



	/* Main render */
	render: function () {
		return ( 
			<div className = "tabs" > 
				{this._renderTitles()} 
				{this._renderContent()} 
			</div>
		);
	}

});







