import React from "react";

const Infos = props => {
    const { adress } = props;

    return (
        <tr>
            <td>{adress.adress}</td>
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
                    {entries.map(entry => <Infos adress={entry} />)}
                </table>
            ) : (
                <div> Nothing to display </div>
            )}
        </div>
    );
};

//export default Consult;
