How to run Netmagis 3.0 development code
========================================

This documentation describes how to run the Netmagis 3.0 
development code on a Debian host.

We assume that development code is located in branch `rest` in the 
netmagis repository.

Step 1 - Install an HTTP server
-------------------------------

Netmagis 3.0 can be run either with Apache or Nginx.

### Apache

  - install `apache2` and `libapache2-mod-scgi` Debian packages
  - run `a2enmod scgi`
  - run `a2enmod proxy_scgi`
  - copy `server/examples/apache.conf` to `/etc/apache2/sites-available/010-netmagis.conf`
  - edit `/etc/apache2/sites-available/010-netmagis.conf`. In 
    particular, you may want to remove the SSL configuration in 
    order to run a non HTTPS server on a non-standard TCP port 
    (e.g. 81)
  - run `a2ensite 010-netmagis.conf`

### Nginx

  - install `nginx` Debian package
  - copy `server/examples/nginx.conf` to `/etc/nginx/sites-available/netmagis`
  - edit `/etc/nginx/sites-available/netmagis`. In particular, you 
    may want to remove the SSL configuration in order to run a non 
    HTTPS server on a non-standard TCP port (e.g. 82)
  - run _<a command I don't remember>_ to enable the site

Step 2 - Install PostgreSQL and initialize database
---------------------------------------------------

### Install PostgreSQL

  - required packages: `postgresql`, `postgresql-pltcl`
  - create user: `createuser --no-superuser --no-createrole --createdb --pwprompt nm`
  - create an empty database: `createdb -U nm nm30`

### Initialize database

This step requires that Netmagis 3.0 is installed on the local 
machine.

  - required packages: `tcl`, `tcl8.6-dev`, `pandoc`, 
    `tcl-thread`, `tcl-tls`, `tcllib`, `libpgtcl`
  - to install `nodejs` and `npm` (packages with a recent 
    version), see:
      `curl -sL https://deb.nodesource.com/setup_8.x | bash -`, 
      then `apt install nodejs`
  - `PREFIX=/local/nm30 ; make PREFIX=$PREFIX TCLSH=/usr/bin/tclsh TCLCONF=/usr/lib/tcl8.6/tclConfig.sh NMDOCDIR=$PREFIX/share/doc NMXMPDIR=$PREFIX/share/examples NMLIBDIR=$PREFIX/lib NMVARDIR=$PREFIX/var install-client install-server`
  - copy `/local/nm30/etc/netmagis.conf.sample` to 
    `/local/nm30/etc/netmagis.conf` and modify the lines 
    `dnsdbhost` (`localhost`), `dnsdbname` (`nm30`), 
    `dnsdbpassword`, then copy the same values for `macdb*`
  - run `(cd /local/nm30/share/examples/with-views ; sh run-all.sh)` to fill 
    the database with example data


Step 3 - Run the REST server in-place
--------------------------------------

  - `cd server/bin ; NMCONF=/local/nm30/etc/netmagis.conf sh run-server`


Step 4 - Web application development
------------------------------------

The REST server started above uses the local sources (not the 
installed version in `/local/nm30`).

These sources are located in `server/www`.  This directory 
contains subdirectories:
  - `static`: where all static files (HTML files, localization 
    messages such as `en.json`) are kept
  - `src`: where the react jsx are located
  - `dist`: where the _transpiled_ source files are located after 
    the build phase

Files are served by the REST server from the `static` and `dist` 
subdirectories. In order to transpile the react sources, just type 
`make` in the `server/www` directory.
