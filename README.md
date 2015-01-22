# mycore_sympa

Bash script to sync ownCloud users and sympa mailling list. Sync is bidirectionnal, can subscribe and unsubscribe owncloud's users in a sympa mailling list. There are a lock mecanism, usefull for large owncloud installation.

## Usage

Typically, install this script on your PHP node. Script need to contact mysql server and sympa server. On a PHP node, check if sympa dump URL is accessible :
wget https://\<sympa_url\>/wws/dump/\<my_list\>/light -O /tmp/test

On sympa server side, you need to allow PHP node's subnet :
match([remote_addr],/\<php-node_subnet\>/)    smtp,smime,md5  -> do_it

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Gilian Gambini (<gilian.gambini@dsi.cnrs.fr>)
| **Copyright:**       | Copyright (c) 2014 CNRS DSI
| **License:**         | AGPL v3, see the COPYING file.
