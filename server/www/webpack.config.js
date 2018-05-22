const webpack = require('webpack') ;
const path = require ("path") ;

module.exports = {
    entry: {
	"netmagis": "./src/netmagis.jsx",
	// "test-app": "./src/test-app.jsx",
	// "common" : [ "react" , "react-dom" ]
	// "test-redux": "./src/test-redux.jsx",
    },
    output: {
        path: path.resolve (__dirname, "dist"),
        filename: "[name].js",
    },
    module: {
        rules: [
	    {
		test: /\.jsx?$/,
		exclude: /node_modules/,
		loader: "babel-loader",
		options: {
		    presets: ["env"],
		},
	    }
	],
    },
   plugins: [
// 	new webpack.optimize.CommonsChunkPlugin("common", "common.js", Infinity),
// 	new webpack.optimize.UglifyJsPlugin()
	
  ]
};
