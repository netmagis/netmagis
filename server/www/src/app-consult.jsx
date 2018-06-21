import React from "react";
import { BrowserRouter as Router, Link, Route, Switch } from "react-router-dom";

//host infos
const Infos = props => {
    const { host } = props;
    const { domain, iddom, idhost, idview, name, view } = host;
    console.log("Host obj: " + host);

    return (
        <tr>
            <td>{idhost}</td>
            <td>
                <Link onClick={() => callback(addr4)} to={"host/" + idhost}>
                    {name}
                </Link>
            </td>
            <td>{iddom}</td>
            <td>{domain}</td>
            <td>{idview}</td>
            <td>{view}</td>
        </tr>
    );
};

//list of available networks
const NetworkListItem = props => {
    const { net, callback } = props;
    const {
        name,
        addr4,
        addr6,
        location,
        organization,
        community,
        comment,
        dhcp,
        gw4,
        gw6
    } = net;

    return (
        <tr>
            <td>{name}</td>
            <td>
                {/* <Link
                    onClick={() => props.goToHost()}
                    to={"consult?net=" + addr4}
                >
                    {addr4}
                </Link> */}
                <Link
                    onClick={() => callback(addr4)}
                    to={"consult/net=" + addr4}
                >
                    {addr4}
                </Link>
            </td>
            <td>
                <Link
                    onClick={() => callback(addr6)}
                    to={"consult/net=" + addr6}
                >
                    {addr6}
                </Link>
            </td>
            <td>{location}</td>
            <td>{organization}</td>
            <td>{community}</td>
            <td>{comment}</td>
            <td>{dhcp}</td>
            <td>{gw4}</td>
            <td>{gw6}</td>
        </tr>
    );
};
class NetworkList extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            networks: []
        };

        this.parseNetwork = this.parseNetwork.bind(this);
    }

    componentDidMount() {
        this.props.api("GET", "networks", null, this.parseNetwork.bind(this));
    }

    parseNetwork(json) {
        console.log("Network json received: ");

        this.setState(prevState => {
            if (
                JSON.stringify(json) !== JSON.stringify(prevState.networks) ||
                prevState.networks == null
            )
                return { networks: json };
        });
        // if (json != JSON.stringify(this.state.networks)) {
        //     this.setState({ networks: json });
        //     console.log("SetState ok: ");
        // }

        console.log(this.state.networks);
    }

    render() {
        return (
            <div>
                {this.state.networks == null ||
                this.state.networks == undefined ? (
                    <p>Loading networks...</p>
                ) : (
                    <table className="table table-hover">
                        <thead className="thead-light">
                            <tr>
                                <th>
                                    <b>name</b>
                                </th>
                                <th>
                                    <b>addr4</b>
                                </th>
                                <th>
                                    <b>addr6</b>
                                </th>
                                <th>
                                    <b>location</b>
                                </th>
                                <th>
                                    <b>organization</b>
                                </th>
                                <th>
                                    <b>community</b>
                                </th>
                                <th>
                                    <b>comment</b>
                                </th>
                                <th>
                                    <b>dhcp</b>
                                </th>
                                <th>
                                    <b>gw4</b>
                                </th>
                                <th>
                                    <b>gw6</b>
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            {this.state.networks.map(n => (
                                <NetworkListItem
                                    net={n}
                                    callback={this.props.updateHosts}
                                />
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        );
    }
}

class HostList extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            hosts: []
        };

        //this.props.updateHosts(this.props.m.params.net);
        this.parseConsult = this.parseConsult.bind(this);
    }

    componentDidMount() {
        this.props.api(
            "GET",
            "hosts?addr=" +
                this.props.m.params.net.split("net=")[1] +
                "/" +
                this.props.m.params.mask,
            null,
            this.parseConsult.bind(this)
        );
    }

    parseConsult(json) {
        console.log("Consult json received: ");
        this.setState({ hosts: json });
        console.log("SetState ok: ");
        console.log(this.state.hosts);
    }

    render() {
        console.log("Hosts object");
        console.log(this.state.hosts);
        return (
            <div>
                <h3>
                    {this.props.m.params.net + "/" + this.props.m.params.mask}
                </h3>
                <div>
                    {this.state.hosts == null ? (
                        <p>Loading...</p>
                    ) : (
                        <table className="table table-hover">
                            <thead className="thead-light">
                                <tr>
                                    <th>
                                        <b>host id</b>
                                    </th>
                                    <th>
                                        <b>host name</b>
                                    </th>
                                    <th>
                                        <b>domain id</b>
                                    </th>
                                    <th>
                                        <b>domain</b>
                                    </th>
                                    <th>
                                        <b>view id</b>
                                    </th>
                                    <th>
                                        <b>view name</b>
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                {this.state.hosts.map(h => <Infos host={h} />)}
                            </tbody>
                        </table>
                    )}
                </div>
            </div>
        );
    }
}

// const PageHote = ({ match }) => (
//     <div>
//         <h3>Page Hotes {match.params.net}</h3>
//     </div>
// );
//
// const PageNet = props => (
//     <div>
//         <h3>Page réseaux</h3>
//         <Link onClick={() => props.goto()} to="consult?net=10.0.0.1">
//             {"10.0.0.1"}
//         </Link>
//     </div>
// );

class HostPage extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            hostInfo: {}
        };

        this.parseHost = this.parseHost.bind(this);
    }

    componentDidMount() {
        this.props.api(
            "GET",
            "hosts/" + this.props.m.params.id,
            null,
            this.parseHost.bind(this)
        );
    }

    parseHost(json) {
        console.log("Consult json received: ");
        this.setState({ hostInfo: json });
        console.log("SetState ok: ");
        console.log(this.state.hostInfo);
    }

    render() {
        const st = this.state.hostInfo;
        return (
            <div>
                <p>Host n°{this.props.m.params.id}</p>
                <p>Adresses</p>
                {/* <table>{st.addr.map(a => <tr>{a}</tr>)}</table> */}
                <p>Comment: {st.comment}</p>
                <p>Id DHCP profile: {st.iddhcpprof}</p>
                <p>Id domain: {st.iddom}</p>
                <p>ID hinfo: {st.idhinfo}</p>
                <p>ID view: {st.idview}</p>
                <p>MAC address: {st.mac}</p>
                <p>Name: {st.name}</p>
                <p>Resp mail: {st.respmail}</p>
                <p>Resp name: {st.respname}</p>
                <p>Send smtp: {st.sendsmtp}</p>
                <p>TTL: {st.ttl}</p>
            </div>
        );
    }
}
//main consult component
export class Consult extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            hosts: null,
            api: this.props.api,
            parsed: "",
            networks: null,
            page: "net" //can have 'net' or 'host' as value
        };
        console.log("Consult page loading");
        //this.props.api("GET", "hosts", null, this.parseConsult.bind(this));

        //this.parseConsult = this.parseConsult.bind(this);
        this.parseNetwork = this.parseNetwork.bind(this);
        this.updateHosts = this.updateHosts.bind(this);
        //this.forceUpdateHandler = this.forceUpdateHandler.bind(this);*/
        this.goToHost = this.goToHost.bind(this);
    }

    // componentDidMount() {
    //     console.log("Mounted");
    //     const queryString = require("query-string");
    //     this.setState({ parsed: queryString.parse(location.search) });
    //     if (
    //         this.state.parsed.net != null ||
    //         this.state.parsed.net != undefined
    //     ) {
    //         console.log("Query detected ! " + this.state.parsed.net);
    //         this.SetState({ page: "hosts" });
    //     }
    //     //console.log("N keys: " + Object.keys(this.state.parsed));
    //     //this.props.api("GET", "networks", null, this.parseNetwork.bind(this));
    // }

    // componentDidUpdate() {
    //     console.log("Component updating");
    //     const queryString = require("query-string");
    //     if (this.state.parsed != queryString.parse(location.search)) {
    //         this.setState({ parsed: queryString.parse(location.search) });
    //         //this.forceUpdateHandler();
    //     }
    // }

    // forceUpdateHandler() {
    //     console.log("Force update !");
    //     this.forceUpdate();
    // }
    //callback function passed to api calls that changes the 'hosts' state
    parseConsult(json) {
        console.log("Consult json received: ");
        this.setState({ hosts: json });
        console.log("SetState ok: ");
        console.log(this.state.hosts);
    }

    //callback function passed to api calls that changes the 'networks' state
    parseNetwork(json) {
        console.log("Network json received: ");

        this.setState(prevState => {
            if (
                JSON.stringify(json) !== JSON.stringify(prevState.networks) ||
                prevState.networks == null
            )
                return { networks: json };
        });
        // if (json != JSON.stringify(this.state.networks)) {
        //     this.setState({ networks: json });
        //     console.log("SetState ok: ");
        // }

        console.log(this.state.networks);
    }

    //updates hosts in state (used when a network is selected)
    updateHosts(addr) {
        console.log("Go to hosts page for " + addr + "network");
        //this.setState({ hosts: null });
        this.props.api(
            "GET",
            "hosts?addr=" + addr,
            null,
            this.parseConsult.bind(this)
        );
        this.forceUpdate();
    }

    // componentDidUpdate() {
    //     console.log("Component updating");
    //
    //     const queryString = require("query-string");
    //     if (this.state.parsed != queryString.parse(location.search)) {
    //         this.setState({ parsed: queryString.parse(location.search) });
    //         //this.forceUpdateHandler();
    //     }
    //
    //     console.log(this.state.page);
    // }

    goToHost() {
        this.setState({ page: "host" });
        console.log("Change page: " + this.state.page);
        //this.forceUpdate();
    }

    displayPage(st) {
        console.log("Display page called");
        //console.log(this.state.parsed.net);
        if (st == "host") {
            console.log("Page hote");
            return <PageHote />;
        } else {
            console.log("Page net");
            this.props.api(
                "GET",
                "networks",
                null,
                this.parseNetwork.bind(this)
            );
            return (
                <NetworkList
                    networks={this.state.networks}
                    updateHosts={this.updateHosts}
                />
            );
        }
    }

    render() {
        const queryString = require("query-string");
        const parser = queryString.parse(location.search);
        console.log("Parser result: ");
        console.log(parser);

        const { match, entries, api } = this.props;
        return (
            <Router>
                <div>
                    {/* <button
                        onClick={() => {
                            this.state.page == "net"
                                ? this.setState({ page: "host" })
                                : this.setState({ page: "net" });
                        }}
                    >
                        change page
                    </button>
                    <h3>Page {this.state.page}</h3>
                    {this.displayPage(this.state.page)} */}
                    <Switch>
                        <Route
                            exact={true}
                            path="*/consult"
                            render={() => (
                                <NetworkList
                                    networks={this.state.networks}
                                    updateHosts={this.updateHosts}
                                    api={api}
                                />
                            )}
                        />
                        {/* <Route path="/consult/:net" component={PageHote} /> */}
                        <Route
                            path="*/consult/host/:id"
                            render={({ match }) => (
                                <HostPage m={match} api={api} />
                            )}
                        />
                        <Route
                            path="*/consult/:net/:mask"
                            render={({ match }) => (
                                <HostList
                                    parsed={this.parsed}
                                    updateHosts={this.updateHosts}
                                    hosts={this.state.hosts}
                                    api={api}
                                    m={match}
                                />
                            )}
                        />
                    </Switch>
                </div>
            </Router>
        );
    }
}

