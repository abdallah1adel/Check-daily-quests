import os
import sys
import logging
from flask import Flask, request, send_file, jsonify
import torch
from TTS.api import TTS
import soundfile as sf
import tempfile

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global TTS Model
tts = None

def load_model():
    global tts
    try:
        device = "cuda" if torch.cuda.is_available() else "cpu"
        # Check for MPS (Apple Silicon)
        if torch.backends.mps.is_available():
            device = "mps"
            
        logger.info(f"Loading XTTS v2 on {device}...")
        # Init TTS with the target model
        tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(device)
        logger.info("XTTS v2 Loaded Successfully!")
    except Exception as e:
        logger.error(f"Failed to load TTS model: {e}")
        sys.exit(1)

@app.route('/status', methods=['GET'])
def status():
    return jsonify({"status": "ready" if tts else "loading", "device": str(tts.device) if tts else "none"})

@app.route('/tts', methods=['POST'])
def generate_speech():
    if not tts:
        return jsonify({"error": "Model not loaded"}), 503

    data = request.json
    text = data.get("text")
    speaker_wav = data.get("speaker_wav", "reference_audio/pcpos_ref.wav") # Path to reference audio
    language = data.get("language", "en")

    if not text:
        return jsonify({"error": "Missing 'text' parameter"}), 400

    try:
        # Generate to a temp file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_wav:
            output_path = temp_wav.name
            
        # Run Inference
        # Note: speaker_wav must exist. If not, we might need a default fallback or embedding.
        # For now, assuming we provide a valid path or use a default provided by the package if available.
        # XTTS requires a speaker reference.
        
        # Check if reference exists, if not use a default from the library if possible or error out
        if not os.path.exists(speaker_wav):
             # Fallback to a dummy generation if no reference (might fail depending on API)
             # Ideally, we should ship a 'default_voice.wav' with the app
             return jsonify({"error": f"Speaker reference file not found: {speaker_wav}"}), 400

        tts.tts_to_file(text=text, speaker_wav=speaker_wav, language=language, file_path=output_path)

        return send_file(output_path, mimetype="audio/wav")

    except Exception as e:
        logger.error(f"TTS Generation Error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    load_model()
    # Run on localhost:5001 to avoid conflict with AirPlay receiver (5000)
    app.run(host='127.0.0.1', port=5002)
