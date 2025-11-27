# Backend API Stub for Federated Learning

## POST /api/v1/learning-graphs/submit

### Purpose
Receives encrypted learning graphs from PCPOS devices, validates privacy guarantees, and triggers model retraining.

### Implementation (Python/FastAPI)

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import hmac
import hashlib
from datetime import datetime

app = FastAPI()

class EncryptedGraphRequest(BaseModel):
    deviceIdHash: str
    appVersion: str
    modelVersion: str
    encryptedData: str  # Base64
    signature: str      # Base64
    timestamp: str

class SubmitResponse(BaseModel):
    status: str
    next_model_version: str
    message: str

@app.post("/api/v1/learning-graphs/submit", response_model=SubmitResponse)
async def submit_learning_graph(request: EncryptedGraphRequest):
    """
    Receives encrypted learning graph from device.
    
    Privacy guarantees:
    - Validates HMAC signature
    - Verifies differential privacy was applied
    - Stores only anonymized patterns
    """
    
    # 1. Validate signature
    if not validate_signature(request.encryptedData, request.signature):
        raise HTTPException(status_code=401, detail="Invalid signature")
    
    # 2. Decrypt (server has key)
    try:
        graph_data = decrypt_graph(request.encryptedData)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Decryption failed: {str(e)}")
    
    # 3. Verify privacy guarantees
    if not verify_differential_privacy(graph_data):
        raise HTTPException(status_code=403, detail="Privacy violation detected")
    
    # 4. Store in database
    await store_graph(
        device_id_hash=request.deviceIdHash,
        graph=graph_data,
        timestamp=datetime.fromisoformat(request.timestamp)
    )
    
    # 5. Check if we should trigger retraining
    graph_count = await get_pending_graph_count()
    if graph_count >= 1000:  # Threshold for retraining
        await trigger_retraining_pipeline()
    
    return SubmitResponse(
        status="accepted",
        next_model_version="granite-3b-v1",
        message="Graph received and validated"
    )

def validate_signature(data: str, signature: str) -> bool:
    """Validate HMAC signature"""
    # In production, use proper key management
    secret_key = get_secret_key()
    expected_sig = hmac.new(secret_key, data.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected_sig, signature)

def decrypt_graph(encrypted_data: str) -> dict:
    """Decrypt learning graph"""
    # Implement AES-256 decryption
    pass

def verify_differential_privacy(graph: dict) -> bool:
    """
    Verify that differential privacy was properly applied.
    Checks:
    - Emotions are bucketed (not exact values)
    - No raw text present
    - Noise added to metrics
    """
    # Implement privacy verification logic
    pass

async def store_graph(device_id_hash: str, graph: dict, timestamp: datetime):
    """Store graph in secure database"""
    # Implement DB storage (PostgreSQL/MongoDB)
    pass

async def get_pending_graph_count() -> int:
    """Get count of graphs waiting for aggregation"""
    # Implement DB query
    pass

async def trigger_retraining_pipeline():
    """Trigger model retraining with aggregated graphs"""
    # Implement pipeline trigger (e.g., Airflow DAG, Kubernetes Job)
    pass

def get_secret_key() -> bytes:
    """Get secret key from secure storage (e.g., AWS Secrets Manager)"""
    pass
```

---

## GET /api/v1/models/latest

### Purpose
Returns latest model version info for devices to check for updates.

```python
@app.get("/api/v1/models/latest")
async def get_latest_model():
    return {
        "version": "granite-3b-v1",
        "created_at": "2025-01-15T00:00:00Z",
        "delta_size_mb": 150,
        "improvements": [
            "Better time/date handling",
            "Improved emotion recognition",
            "Faster simple queries"
        ],
        "download_url": "https://cdn.example.com/models/granite-3b-v1-delta.bin"
    }
```

---

## Deployment

### Requirements
- **Server**: AWS/GCP with GPU (for retraining)
- **Database**: PostgreSQL for graph storage
- **Storage**: S3/GCS for model files
- **CDN**: CloudFront/CloudCDN for model distribution

### Estimated Costs (Monthly)
- Compute (GPU for retraining): $500-1500
- Storage (graphs + models): $50-200
- Bandwidth (model distribution): $100-500
- **Total**: ~$650-2200/month

---

## Next Steps

1. **User**: Set up server infrastructure
2. **Agent**: Implement client-side upload logic
3. **Both**: Test end-to-end flow
4. **User**: Deploy and monitor
