#!/bin/bash
# Start both Granite and TTS servers

set -e

echo "🚀 Starting PCPOS AI Servers"
echo "============================"

# Activate Python environment
echo "📦 Activating ml_env..."
source ~/ml_env/bin/activate

# Navigate to script directory
cd "$(dirname "$0")"

# Start Granite Server (Port 5001)
echo "🧠 Starting Granite Server (Port 5001)..."
python granite_server.py &
GRANITE_PID=$!

# Start TTS Server (Port 5002)
echo "🗣️ Starting TTS Server (Port 5002)..."
python tts_server.py &
TTS_PID=$!

echo "✅ Servers started!"
echo "   Granite PID: $GRANITE_PID"
echo "   TTS PID: $TTS_PID"
echo ""
echo "Press Ctrl+C to stop both servers."

# Trap Ctrl+C to kill both processes
trap "kill $GRANITE_PID $TTS_PID; exit" INT

# Wait for processes
wait
