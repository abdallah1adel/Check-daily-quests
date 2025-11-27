#!/bin/bash
# Simplified Model Download - Uses your existing ml_env

set -e

echo "🤗 PCPOS Model Downloader (ml_env version)"
echo "=========================================="

# Activate your existing environment
source ~/ml_env/bin/activate

echo "✅ Using Python from ml_env"
python --version

# Step 1: Login to Hugging Face
echo ""
echo "🔐 Step 1: Hugging Face Authentication"
echo "You'll be asked for your token. Paste it and press Enter."
echo ""

python << 'PYEOF'
from huggingface_hub import login
login()
PYEOF

# Step 2: Download Granite Model
echo ""
echo "🧠 Step 2: Downloading Granite 3.1 Model"
echo "Choose size:"
echo "1) 3B (smaller, ~2GB) - Recommended"
echo "2) 8B (larger, ~5GB)"
read -p "Enter choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    REPO="ibm-granite/granite-3.1-3b-a800m-instruct"
elif [ "$choice" = "2" ]; then
    REPO="ibm-granite/granite-3.1-8b-instruct"
else
    echo "❌ Invalid choice"
    exit 1
fi

# Create destination directory
mkdir -p Resources/models/llm

echo "Downloading from: $REPO"
echo "Destination: Resources/models/llm/"

# Download using HF CLI
hf download "$REPO" --local-dir Resources/models/llm --local-dir-use-symlinks False

echo ""
echo "✅ Download Complete!"
echo ""
echo "📁 Model location:"
ls -lh Resources/models/llm/
echo ""
echo "🎯 Next: Add the .gguf file to Xcode"
