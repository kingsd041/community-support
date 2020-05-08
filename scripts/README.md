## crontab 配置

```
43 15 * * *  /opt/download.sh kingsd041:88c81fd04e36d40dd9b3570c88450eb521aa7cacc >> /opt/logs/download.log
1 3 * * *  /usr/local/bin/ossutil --config-file=/root/.ossutilconfig cp /opt/rancher-mirror/ oss://rancher-mirror/ -u -r --snapshot-path=/opt/rancher-mirror-snapshot/  >> /opt/logs/ossutil.log
```
