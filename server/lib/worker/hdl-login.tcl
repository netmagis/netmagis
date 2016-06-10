api-handler get {/login} no {
    } {
    ::scgi::set-cookie session bla 0 / "" 0 0
    ::scgi::set-header Content-Type text/html
    ::scgi::set-body "<html><title>login ok</title><body>welcome!</body></html>"
}
