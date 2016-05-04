How to implement utils/*
========================

dnsaddhost host ip view
-----------------------

  * GET /names ? name=host & domain=example.org & view=internal & context=host
	* => 403 Forbidden: context authorization does not authorize to
	    use this name/domain/view
	* => 404 Not Found: ok, name is not used
	* => 200 app/json: ok, existing host, and we are authorized

  * if 404: POST /names with JSON content : add new host
  * if 200: POST /names/<idrr> with JSON content : modify existing host
