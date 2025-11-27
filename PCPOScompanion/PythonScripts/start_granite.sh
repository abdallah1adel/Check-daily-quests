#!/bin/bash
# Start Granite 3.1 LLM Server
# This script activates the Python environment and starts the Granite server

set -e

echo "🚀 Starting Granite 3.1 LLM Server"
echo "=================================="

# Activate Python environment
echo "📦 Activating ml_env..."
source ~/ml_env/bin/activate

# Check if required packages are installed
echo "🔍 Checking dependencies..."
python -c "import transformers, torch, flask" 2>/dev/null || {
    echo "❌ Missing dependencies. Installing..."
    pip install transformers torch flask
}

# Navigate to script directory
cd "$(dirname "$0")"

echo "✅ Dependencies ready"
echo ""

# Start the server
echo "🧠 Starting Granite server..."
python granite_server.py
