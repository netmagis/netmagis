const webpack = require('webpack');

module.exports = {
    entry: {
	'netmagis': './src/netmagis.jsx',
	'test-app': './src/test-app.jsx',
	'common' : [ 'react' , 'react-dom' ]
    },
    output: {
        path: 'dist/',
        filename: '[name].js',
    },
    module: {
        loaders: [{
            test: /\.jsx?$/,
            exclude: /node_modules/,
            loader: 'babel',
        }]
    },
   plugins: [
 	new webpack.optimize.CommonsChunkPlugin("common", "common.js", Infinity),
// 	new webpack.optimize.UglifyJsPlugin()
	
  ]
};
