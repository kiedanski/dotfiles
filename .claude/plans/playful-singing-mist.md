# Plan: Configurable Storage Backend (Local FS vs S3)

## Context

Multi-replica Kubernetes deployments (StatefulSet with `replicas: 2`) share state via Postgres (DBOS) but not the filesystem. When a file is uploaded to `app-0`, it lives in `/tmp/excellence_workflows/<id>/` on that pod only. If DBOS resumes the workflow on `app-1`, the pod crashes trying to read a file that doesn't exist there.

The fix: introduce a `StorageBackend` abstraction so all file I/O routes through a single configurable interface. For local dev, behavior is unchanged (local disk). For k8s, configure S3 (or S3-compatible) so all pods read/write from shared object storage.

## Architecture

### New package: `backend/src/excellence_app/storage/`

```
storage/
  __init__.py        # exports get_storage()
  backend.py         # StorageBackend ABC
  local.py           # LocalBackend (current behavior)
  s3.py              # S3Backend (boto3)
  factory.py         # singleton get_storage()
```

### StorageBackend ABC (`backend.py`)

```python
class StorageBackend(ABC):
    # Workflow temp files (DataFrames, pickles, etc.)
    def workflow_path(self, workflow_id: str, *parts: str) -> str: ...       # logical path key
    def write_bytes(self, path: str, data: bytes) -> None: ...
    def read_bytes(self, path: str) -> bytes: ...
    def exists(self, path: str) -> bool: ...
    def delete(self, path: str) -> None: ...
    def list_paths(self, prefix: str) -> list[str]: ...
    def delete_prefix(self, prefix: str) -> None: ...

    # Upload handling (user-uploaded Excel files)
    def write_upload(self, upload_id: str, filename: str, data: bytes) -> str: ...  # returns path key
    def get_local_path(self, path: str) -> str: ...  # downloads to local tmp if needed, returns local path

    # Result/download handling
    def write_result(self, workflow_id: str, local_path: str) -> str: ...    # returns path key
    def get_download_response(self, path: str, filename: str) -> Response: ...  # FileResponse or redirect
```

### Factory (`factory.py`)

```python
_storage: StorageBackend | None = None

def get_storage() -> StorageBackend:
    global _storage
    if _storage is None:
        backend = os.getenv("STORAGE_BACKEND", "local")
        if backend == "s3":
            _storage = S3Backend(
                bucket=os.environ["S3_BUCKET"],
                region=os.getenv("AWS_REGION", "us-east-1"),
                prefix=os.getenv("S3_KEY_PREFIX", "excellence-workflows"),
                presigned_expiry=int(os.getenv("S3_PRESIGNED_URL_EXPIRY", "3600")),
            )
        else:
            _storage = LocalBackend(
                base_dir=os.getenv("TEMP_DIR", "/tmp/excellence_workflows")
            )
    return _storage
```

## Files to Modify

### 1. `backend/src/excellence_app/workflow/temp_storage.py`

Thin delegation shim — replace all direct `os`/`pickle`/`Path` calls with `get_storage()`:

```python
from excellence_app.storage import get_storage

DATAFRAMES_DIR = "dataframes"

def save_dataframe(df, workflow_id: str, name: str) -> str:
    path = get_storage().workflow_path(workflow_id, DATAFRAMES_DIR, name + ".pkl")
    get_storage().write_bytes(path, pickle.dumps(df))
    return path

def load_dataframe(path: str) -> pd.DataFrame:
    return pickle.loads(get_storage().read_bytes(path))

def delete_workflow_files(workflow_id: str) -> None:
    get_storage().delete_prefix(
        get_storage().workflow_path(workflow_id, "")
    )
```

Note: existing callers pass the path returned by `save_dataframe` directly to `load_dataframe` — this contract is preserved.

### 2. `backend/src/excellence_app/app/excel_endpoints.py`

- **Upload**: `storage.write_upload(upload_id, filename, await file.read())` → store returned path key in state
- **Read for processing**: `storage.get_local_path(path_key)` → local path (downloads from S3 if needed)
- **Download result**: `storage.get_download_response(path_key, filename)` → `FileResponse` for local, 302 redirect to presigned URL for S3

### 3. `backend/src/excellence_app/workflow/workflow.py` (finalize step)

Write output Excel to a local tmp file, then:
```python
path_key = get_storage().write_result(workflow_id, local_tmp_path)
state.result_path = path_key
```

### 4. `backend/pyproject.toml`

Add `boto3>=1.34.0` to dependencies.

### 5. `k8s/app.yaml`

Add env vars to StatefulSet container spec:
```yaml
- name: STORAGE_BACKEND
  value: "s3"
- name: S3_BUCKET
  valueFrom:
    secretKeyRef:
      name: api-keys
      key: S3_BUCKET
- name: AWS_REGION
  value: "us-east-1"
```

## New Environment Variables

| Variable | Default | Description |
|---|---|---|
| `STORAGE_BACKEND` | `local` | `local` or `s3` |
| `S3_BUCKET` | — | Required when `s3` |
| `AWS_REGION` | `us-east-1` | S3 region |
| `S3_KEY_PREFIX` | `excellence-workflows` | Key namespace in bucket |
| `S3_PRESIGNED_URL_EXPIRY` | `3600` | Presigned URL TTL (seconds) |

## LocalBackend: No Behavioral Change

`LocalBackend` replicates current behavior exactly:
- `workflow_path(id, *parts)` → `/tmp/excellence_workflows/<id>/<parts>`
- `write_bytes` / `read_bytes` → standard file I/O
- `get_local_path(path)` → returns `path` as-is (already local)
- `get_download_response(path, filename)` → `FileResponse(path)`

## S3Backend

- Uses `boto3.client("s3")`
- `get_local_path(path)` → downloads to `/tmp/s3cache/<hash>/` if not already cached
- `get_download_response(path, filename)` → generates presigned GET URL, returns `RedirectResponse`
- IAM: pods need `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket` on the bucket (via EKS pod identity or instance role)

## Critical Files

- `backend/src/excellence_app/workflow/temp_storage.py` — primary change target
- `backend/src/excellence_app/app/excel_endpoints.py` — upload/download paths
- `backend/src/excellence_app/workflow/workflow.py` — finalize step result write
- `backend/pyproject.toml` — add boto3

## Verification

1. **Local (unchanged behavior):** Run existing workflow end-to-end with `STORAGE_BACKEND=local` (default). Upload file, run pipeline, download result. All existing tests pass: `uv run pytest`.

2. **S3 (new):** Set `STORAGE_BACKEND=s3`, `S3_BUCKET=<test-bucket>`. Run workflow. Verify files appear in S3 console under `excellence-workflows/<workflow_id>/`. Download result via presigned URL.

3. **k8s multi-replica:** Deploy with 2 replicas. Upload to one pod, verify workflow completes when DBOS resumes on the other pod.
