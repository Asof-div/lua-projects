#!/bin/bash 

sshfs -o allow_other,nonempty admin@192.168.234.43:/var/www/html/apponereach/storage/app/public/ /var/cloudpbx/ -o IdentityFile=/home/admin/VOIP.pem

sshfs -o allow_other,nonempty admin@192.168.234.43:/var/www/freeswitch/ /usr/local/freeswitch/conf/directory/default/ -o IdentityFile=/home/admin/VOIP.pem


fs_cli -x "load mod_flite"