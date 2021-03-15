## crontab 配置

```
1 */12 * * * /opt/community-support/scripts/download.sh kingsd041:token > /opt/logs/download/download-`date +'\%Y-\%m-\%d-\%H'`.log && /usr/local/bin/ossutil --config-file=/root/.ossutilconfig cp /opt/rancher-mirror/ oss://rancher-mirror/ -u -r --snapshot-path=/opt/rancher-mirror-snapshot/ > /opt/logs/ossutil/ossutil-`date +'\%Y-\%m-\%d-\%H'`.log; /opt/community-support/scripts/send_notification.sh
```

## rc.local

```
sleep 60

cd /opt/community-support/ && git pull
/opt/community-support/scripts/exec.sh $token
sleep 120

shutdown -h now

```

