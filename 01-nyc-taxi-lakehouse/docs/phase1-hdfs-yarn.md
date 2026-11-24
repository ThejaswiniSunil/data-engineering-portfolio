# Phase 1: HDFS + YARN cluster

## Goal
A running Hadoop cluster you can explain: NameNode, two DataNodes, ResourceManager, NodeManager. Proven by real checks,
not assumed.

## Run order (in your Codespace terminal, from the repo root)

```bash
./scripts/00_preflight.sh        # machine + image facts. Paste the full output back to me.
./scripts/01_up.sh               # starts the cluster, waits until healthy
./scripts/02_verify_phase1.sh    # about 16 checks, ends with "RESULT: N passed, M failed"
```

First start pulls a ~1.2 GB image; allow a few minutes. After that, start-up should be much faster.

## What the verify script proves

| Check | What it demonstrates |
|---|---|
| 2 live DataNodes | DataNodes registered with the NameNode via heartbeats. |
| 5 MB file with 1 MB blocks becomes 5 blocks | Files are split into blocks (the real default is 128 MB; 1 MB is used only so a tiny test file shows multiple blocks). |
| Average replication 2.0 + fsck HEALTHY | Each block lives on both DataNodes. |
| SHA-256 of read-back equals what was written | End-to-end integrity through the HDFS pipeline. |
| `yarn node -list` shows RUNNING | NodeManager registered with the ResourceManager. |
| `hadoop jar ... pi 2 100` finishes | MapReduce runs as YARN containers: AM, map tasks, reduce task. |

## Exercises (do these; they are the interview answers)

### 1. See where blocks live
```bash
docker compose exec namenode bash -c 'head -c 5242880 /dev/urandom > /tmp/x.bin'
docker compose exec namenode hdfs dfs -D dfs.blocksize=1048576 -put /tmp/x.bin /x.bin
docker compose exec namenode hdfs fsck /x.bin -files -blocks -locations
```
Expected: 5 blocks, each listing two DataNode addresses. Question to answer: why does the client talk to the NameNode only for metadata?

### 2. Kill a DataNode and keep reading
```bash
docker compose stop datanode2
docker compose exec namenode hdfs dfs -cat /x.bin | wc -c        # still 5242880
docker compose exec namenode hdfs fsck /x.bin | grep -iE "under|status"
docker compose start datanode2
```
Expected: reads still work from the surviving replica. The NameNode takes a while to declare a silent DataNode dead
(by default about 10.5 minutes), so fsck may show the file healthy at first; the point is that data stayed available.
Do not guess the exact timing, watch what your cluster reports.

### 3. YARN resource limits
Open the ResourceManager UI (port 8088) while running
`docker compose exec namenode hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 4 100`.
Watch the container count and memory in use. Question: why can't we ask for a 2 GB container? (`maximum-allocation-mb`.)

## Concepts you should be able to explain after this phase
- NameNode vs DataNode responsibilities; what is in `fsimage` and the edit log.
- Block size, replication factor, and what `fsck` reports.
- Why DataNodes heartbeat, and what a block report is.
- ResourceManager vs NodeManager vs ApplicationMaster; what a container is.
- Why `maximum-am-resource-percent` matters on small clusters.

## Common errors

| Symptom | Likely cause | Fix |
|---|---|---|
| `init-perms` fails | The image's user/owner assumption is wrong. | Paste the preflight output; we adjust the `chown` target. |
| NameNode exits immediately | Config mount or format problem. | `docker compose logs namenode | tail -50` and paste it. |
| NameNode UI shows 0 live DataNodes | DataNodes cannot resolve/reach `namenode`. | `docker compose logs datanode1`. |
| Job stuck in ACCEPTED in the RM UI | Not enough memory for the ApplicationMaster. | Check `maximum-am-resource-percent`, free RAM (`free -h`). |
| Containers killed, exit code 137 | Out of memory (no swap). | Stop other containers; lower `yarn.nodemanager.resource.memory-mb`. |
| NodeManager unhealthy, "local-dirs are bad" | Disk over the utilization threshold. | Free disk space, or raise `max-disk-utilization-per-disk-percentage`. |
| Port not reachable in browser | Codespaces port not forwarded. | Open the PORTS tab and forward 9870, 8088, 8042. |

## Cleanup
```bash
docker compose down        # stop, keep HDFS data
docker compose down -v     # stop and wipe all HDFS/YARN data
```
