import React from "react";

export class Search extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            host: [],
            net: [],
            alias: [],
            other: [],
            lastres: {}
        };
    }

    componentDidUpdate() {
        if (
            JSON.stringify(this.state.lastres) != JSON.stringify(this.props.res)
        ) {
            const resArray = this.props.res;
            console.log("Seach results: ");
            console.log(resArray);
            let host = [];
            let net = [];
            let alias = [];
            let other = [];

            if (
                resArray != null ||
                resArray != undefined ||
                resArry.length !== 0
            ) {
                resArray.map(r => {
                    if (r.type == "host") {
                        host.push(r);
                    } else if (r.type == "network") {
                        net.push(r);
                    } else if (r.type == "alias") {
                        alias.push(r);
                    } else {
                        other.push(r);
                    }
                });
            } else {
                host = null;
                net = null;
                alias = null;
                other = null;
            }

            this.setState({
                lastres: resArray,
                host: host,
                net: net,
                alias: alias,
                other: other
            });
        }
    }

    render() {
        const { host, net, alias, other } = this.state;
        console.log("Search: ");
        console.log(this.props.search);
        return this.props.search != null &&
            this.props.search.length != 0 &&
            this.props.search != "" ? (
            <div className="container">
                <div className="row">
                    <div className="col-4" />
                    <div className="col">
                        <h3>Search results for {this.props.search}</h3>
                        {host == null &&
                        net == null &&
                        alias == null &&
                        other == null ? (
                            <p>No results</p>
                        ) : (
                            <div>
                                {host.length > 0 ? (
                                    <div>
                                        <h4>Hosts</h4>
                                        {host.map(h => (
                                            <a style={{ marginLeft: "2em" }}>
                                                {h.result}
                                                <br />
                                            </a>
                                        ))}
                                    </div>
                                ) : null}
                                {net.length > 0 ? (
                                    <div>
                                        <h4>Networks</h4>
                                        {net.map(n => (
                                            <a style={{ marginLeft: "2em" }}>
                                                {n.result}
                                                <br />
                                            </a>
                                        ))}
                                    </div>
                                ) : null}
                                {alias.length > 0 ? (
                                    <div>
                                        <h4>Aliases</h4>
                                        {alias.map(a => (
                                            <a style={{ marginLeft: "2em" }}>
                                                {a.result}
                                                <br />
                                            </a>
                                        ))}
                                    </div>
                                ) : null}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        ) : null;
    }
}

//export default Search;
