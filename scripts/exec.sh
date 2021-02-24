#!/bin/bash

keyword='Download the required resources successfully'
log_dir=/opt/logs/download
log_file=download-`date +'%Y-%m-%d-%H'`.log

# 从github下载rancher资源
/opt/community-support/scripts/download.sh kingsd041:22fd5eacc59e46f4f8958a478cd45e08b6378376 > /opt/logs/download/download-`date +'\%Y-\%m-\%d-\%H'`.log


# 同步资源到oss
cat $log_dir/$log_file | grep  "$keyword"
if [[ $? == "0"  ]]; then
    # /usr/local/bin/ossutil --config-file=/root/.ossutilconfig cp /opt/rancher-mirror/ oss://rancher-mirror/ -u -r --snapshot-path=/opt/rancher-mirror-snapshot/ > /opt/logs/ossutil/ossutil-`date +'\%Y-\%m-\%d-\%H'`.log
    /usr/local/bin/ossutil --config-file=/root/.ossutilconfig cp /opt/rancher-mirror/ oss://rancher-mirror/ -u  > /opt/logs/ossutil/ossutil-`date +'\%Y-\%m-\%d-\%H'`.log
fi

# 发送通知
/opt/community-support/scripts/send_notification.sh