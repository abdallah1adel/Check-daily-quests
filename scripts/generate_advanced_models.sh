#!/bin/bash

echo "🚀 PCPOS Brain Generator (Advanced)"
echo "==================================="

# 1. Activate Environment
source venv/bin/activate

# 2. Install Advanced Exporters
echo "⬇️ Installing Optimum & Exporters..."
pip install --upgrade pip
pip install "optimum[exporters]" "git+https://github.com/huggingface/transformers.git" accelerate sentencepiece protobuf

# 3. Login Check
echo ""
echo "🔐 HUGGING FACE AUTH CHECK"
echo "If the download fails with 401/403, please run this command in terminal before the script:"
echo "export HF_TOKEN='your_token_here'"
echo ""

# 4. Generate Llama 3.2 1B (The Chat Brain)
echo ""
echo "🧠 Generating Llama 3.2 1B (Native CoreML)..."
python3 generate_llama_coreml.py

# 5. Generate TTS Model (The Voice)
echo ""
echo "🗣️ Generating TTS Model (SpeechT5)..."
python3 generate_tts_coreml.py

echo ""
echo "✅ Done!"
echo "1. Drag 'Llama3_1B.mlpackage' into Xcode Resources."
echo "2. Drag 'SpeechT5_Acoustic.mlpackage' into Xcode Resources."
