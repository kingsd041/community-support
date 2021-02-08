## crontab 配置

```
1 */12 * * * /opt/community-support/scripts/download.sh kingsd041:token > /opt/logs/download/download-`date +'\%Y-\%m-\%d-\%H'`.log && /usr/local/bin/ossutil --config-file=/root/.ossutilconfig cp /opt/rancher-mirror/ oss://rancher-mirror/ -u -r --snapshot-path=/opt/rancher-mirror-snapshot/ > /opt/logs/ossutil/ossutil-`date +'\%Y-\%m-\%d-\%H'`.log; /home/ubuntu/scripts/send_notification.sh
```
