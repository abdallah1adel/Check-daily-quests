#!/bin/bash
# Hugging Face Model Setup Script
# Downloads AI models for PCPOS Companion

set -e

echo "🤗 PCPOS AI Model Setup"
echo "======================="

# Use Homebrew Python 3.10
PYTHON="/opt/homebrew/opt/python@3.10/libexec/bin/python3.10"
PIP="/opt/homebrew/opt/python@3.10/libexec/bin/pip3.10"

# Check if Python 3.10 exists
if [ ! -f "$PYTHON" ]; then
    echo "❌ Python 3.10 not found at $PYTHON"
    echo "Install with: brew install python@3.10"
    exit 1
fi

echo "✅ Using Python 3.10: $PYTHON"

# Install Hugging Face CLI
echo ""
echo "📦 Installing Hugging Face Hub..."
$PIP install --upgrade huggingface-hub

# Login to Hugging Face
echo ""
echo "🔐 Hugging Face Login"
echo "You'll need your HF token from: https://huggingface.co/settings/tokens"
echo ""
$PYTHON -c "from huggingface_hub import login; login()"

# Create models directory
MODELS_DIR="$(pwd)/Resources/models"
mkdir -p "$MODELS_DIR/llm"
mkdir -p "$MODELS_DIR/vision"
mkdir -p "$MODELS_DIR/tts"

echo ""
echo "📂 Models directory: $MODELS_DIR"

# Download Granite 3.1 (GGUF)
echo ""
echo "🧠 Downloading Granite 3.1 Model..."
echo "Choose model size:"
echo "1) granite-3.1-3b-a800m (smaller, ~2GB)"
echo "2) granite-3.1-8b (larger, ~5GB)"
read -p "Enter choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    MODEL="ibm-granite/granite-3.1-3b-a800m-instruct"
    FILENAME="granite-3.1-3b-a800m-instruct-Q4_K_M.gguf"
elif [ "$choice" = "2" ]; then
    MODEL="ibm-granite/granite-3.1-8b-instruct"
    FILENAME="granite-3.1-8b-instruct-Q4_K_M.gguf"
else
    echo "❌ Invalid choice"
    exit 1
fi

echo "Downloading $MODEL..."
$PYTHON -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='$MODEL',
    filename='$FILENAME',
    local_dir='$MODELS_DIR/llm',
    local_dir_use_symlinks=False
)
print('✅ Model downloaded')
"

# Download EmotionNet (Vision)
echo ""
echo "👁️ Downloading EmotionNet Model..."
$PYTHON -c "
from huggingface_hub import hf_hub_download
try:
    hf_hub_download(
        repo_id='dima806/facial_emotions_image_detection',
        filename='model.pkl',
        local_dir='$MODELS_DIR/vision',
        local_dir_use_symlinks=False
    )
    print('✅ EmotionNet downloaded')
except Exception as e:
    print(f'⚠️ EmotionNet not available: {e}')
"

# Install TTS dependencies
echo ""
echo "🎙️ Installing TTS Dependencies..."
$PIP install TTS torch soundfile flask

echo ""
echo "✅ Setup Complete!"
echo ""
echo "Downloaded models:"
ls -lh "$MODELS_DIR/llm/"
echo ""
echo "⚠️ Important: Add these files to Xcode:"
echo "1. Open Xcode project"
echo "2. Right-click 'Resources/models/llm/'"
echo "3. Add Files... → Select .gguf file"
echo "4. Check 'Copy items if needed'"
