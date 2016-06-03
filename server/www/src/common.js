import React from 'react';


export var APIURL = "http://130.79.91.54/stage-l2s4/nm_pages/api";


/* Same as $.getJSON but defines mimeType
   usefull in case of static files */
export var getJSON = function(url, success, callback){
        $.ajax({
                url: url,
                dataType: 'json',
                mimeType: 'application/json',
                success:  success,
                complete: callback
        });
}


/* dotted-quad IP to integer */
export function IPv4_dotquadA_to_intA( strbits ) {
	var split = strbits.split( '.', 4 );
	var myInt = (
		parseFloat( split[0] * 16777216 )	/* 2^24 */
	  + parseFloat( split[1] * 65536 )		/* 2^16 */
	  + parseFloat( split[2] * 256 )		/* 2^8  */
	  + parseFloat( split[3] )
	);
	return myInt;
}

/* integer IP to dotted-quad */
export function IPv4_intA_to_dotquadA( strnum ) {
	var byte1 = ( strnum >>> 24 );
	var byte2 = ( strnum >>> 16 ) & 255;
	var byte3 = ( strnum >>>  8 ) & 255;
	var byte4 = strnum & 255;
	return ( byte1 + '.' + byte2 + '.' + byte3 + '.' + byte4 );
}
 
