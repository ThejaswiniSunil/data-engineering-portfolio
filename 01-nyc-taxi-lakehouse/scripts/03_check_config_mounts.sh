#!/usr/bin/env bash
# Fails if any Hadoop service runs a config file that differs from conf/hadoop/
fail=0
for svc in namenode datanode1 datanode2 resourcemanager nodemanager; do
  for f in core-site hdfs-site yarn-site mapred-site capacity-scheduler; do
    host=$(sha256sum "conf/hadoop/$f.xml" | cut -d' ' -f1)
    cont=$(docker compose exec -T "$svc" sha256sum "/opt/hadoop/etc/hadoop/$f.xml" 2>/dev/null | cut -d' ' -f1)
    if [ "$host" = "$cont" ]; then echo "  PASS: $svc $f.xml"; else echo "  FAIL: $svc $f.xml"; fail=1; fi
  done
done
exit $fail
