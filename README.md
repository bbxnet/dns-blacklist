DNS Blacklist
=============

This repository contains sciprts for generating DNS blacklist configuration files for [BIND](http://www.isc.org/downloads/BIND/).


Configuration
-------------

This script recognizes the following variables that can be set in `config.mk` file.

**`BLACKLIST`**

File containing new-line separated list of domains to be blocked.

**`BLACKLIST_STRIP_WWW `**

Remove leading www. from blacklist URLs, if set to 1.

**`DEPLOYDIR`**

Directory containing BIND configuration files.

**`HOSTMASTER`**

DNS SOA hostmaster for blocked domains.

**`NAMEDBLACKLIST`**

Filename of BIND blacklist configuration file.

**`NAMEDCONF`**

Filename of BIND main configuration file, should be located in `DEPLOYDIR`.

**`PRIMARYDNS`**

Primary nameserver for blocked domains.

**`SECONDARYDNS`**

Secondary nameserver for blocked domains.

**`SERVICE`**

BIND service name.

**`ZONEFILE`**

Filename of BIND blacklist zone file.


Example configuration
---------------------

```
BLACKLIST = blacklist.txt
BLACKLIST_STRIP_WWW = 0
NAMEDBLACKLIST = named.conf.blacklist
ZONEFILE = db.blacklist
PRIMARYDNS = dnsa.example.com
SECONDARYDNS = dnsb.example.com
HOSTMASTER = root.example.com
DEPLOYDIR = /etc/bind
NAMEDCONF = named.conf
SERVICE = bind9
```


Usage
-----

To download latest version from GitHub and setup DNS blacklist run:

```
$ git clone --recursive https://github.com/bbxnet/dns-blacklist
$ cd dns-blacklist
$ make
$ sudo make deploy
```

**NOTE:** 
This script requires `config.mk` configration file (see [Configuration](#configuration) section) and new-line separated domain list to be present.


Test
----

This repository also provides a simple test, which checks basic functionality of DNS blacklist.

```
$ cd dns-blacklist
$ make test 
```

