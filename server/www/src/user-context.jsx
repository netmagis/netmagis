import React from 'react' ;

export const UserContext = React.createContext ({
    user: '',
    cap: {},
    lang: 'C',
    transl: {},
    disconnect: () => {},
    fetchCap: () => {},
    changeLang: (l) => {},
}) ;

export function withUser (Component) {
    return function UseredComponent (props) {
	return (
	    <UserContext.Consumer>
		{(c) => <Component {...props}
				user={c.user} cap={c.cap} lang={c.lang}
				disconnect={c.disconnect}
				changeLang={c.changeLang}
				/>}
	    </UserContext.Consumer>
	) ;
    } ;
}
