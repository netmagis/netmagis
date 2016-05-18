How to implement utils/*
========================

dnsaddhost host ip view
-----------------------

  * GET /names ? name=host & domain=example.org & view=internal & test=host
	* => 403 Forbidden: context authorization does not authorize to
	    use this name/domain/view
	* => 200 app/json (empty json array): ok, name is not used
	* => 200 app/json (json array of length 1): ok, existing host, and we are authorized

  * if 200 (empty): POST /names with JSON content : add new host
  * if 200 (array length 1): POST /names/<idrr> with JSON content : modify existing host
