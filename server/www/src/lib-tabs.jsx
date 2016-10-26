import React from 'react' ;
import ReactDOM from 'react-dom' ;

/**
 * Use this component together with one or more Panes (see above)
 * to create a series of toggling tabs. A Tabs takes an optional
 * property `selected` to specify the preselected pane (panes
 * are enumerated starting from 0, which is the default `selected` value)
 *
 * Example of use:
 *
 * <Tabs selected=1 >
 *	<Pane label="Tab 0">
 *		<First content />
 *	</Pane>
 *	<Pane label="Tab 1 (preselected)">
 *		<Second content />
 *	</Pane>
 * </Tabs>
 *
 */

export var Tabs = React.createClass ({
    /* This will force a rerendering on language/capability change */
    contextTypes: {nm: React.PropTypes.object},

    /* The first tab is the one active by default */
    getInitialState: function () {
	return {selected: this.props.selected || 0} ;
    },

    /* Update selected panel */
    handleClick: function (index, event) {
	event.preventDefault () ;	// Stop other things from happening
	this.setState ({selected: index}) ;
    },

    /* Render the navigation bar */
    renderTitles: function () {
	function labels (child, index) {
	    /* Label is active if selected */
	    var activeClass = (this.state.selected === index) ? 'active' : '' ;
	    return (
		    <li key={"tlab" + index} className={activeClass}>
		      <a href = "#"
			   onClick={this.handleClick.bind (this, index)}
			   >
			{child.props.label}
		      </a>
		    </li>
		) ;
	}
	return (
		<ul className = "nav nav-tabs" >
		  {this.props.children.map (labels.bind (this))}
		</ul>
	    ) ;
    },

    /* Render the content of the children hiding the non-selected children */
    renderContents: function () {
	function contents (child, index) {
	    var show = (this.state.selected === index) ? '' : 'none' ;
	    return (
		    <div key={"tcon" + index} style={{display: show}}>
		      {this.props.children [index]}
		    </div>
		) ;
	}
	return (
		<div className= "tabs-content" >
		  {this.props.children.map (contents.bind (this))}
		</div>
	    ) ;
    },

    render: function () {
	return (
		<div className = "tabs" >
		  {this.renderTitles ()}
		  {this.renderContents ()}
		</div>
	    ) ;
    }
}) ;

/**
 * Use this element to specify the different contents inside
 * a Tabs component (see above), the contents must be put inside
 * a Pane. A Pane takes also a `label` property which names
 * the current tab.
 * @note: this component just wrap his children inside a <div>
 *	  his properties are used by the component Tabs.
 *
 * example of use:
 *	<Pane label="Zoo"> <ListOfAnimals /> </Pane>
 */

export var Pane = React.createClass ({
    /* This will force a rerendering on language/capability change */
    contextTypes: {nm: React.PropTypes.object},

    render: function () {
	return (<div>{this.props.children}</div>) ;
    }
}) ;

