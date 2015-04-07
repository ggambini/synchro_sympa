# Synchro_sympa

Bash script to sync mails from a mysql table and sympa list. Sync is bidirectionnal, can subscribe and unsubscribe website's users in a mailling list. There are a lock mecanism and syslog method, usefull for large installation.

This script use a MySQL request to extract mail address of your website's users. 

## Usage

Typically, install this script on your PHP node. Script need to contact mysql server and sympa server. On a PHP node, check if sympa dump URL is accessible :

wget https://\<sympa_url\>/wws/dump/\<my_list\>/light -O /tmp/test

On sympa server side, You need to allow owner to make subscribe/unsubscrive without auth and you need to allow PHP node's subnet :

match([remote_addr],/\<php-node_subnet\>/)    smtp,smime,md5  -> do_it

Lock_file location must be on a shared filesystem if you want cron's redundancy. Leave log_file empty to use syslog, then if you have multiple PHP node, you can use a centralized logging service like syslog-ng.

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Gilian Gambini (<gilian.gambini@dsi.cnrs.fr>)
| **Copyright:**       | Copyright (c) 2014 CNRS DSI
| **License:**         | AGPL v3, see the COPYING file.
