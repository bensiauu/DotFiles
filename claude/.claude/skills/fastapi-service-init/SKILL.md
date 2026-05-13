---
name: fastapi-service-init
description: Use this skill when the user wants to "scaffold a fastapi service", "new python microservice", or start a Python service from scratch that matches the rolls-royce / aimpact / amvp house style. Delegate to python-service-engineer for substantive business logic.
version: 0.1.0
---

# Scaffold a FastAPI service

## When to use
The user wants a fresh Python microservice. Existing-service edits go to `python-service-engineer` directly.

## House style (matches rolls-royce / aimpact / amvp)
- Python 3.11
- FastAPI + uvicorn (gunicorn-uvicorn worker in prod)
- Pydantic v2 settings from env
- SQLAlchemy 2.x async + Alembic
- Aio-pika for RabbitMQ (or aiokafka for Kafka, per repo convention)
- MinIO via `minio` client
- Structured JSON logging via `structlog` or `python-json-logger`
- `/healthz` (liveness) + `/readyz` (checks DB + broker + object store reachable)
- `uv` lockfile (or `pip-tools` if repo already uses it)

## Output layout
```
<service-name>/
  pyproject.toml          # uv/pip-tools, ruff, mypy/pyright config
  uv.lock
  Dockerfile              # multi-stage, non-root, distroless or alpine final
  .dockerignore
  docker-compose.yml      # local dev: service + postgres + rabbitmq + minio
  src/<pkg>/
    __init__.py
    main.py               # FastAPI app factory, lifespan, routers
    settings.py           # Pydantic BaseSettings
    logging.py            # structlog config
    health.py             # /healthz, /readyz handlers
    db/
      __init__.py
      session.py          # async engine + sessionmaker
      models.py
    broker/
      __init__.py
      consumer.py         # aio-pika consumer skeleton
      publisher.py
    storage/
      __init__.py
      minio_client.py
    routers/
      __init__.py
      example.py
  alembic/
    env.py                # async-aware
    versions/
  tests/
    conftest.py           # testcontainers fixtures for pg/rabbit/minio
    test_health.py
    test_example.py
  .env.example
  README.md
```

## Steps
1. Gather: service name, primary purpose (one sentence), whether it needs RabbitMQ/Kafka, whether it needs MinIO.
2. Create directory tree.
3. Write `pyproject.toml` pinning fastapi, pydantic v2, sqlalchemy 2, aio-pika, minio, structlog, ruff, pyright, pytest, pytest-asyncio, httpx, testcontainers.
4. Run `uv lock` to produce `uv.lock`.
5. Write `main.py` with app factory, lifespan (sets up DB engine + broker connection + minio client), router includes.
6. Write `settings.py` reading every external dep from env (DATABASE_URL, RABBITMQ_URL, MINIO_*).
7. Write `health.py` — `/healthz` returns 200 always; `/readyz` checks each dep with a short timeout.
8. Write `broker/consumer.py` skeleton with at-least-once handler, DLQ binding, ack-after-commit pattern.
9. Write the Dockerfile (multi-stage, non-root, includes `--health` curl on `/healthz`).
10. Write `docker-compose.yml` for local-dev parity with the user's existing stacks.
11. Write `conftest.py` with testcontainers fixtures (no DB mocks — user has been bitten by mock/prod divergence).
12. Hand off business logic / domain models to `python-service-engineer`.

## Hard rules
- No blocking I/O in async paths.
- No `except Exception` swallowing errors — raise typed exceptions handled by FastAPI exception handlers.
- DB integration tests use testcontainers, not mocks.

## Reporting
Files created, dependencies pinned, and the next prompt for `python-service-engineer`.
