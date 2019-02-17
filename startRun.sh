#!/bin/sh
# startPure-ftpd
echo "start Pureftpd Now !"
pure-ftpd /etc/pure-ftpd.conf
# startNginx
echo "start Nginx Now!"
nginx -g "daemon off;"