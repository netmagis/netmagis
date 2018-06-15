/* https://reactjs.org/docs/context.html */

require("es6-promise").polyfill();

import React from "react";
import ReactDOM from "react-dom";
import Cookies from "universal-cookie";
import PropTypes from "prop-types";
import fetch from "isomorphic-fetch";

import { addLocaleData, IntlProvider, FormattedMessage } from "react-intl";
import enLocaleData from "react-intl/locale-data/en";
import frLocaleData from "react-intl/locale-data/fr";
addLocaleData([...enLocaleData, ...frLocaleData]);

import { UserContext } from "./user-context.jsx";

import { NMMenu } from "./nm-menu.jsx";

var baseUrl = window.location.toString().replace(/[^/]*$/, "");
// hack to decode pathname
function getPathname(url) {
    var parser = document.createElement("a");
    parser.href = window.location;
    return parser.pathname;
}
const pathUrl = getPathname(window.location).replace(/[^/]*$/, "");
//pathname = /netmagis/netmagis/ on test server -> put it router
const cookies = new Cookies();

class App extends React.Component {
    constructor(props) {
        super(props);

        this.changeLang = (l, e) => {
            e.preventDefault();
            this.setState({ lang: l });
            this.fetchTransl(l);
        };

        this.state = {
            user: "",
            lang: "C",
            cap: {},
            transl: {},
            errors: [],
            /****************
        fetchTransl: this.fetchTransl.bind (this),
        ****************/
            disconnect: this.disconnect.bind(this),
            changeLang: this.changeLang
        };
        this.fetchCap();

        this.api = this.api.bind(this);
        this.removeError = this.removeError.bind(this);
        this.addError = this.addError.bind(this);
        this.componentDidUpdate = this.componentDidUpdate.bind(this);
    }

    /*
     * Debug only function, prints the state at every update
     */
    componentDidUpdate() {
        console.log(this.state.errors);
    }

    decodeCap(json) {
        if (this.state.lang != json.lang) this.fetchTransl(json.lang);
        let cap = {};
        json.cap.forEach(val => (cap[val] = true));
        if (!cap["logged"]) {
            cap["notlogged"] = true;
        }
        console.log("decodeCap: cap=", cap);
        this.setState({
            user: json.user,
            lang: json.lang,
            cap: cap
        });
    }

    decodeTransl(lang, json) {
        console.log("decodeTransl: lang=", lang, ", json=", json);
        this.setState({
            lang: lang,
            transl: json
        });
        cookies.set("lang", lang, { path: pathUrl });
    }

    fetchCap() {
        this.api("GET", "cap", null, this.decodeCap.bind(this));
    }

    fetchTransl(l) {
        console.log("fetchTransl(", l, ")");
        this.api("GET", l + ".json", null, this.decodeTransl.bind(this, l));
    }

    disconnect() {
        console.log("deconnexion demandée ");
        cookies.remove("session");
        console.log("fonction executee");
        this.fetchCap();
    }

    /*
     * Make a request to the api
     */
    api(verb, name, jsonbody, handler) {
        let url = baseUrl + "/" + name;
        let opt = {
            method: verb,
            credentials: "same-origin"
        };
        if (jsonbody != null) {
            opt.headers = {
                "Content-Type": "application/json"
            };
            opt.body = JSON.stringify(jsonbody);
        }
        fetch(url, opt)
            .then(
                response => {
                    console.log(response);
                    if (!response.ok) {
                        console.log("ERROR resp");
                        response.json().then(json => {
                            this.addError(
                                `${json.type}: status ${json.status}, ${
                                    json.title
                                }. Details: ${json.detail}`
                            );
                        });

                        throw new Error("ERROR ", url, "=> ", response.status);
                    }
                    return response.json();
                },
                error => {
                    console.log("ERROR FETCH ", url, " => ", error);
                }
            )
            .then(
                json => {
                    console.log("JSON recupere");
                    console.log(json);
                    handler(json);
                    return json;
                },
                error => {
                    console.log("ERROR", url, " WHILE DECODING JSON ", error);
                }
            );
    }

    /*
    * This function adds an error in the state
    */
    addError(str) {
        this.setState(prevState => ({
            errors: [...prevState.errors, { errdesc: str }]
        }));
    }

    /*
    * This function gets the 'errdesc' properties of all error objects and
    * get the correct index for deleting the clicked item.
    */
    removeError(event) {
        let tmpArray = this.state.errors;

        //used to get the errdesc props from the state.errors
        let workArray = [];
        for (const v of tmpArray) {
            workArray.push(v.errdesc);
        }

        //removing the entry that has been clicked
        tmpArray.splice(
            workArray.indexOf(event.target.innerText.split(": ")[1]),
            1
        );

        //update state
        this.setState({
            errors: tmpArray
        });
    }

    render() {
        return (
            <UserContext.Provider value={this.state}>
                <IntlProvider
                    locale={this.state.lang}
                    messages={this.state.transl}
                >
                    <NMMenu
                        pathname={pathUrl}
                        errors={this.state.errors}
                        disconnect={function() {
                            this.disconnect();
                        }}
                        api={this.api}
                        removeError={this.removeError}
                    />
                </IntlProvider>
            </UserContext.Provider>
        );
    }
}

/* Render the app on the element with id #app */
ReactDOM.render(<App />, document.getElementById("app"));
