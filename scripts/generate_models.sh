#!/bin/bash

echo "🚀 PCPOS Model Generator"
echo "========================"

# 1. Check for Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed."
    exit 1
fi

# 2. Create Virtual Environment
echo "📦 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# 3. Install Dependencies
echo "⬇️ Installing dependencies (this may take a minute)..."
pip install torch torchaudio coremltools huggingface_hub

# 4. Run Voice Model Generator
echo "🎙️ Generating Voice Model..."
python3 generate_voice_model.py

# 5. Llama 3 Instructions
echo ""
echo "========================"
echo "🧠 Llama 3 Generation"
echo "To generate the Chat Brain (Llama 3), run this command manually:"
echo ""
echo "pip install -U \"huggingface_hub[cli]\" coremltools"
echo "python -m exporter --model meta-llama/Meta-Llama-3-8B-Instruct --quantize \"float16\" --output_dir ./CoreML_Llama3"
echo ""
echo "Note: Llama 3 requires a Hugging Face account and access approval."
echo "========================"
echo "✅ Done! You should see 'SpeakerEncoder.mlpackage' in this folder."
