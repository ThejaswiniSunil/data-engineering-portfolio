# NYC Taxi Lakehouse and Real-Time Analytics Platform

A hands-on big data engineering project built phase by phase on the NYC Taxi and Limousine Commission dataset:
HDFS, YARN, MapReduce, Hive, Spark (batch + Structured Streaming), Kafka, Airflow, HBase, and dashboards,
run with Docker Compose in a GitHub Codespace.

**Status:** Phase 1 (HDFS + YARN) files written; first verified run pending. See [docs/roadmap.md](docs/roadmap.md).
Results, screenshots and benchmarks will only be added from real runs.

## Quick start (GitHub Codespace, 2 cores / ~8 GB RAM)

```bash
./scripts/00_preflight.sh       # checks machine, pulls and inspects the Hadoop image
./scripts/01_up.sh              # starts the cluster
./scripts/02_verify_phase1.sh   # runs the checks
```

Web UIs once up: NameNode `:9870`, ResourceManager `:8088`, NodeManager `:8042`.
Stop the Codespace when you finish a session to preserve free hours.

## Docs
- [Architecture and data flow](docs/architecture.md)
- [Version matrix](docs/version-matrix.md)
- [Resource plan](docs/resource-plan.md)
- [Roadmap and repo structure](docs/roadmap.md)
- [Phase 1 guide, exercises and troubleshooting](docs/phase1-hdfs-yarn.md)
