#
# User capabilities
#
#

api-handler get {/cap} any {
    } {
    set cap [format {["%s"]} [join [::n capabilities] {", "}]]
    set user [::n setuid]
    set lang [mclocale]

    set j [format {{"cap":%1$s, "user":"%2$s", "lang":"%3$s"}} $cap $user $lang]

    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}
