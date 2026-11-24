#!/usr/bin/env bash
# Phase 1 preflight: checks the machine and inspects the pinned Hadoop image BEFORE we start the cluster.
# The image inspection exists because our compose file makes assumptions about the image
# (user, /opt/hadoop location, entrypoint). This prints the facts so they can be confirmed, not guessed.
set -uo pipefail

IMAGE="apache/hadoop:3.4.2"
cd "$(dirname "$0")/.."

echo "== Machine =="
echo "CPU cores : $(nproc)"
free -h | awk 'NR==1 || NR==2'
echo "Disk (/)  :"; df -h / | awk 'NR==1 || NR==2'
echo "Disk (docker root):"; df -h /var/lib/docker 2>/dev/null | awk 'NR==2' || true
echo

echo "== Docker =="
docker --version || { echo "FAIL: docker not found"; exit 1; }
docker compose version || { echo "FAIL: docker compose plugin not found"; exit 1; }
docker info >/dev/null 2>&1 || { echo "FAIL: docker daemon not reachable"; exit 1; }
echo

echo "== Pulling $IMAGE (first time: ~1.2 GB, takes a few minutes) =="
docker pull "$IMAGE" || { echo "FAIL: could not pull $IMAGE"; exit 1; }
echo

echo "== Image facts the compose file assumes =="
echo "-- Image architecture / entrypoint / default user:"
docker image inspect "$IMAGE" --format 'arch={{.Architecture}} os={{.Os}} user="{{.Config.User}}" entrypoint={{json .Config.Entrypoint}} cmd={{json .Config.Cmd}}'
echo "-- Inside the container:"
docker run --rm --entrypoint /bin/bash "$IMAGE" -c '
  echo "whoami            : $(whoami) (uid=$(id -u) gid=$(id -g))"
  echo "HADOOP_HOME       : ${HADOOP_HOME:-<unset>}"
  echo "/opt/hadoop owner : $(stat -c "%U (%u:%g)" /opt/hadoop 2>&1)"
  echo "java              : $(java -version 2>&1 | head -1)"
  echo "hadoop version    : $(hadoop version 2>&1 | head -1)"
  echo "bash /dev/tcp ok  : $(bash -c "exec 3<>/dev/tcp/127.0.0.1/1" 2>&1 | head -1 | sed "s/^$/(refused, as expected - feature works)/")"
  echo "config dir        :"; ls /opt/hadoop/etc/hadoop | grep -E "site.xml|capacity" | sed "s/^/   /"
  echo "examples jar      : $(ls /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar 2>&1)"
'
echo
echo "== Compose file syntax =="
docker compose config -q && echo "docker-compose.yml: valid"
echo
echo "Preflight finished. Paste this whole output back so the assumptions can be confirmed."
