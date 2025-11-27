#!/bin/bash
# Super Simple Model Download - No interactive prompts

set -e

echo "🤗 PCPOS Model Downloader"
echo "========================="
echo ""
echo "Paste your HuggingFace token and press Enter:"
read -s HF_TOKEN

# Activate environment
source ~/ml_env/bin/activate

echo ""
echo "✅ Logging in..."

# Login non-interactively
export HF_TOKEN
python -c "from huggingface_hub import login; login(token='$HF_TOKEN', add_to_git_credential=True)"

echo ""
echo "🧠 Downloading Granite 3.1 (1B model - ~700MB)..."

# Create directory
mkdir -p Resources/models/llm

# Download 1B model (smaller, faster)
hf download ibm-granite/granite-3.1-1b-a400m-instruct \
  --local-dir Resources/models/llm

echo ""
echo "✅ Done!"
echo ""
echo "Location: Resources/models/llm/"
ls -lh Resources/models/llm/ | head -20
