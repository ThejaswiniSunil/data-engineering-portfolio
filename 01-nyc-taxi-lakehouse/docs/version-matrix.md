# Version matrix

Policy: a version only goes in the "Pinned" table once it has been run successfully in this repo.
Everything else is a **candidate** that gets checked for compatibility at the start of its own phase.
Nothing below the Phase 1 rows has been tested yet.

## Pinned (Phase 1)

| Component | Version | Source | Notes |
|---|---|---|---|
| Hadoop (HDFS, YARN, MapReduce) | 3.4.2 | `apache/hadoop:3.4.2` on Docker Hub | The Docker Hub tag listing shows linux/amd64 only. That matches Codespaces. |
| Docker Engine | 29.9.2 (reported by your Codespace) | preinstalled | |
| Docker Compose | v2 plugin | preinstalled | Uses `--wait` and healthcheck conditions. |

## Candidates for later phases (NOT verified)

| Phase | Component | Candidate | What must be checked first |
|---|---|---|---|
| 3 | MapReduce | bundled with Hadoop 3.4.2 | Python via Hadoop Streaming needs Python inside the image; confirm. |
| 4 | Hive + metastore | Hive 4.x or 3.1.x, Postgres metastore | Hive/Hadoop 3.4 compatibility; Hive 4 image availability. |
| 5 | Spark | 3.5.x or 4.0.x | Which Hadoop client the Spark build bundles vs. our 3.4.2 cluster; Spark-on-YARN needs the cluster's config on the Spark client. |
| 6 | Kafka | 3.9 / 4.x in KRaft mode (no ZooKeeper) | Saves RAM; confirm the Spark Kafka connector matches the Spark version. |
| 7 | Airflow | 2.10.x or 3.x | Memory use on 7.8 GB; LocalExecutor with Postgres. |
| 8 | HBase | 2.5.x or 2.6.x | Hadoop 3.4 support; HBase on HDFS vs. local; ZooKeeper requirement and RAM. |
| 9 | Superset | current stable | Hive connectivity driver (PyHive / thrift). |

Each phase will start by pinning exact tags, verifying them, and recording them here.