/*this.props.entries ? (
                    <table className="consult-tab">
                        <div>
                            <button
                                onClick={() => {
                                    console.log(
                                        "Api call: " +
                                            api(
                                                "GET",
                                                "hosts",
                                                null,
                                                this.parseConsult
                                            )
                                    );
                                }}
                            >
                                Call api
                            </button>
                        </div>
                        <tbody>
                            <div className />
                            {this.props.entries.map(entry => (
                                <Infos adress={entry} />
                            ))}
                        </tbody>
                    </table>
                ) : (
                    <div> Nothing to display </div>
                )
                */

/*
                    //////tmp /////////////////

                    <table>
                        {this.state.hosts == null ? (
                            <p>Loading...</p>
                        ) : (
                            <tbody>
                                <tr>
                                    <td>
                                        <b>domain id</b>
                                    </td>
                                    <td>
                                        <b>domain</b>
                                    </td>
                                    <td>
                                        <b>host id</b>
                                    </td>
                                    <td>
                                        <b>host name</b>
                                    </td>
                                    <td>
                                        <b>view id</b>
                                    </td>
                                    <td>
                                        <b>view name</b>
                                    </td>
                                </tr>
                                {this.state.hosts.map(h => <Infos host={h} />)}
                            </tbody>
                        )}
                    </table>

                    //////////////
                */

//export default Consult;
