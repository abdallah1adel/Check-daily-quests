# PCPOS AI Model Setup Guide

## Prerequisites
1. **Hugging Face Account**: Sign up at https://huggingface.co
2. **Access Token**: Get from https://huggingface.co/settings/tokens
   - Create a token with "Read" permissions
3. **Python 3.10**: Installed via Homebrew

---

## Quick Setup (Automated)

Run the setup script:
```bash
cd /Users/pcpos/Desktop/PCPOScompanion/PCPOScompanion
./setup_models.sh
```

**What it does:**
1. Installs Hugging Face CLI
2. Prompts for HF token authentication
3. Downloads Granite 3.1 model (your choice of size)
4. Downloads EmotionNet model
5. Installs TTS dependencies

---

## Manual Setup

### 1. Install Hugging Face CLI
```bash
/opt/homebrew/opt/python@3.10/libexec/bin/pip3.10 install huggingface-hub
```

### 2. Login to Hugging Face
```bash
/opt/homebrew/opt/python@3.10/libexec/bin/python3.10 -c "from huggingface_hub import login; login()"
```
*Enter your token when prompted*

### 3. Download Granite Model
```bash
python3.10 << EOF
from huggingface_hub import hf_hub_download

# Choose one:
# Option 1: Smaller model (2GB)
model = "ibm-granite/granite-3.1-3b-a800m-instruct"
filename = "granite-3.1-3b-a800m-instruct-Q4_K_M.gguf"

# Option 2: Larger model (5GB)
# model = "ibm-granite/granite-3.1-8b-instruct"
# filename = "granite-3.1-8b-instruct-Q4_K_M.gguf"

hf_hub_download(
    repo_id=model,
    filename=filename,
    local_dir="Resources/models/llm",
    local_dir_use_symlinks=False
)
EOF
```

### 4. Install TTS Dependencies
```bash
/opt/homebrew/opt/python@3.10/libexec/bin/pip3.10 install TTS torch soundfile flask
```

---

## Add to Xcode

After downloading:
1. Open `PCPOScompanion.xcodeproj`
2. In Xcode sidebar, right-click `Resources/models/llm/`
3. Choose **"Add Files to PCPOScompanion..."**
4. Select the `.gguf` file
5. ✅ Check **"Copy items if needed"**
6. Click **Add**

---

## Testing

### Test GGUF Loading:
```swift
Task {
    print("Model mode: \(LocalLLMService.shared.currentMode)")
}
```

Expected output:
- `"GGUF"` - Successfully loaded
- `"CoreML"` - GGUF not found, using CoreML
- `"Fallback"` - Neither found, using patterns

---

## File Sizes
- **granite-3.1-3b**: ~2GB (recommended for testing)
- **granite-3.1-8b**: ~5GB (better quality)
- **EmotionNet**: ~50MB

---

## Troubleshooting

### "Token required"
Get token from: https://huggingface.co/settings/tokens

### "Model not found"
Some models require accepting terms on Hugging Face first.

### "Permission denied"
Run: `chmod +x setup_models.sh`
