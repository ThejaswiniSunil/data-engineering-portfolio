# Roadmap and target repository structure

Status legend: **done** = run and verified on a real cluster. Nothing is marked done until the output has been seen.

| # | Phase | Status |
|---|---|---|
| 1 | Environment setup + HDFS and YARN cluster, with verification | files written, awaiting your first run |
| 2 | HDFS deep dive: blocks, replication, fault-tolerance exercises, NYC data landing in Bronze | not started |
| 3 | MapReduce (Python Hadoop Streaming) on taxi data | not started |
| 4 | Hive warehouse: metastore, external/managed tables, partitions, analytical SQL | not started |
| 5 | PySpark batch ETL (Bronze -> Silver -> Gold), star schema, Spark on YARN, tuning | not started |
| 6 | Kafka + Spark Structured Streaming: watermarks, checkpoints, dead-letter topic | not started |
| 7 | Airflow DAGs: ingest, process, validate, publish; retries and backfills | not started |
| 8 | HBase: row-key design, scans, lookups, operational metrics | not started |
| 9 | Dashboards (Superset) | not started |
| 10 | Hardening: tests, CI, monitoring, measured benchmarks, README polish | not started |

Roadmap note: phases 1 and 2 of your original list (cluster setup, HDFS and YARN verification) are combined in the files here;
the HDFS exercises in Phase 2 build on the cluster from Phase 1.

## Target repository structure (grows phase by phase)

```
nyc-taxi-lakehouse/
├── README.md
├── docker-compose.yml            # Phase 1: HDFS + YARN
├── compose/                      # later phases add their own compose files here
│   ├── hive.yml                  # Phase 4
│   ├── kafka.yml                 # Phase 6
│   ├── airflow.yml               # Phase 7
│   ├── hbase.yml                 # Phase 8
│   └── superset.yml              # Phase 9
├── conf/
│   ├── hadoop/                   # core, hdfs, yarn, mapred, capacity-scheduler
│   ├── hive/  spark/  kafka/  hbase/
├── scripts/                      # numbered, runnable, each ends in PASS/FAIL
├── ingestion/                    # batch download + landing into Bronze
├── mapreduce/                    # mapper.py / reducer.py
├── sql/                          # HiveQL DDL and analytics
├── spark/                        # batch ETL, streaming jobs, shared modules
├── streaming/                    # event generator, Kafka producer/consumer
├── airflow/dags/
├── hbase/
├── dashboards/
├── tests/                        # pytest: unit + integration
├── docs/                         # architecture, data flow, troubleshooting, benchmarks, screenshots
└── .github/workflows/            # CI
```
