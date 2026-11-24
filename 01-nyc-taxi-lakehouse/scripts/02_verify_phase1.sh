#!/usr/bin/env bash
# Phase 1 verification: proves HDFS (replication, blocks), YARN (node registered) and MapReduce-on-YARN work.
# Exits non-zero if any check fails. Every check prints the evidence it used.
set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }
nn()   { docker compose exec -T namenode "$@"; }
section() { echo; echo "== $1 =="; }

TESTDIR="/phase1-verify"
LOCAL="$(mktemp)"
trap 'rm -f "$LOCAL"' EXIT

section "1. Containers"
for svc in namenode datanode1 datanode2 resourcemanager nodemanager; do
  state=$(docker compose ps --format '{{.State}}' "$svc" 2>/dev/null)
  [ "$state" = "running" ] && ok "$svc running" || bad "$svc state='$state'"
done

section "2. HDFS: DataNodes registered"
# After start-up the NameNode sits in safe mode (read-only) until enough blocks are reported. Wait it out.
nn hdfs dfsadmin -safemode wait 2>&1 | sed 's/^/  | /'
report=$(nn hdfs dfsadmin -report 2>&1)
live=$(echo "$report" | grep -E "Live datanodes" | grep -oE "[0-9]+" | head -1)
echo "$report" | grep -E "Live datanodes|Configured Capacity|DFS Used:|Replicated Blocks|Under replicated" | sed 's/^/  | /'
[ "${live:-0}" = "2" ] && ok "2 live DataNodes" || bad "expected 2 live DataNodes, got '${live:-none}'"

section "3. HDFS: write a multi-block file with replication"
# 5 MB file with a 1 MB block size => 5 blocks. (--block-size override applies to this write only.)
head -c 5242880 /dev/urandom > "$LOCAL"
nn hdfs dfs -rm -r -f -skipTrash "$TESTDIR" >/dev/null 2>&1
nn hdfs dfs -mkdir -p "$TESTDIR" && ok "mkdir $TESTDIR" || bad "mkdir $TESTDIR"
docker compose exec -T namenode bash -c "cat > /tmp/blob.bin" < "$LOCAL"
if nn hdfs dfs -D dfs.blocksize=1048576 -put -f /tmp/blob.bin "$TESTDIR/blob.bin"; then
  ok "put 5 MB file"
else
  bad "put 5 MB file"
fi
fsck=$(nn hdfs fsck "$TESTDIR/blob.bin" -files -blocks -locations 2>&1)
echo "$fsck" | grep -E "Total blocks|Average block replication|Under-replicated|Status:|^/" | sed 's/^/  | /'
blocks=$(echo "$fsck" | grep -E "Total blocks \(validated\)" | grep -oE "[0-9]+" | head -1)
avg=$(echo "$fsck" | grep -E "Average block replication" | grep -oE "[0-9]+\.[0-9]+" | head -1)
[ "${blocks:-0}" = "5" ] && ok "file split into 5 blocks" || bad "expected 5 blocks, got '${blocks:-none}'"
[ "${avg:-0}" = "2.0" ] && ok "average replication 2.0" || bad "expected replication 2.0, got '${avg:-none}'"
echo "$fsck" | grep -q "is HEALTHY" && ok "fsck reports HEALTHY" || bad "fsck not HEALTHY"

section "4. HDFS: read-back integrity"
sent=$(sha256sum "$LOCAL" | cut -d' ' -f1)
got=$(nn hdfs dfs -cat "$TESTDIR/blob.bin" | sha256sum | cut -d' ' -f1)
[ "$sent" = "$got" ] && ok "checksum matches ($sent)" || bad "checksum mismatch: sent=$sent got=$got"

section "5. YARN: NodeManager registered"
nodes=$(nn yarn node -list 2>&1)
echo "$nodes" | sed 's/^/  | /'
echo "$nodes" | grep -q "RUNNING" && ok "NodeManager RUNNING" || bad "no RUNNING NodeManager"

section "6. MapReduce on YARN (pi estimator: 2 maps x 100 samples)"
jar=$(nn bash -c 'ls /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar | head -1')
echo "  using $jar"
if out=$(nn hadoop jar "$jar" pi 2 100 2>&1); then
  echo "$out" | grep -E "Job Finished|Estimated value of Pi|application_[0-9_]+" | sed 's/^/  | /' | head -6
  echo "$out" | grep -q "Estimated value of Pi" && ok "MapReduce job completed on YARN" || bad "job ran but no result line"
else
  echo "$out" | tail -25 | sed 's/^/  | /'
  bad "MapReduce job failed (see docs/phase1-hdfs-yarn.md, 'Common errors')"
fi

section "Cleanup"
nn hdfs dfs -rm -r -f -skipTrash "$TESTDIR" >/dev/null 2>&1 && echo "  removed $TESTDIR"

echo
echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
