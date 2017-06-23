% NETMAGISRC(5) Netmagis User Manuals
% Jean Benoit, Pierre David, Arnaud Grausem
% June 23, 2017

# NAME

`~/.config/netmagisrc` - user configuration file for Netmagis client programs


# DESCRIPTION

The `netmagisrc` file contains user configuration for various programs in
the Netmagis server package.

> [general]
>>   _key_= _value_
>>   _key_= _value_
>>   ..


# CONFIGURATION KEYS

Configuration keys are divided in sections.

## SECTION [general]

url
  : URL of Netmagis REST server. For example:
    https://www.example.com/netmagis

key
  : API session key for this user. See the Netmagis Web application
    in order to get such a key or extend its lifetime.


## OTHER SECTIONS

No other section is defined at this time.

# FILES

`~/.config/netmagisrc`


# EXAMPLE

```
[general]
   url = https://www.example.com/netmagis
   key = averylongtokenprovidedbytheNetmagisWebserver
```


# SEE ALSO

`dnsaddalias` (1),
`dnsaddhost` (1),
`dnsdelhost` (1),
`dnsdelip` (1),
`dnsmodattr` (1),
`dnsreadprol` (1),
`dnswriteprol` (1)

<http://netmagis.org>
