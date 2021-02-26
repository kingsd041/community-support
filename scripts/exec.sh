#!/bin/bash

keyword='Download the required resources successfully'
log_dir=/opt/logs/download
log_file=download-`date +'%Y-%m-%d-%H'`.log

# 从github下载rancher资源
/opt/community-support/scripts/download.sh $1 > /opt/logs/download/download-`date +'%Y-%m-%d-%H'`.log


# 同步资源到oss
cat $log_dir/$log_file | grep  "$keyword"
if [[ $? == "0"  ]]; then
    /usr/local/bin/ossutil --config-file=/root/.ossutilconfig cp /opt/rancher-mirror/ oss://rancher-mirror/ -u -r --snapshot-path=/opt/rancher-mirror-snapshot/ > /opt/logs/ossutil/ossutil-`date +'%Y-%m-%d-%H'`.log
fi

# 发送通知
/opt/community-support/scripts/send_notification.sh