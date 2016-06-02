api-handler get {/login} no {
    } {
    ::scgiapp::set-cookie session bla 0 / "" 0 0
    ::scgiapp::set-header Content-Type text/html
    ::scgiapp::set-body "<html><title>login ok</title><body>welcome!</body></html>"
}
