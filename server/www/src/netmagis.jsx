import React from 'react' ;
import ReactDOM from 'react-dom' ;

import {NMState} from './nm-state.jsx' ;
import {NMMenu} from './nm-menu.jsx' ;

/* Render the app on the element with id #app */
var dom_node = document.getElementById ('app') ;
ReactDOM.render (<NMState><NMMenu /></NMState>, dom_node) ;
