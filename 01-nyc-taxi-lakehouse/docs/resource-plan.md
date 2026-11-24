# Resource plan

Target machine (measured by you in the Codespace): **2 cores, 7.8 GiB RAM, no swap**.
No swap means exceeding RAM gets a container OOM-killed rather than slowed down, so we budget conservatively.

## Rule: run only what the current phase needs

The full stack (Hadoop + Hive + Spark + Kafka + Airflow + HBase + Superset) does not fit in 7.8 GiB at once.
Each later phase adds its own compose file, and the verify scripts for that phase start only the services required.
Stop the Codespace when you finish a session so the free monthly hours last.

## Phase 1 budget (estimates, to be replaced with measurements)

| Service | JVM heap | Approx. process RAM |
|---|---|---|
| NameNode | 384 MB | ~0.5 GB |
| DataNode x2 | 256 MB each | ~0.7 GB total |
| ResourceManager | 384 MB | ~0.5 GB |
| NodeManager daemon | 384 MB | ~0.5 GB |
| YARN containers (offered by NodeManager) | n/a | up to 2.0 GB when jobs run |
| **Total, jobs running** | | **~4.2 GB** |

These are my estimates from the configured heaps, not measurements. After the cluster is up and after the MapReduce job runs,
measure them for real:

```bash
docker stats --no-stream
free -h
```

and record the numbers in `docs/benchmarks.md` (created in the benchmarking phase; nothing is invented).

## Where the numbers come from

| Setting | Value | Why |
|---|---|---|
| `yarn.nodemanager.resource.memory-mb` | 2048 | Leaves headroom for 5 daemons, the OS and the Codespace's editor. |
| `yarn.nodemanager.resource.cpu-vcores` | 2 | Matches the 2 cores. |
| `yarn.scheduler.maximum-allocation-mb` | 1024 | Biggest single container. Spark executors in Phase 5 must fit under this. |
| MapReduce AM/map/reduce container | 512 MB, heap 384 MB | Heap must be smaller than the container or YARN kills it. |
| `maximum-am-resource-percent` | 0.5 | Default 0.1 would allow ~204 MB of AMs on this cluster, so no 512 MB AM could start. |
| `dfs.replication` | 2 | Two DataNodes; shows replication and failure recovery. |
