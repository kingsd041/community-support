#!/bin/bash

log_dir=/opt/logs/download
log_file=download-`date +'%Y-%m-%d-%H'`.log 
keyword='Download the required resources successfully'
host_data=`date "+%Y-%m-%d %H:%M:%S"`
host_hostname=`hostname`
host_ip=`/sbin/ifconfig eth0 | grep -w inet | awk  '{print $2}'`
mail_tile_failure="[FAILED] Rancher mirror download failed"
mail_tile_successful="[SUCCESS] Rancher mirror download successful ！！！"
receive_mail="nicholas_ksd@hotmail.com"
mail_content=`cat $log_dir/$log_file $receive_mail | grep -v "already exists"`

cat $log_dir/$log_file | grep  "$keyword"
if [[ $? != "0"  ]]; then
    echo -e "DATA: $host_data \nHOSTNAME: $host_hostname\nIP: $host_ip \nLogs: \n$mail_content" | s-nail  -s "$mail_tile_failure"  $receive_mail
else
    echo -e "DATA: $host_data \nHOSTNAME: $host_hostname\nIP: $host_ip \nLogs: \n$mail_content" | s-nail  -s "$mail_tile_successful"  $receive_mail
fi