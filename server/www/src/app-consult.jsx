import React from "react";
import { BrowserRouter as Router, Link, Route } from "react-router-dom";

const Infos = props => {
    const { adress } = props;

    return (
        <tr>
            <td>
                <Link to={"consult?net=" + adress.adress}>{adress.adress}</Link>
            </td>
        </tr>
    );
};

export const Consult = ({ match, entries }) => {
    console.log("Consut page loading");
    const queryString = require("query-string");
    const parsed = queryString.parse(location.search);
    console.log("N keys: " + Object.keys(parsed));

    return (
        <div>
            <h4> Consult component + args</h4>
            {Object.keys(parsed).length > 0 ? (
                <div>
                    {parsed.net ? (
                        <p>
                            {" "}
                            Infos about <b>{parsed.net}</b>{" "}
                        </p>
                    ) : (
                        <p>No network specified</p>
                    )}
                </div>
            ) : entries ? (
                <table className="consult-tab">
                    <tbody>
                        {entries.map(entry => <Infos adress={entry} />)}
                    </tbody>
                </table>
            ) : (
                <div> Nothing to display </div>
            )}
        </div>
    );
};

//export default Consult;
