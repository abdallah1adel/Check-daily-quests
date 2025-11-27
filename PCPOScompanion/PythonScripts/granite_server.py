#!/usr/bin/env python3
"""
Granite 3.1 LLM Server
Loads the Granite 3.1 model via HuggingFace transformers and exposes a Flask API
"""

from flask import Flask, request, jsonify
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch
import os
import sys

app = Flask(__name__)

# Global model and tokenizer
model = None
tokenizer = None

def load_model():
    """Load Granite 3.1 model from Resources/models/llm"""
    global model, tokenizer
    
    # Get model path (relative to this script)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(script_dir, "..", "Resources", "models", "llm")
    
    print(f"🧠 Loading Granite 3.1 from: {model_path}")
    
    try:
        # Load tokenizer
        print("📝 Loading tokenizer...")
        tokenizer = AutoTokenizer.from_pretrained(model_path)
        
        # Load model with optimizations
        print("🔄 Loading model (this may take a minute)...")
        model = AutoModelForCausalLM.from_pretrained(
            model_path,
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            device_map="auto" if torch.cuda.is_available() else None,
            low_cpu_mem_usage=True
        )
        
        print("✅ Granite 3.1 loaded successfully!")
        print(f"   Device: {'CUDA' if torch.cuda.is_available() else 'CPU'}")
        print(f"   Model: granite-3.1-3b-a800m-instruct")
        
        return True
        
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return False

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy" if model is not None else "not_loaded",
        "model": "granite-3.1-3b-a800m-instruct"
    })

@app.route('/generate', methods=['POST'])
def generate():
    """
    Generate text from Granite 3.1
    
    Request JSON:
    {
        "prompt": "User input text",
        "max_tokens": 100,
        "temperature": 0.7,
        "system_prompt": "Optional system instruction"
    }
    
    Response JSON:
    {
        "response": "Generated text",
        "prompt_tokens": 10,
        "completion_tokens": 50
    }
    """
    if model is None or tokenizer is None:
        return jsonify({"error": "Model not loaded"}), 503
    
    try:
        # Parse request
        data = request.json
        user_prompt = data.get('prompt', '')
        max_tokens = data.get('max_tokens', 100)
        temperature = data.get('temperature', 0.7)
        system_prompt = data.get('system_prompt', 'You are PCPOS, a helpful AI companion.')
        
        # Build Granite-style prompt
        # Format: ### System:\n{system}\n\n### User:\n{user}\n\n### Assistant:\n
        full_prompt = f"### System:\n{system_prompt}\n\n### User:\n{user_prompt}\n\n### Assistant:\n"
        
        # Tokenize
        inputs = tokenizer(full_prompt, return_tensors="pt")
        input_length = inputs['input_ids'].shape[1]
        
        # Move to device
        if torch.cuda.is_available():
            inputs = {k: v.to('cuda') for k, v in inputs.items()}
        
        # Generate
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_new_tokens=max_tokens,
                temperature=temperature,
                do_sample=True,
                top_p=0.9,
                repetition_penalty=1.1,
                pad_token_id=tokenizer.eos_token_id
            )
        
        # Decode
        full_response = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Extract just the assistant's response
        # Remove the prompt part
        response = full_response[len(full_prompt):].strip()
        
        # Calculate tokens
        output_length = outputs.shape[1]
        completion_tokens = output_length - input_length
        
        return jsonify({
            "response": response,
            "prompt_tokens": input_length,
            "completion_tokens": completion_tokens
        })
        
    except Exception as e:
        print(f"❌ Generation error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/shutdown', methods=['POST'])
def shutdown():
    """Shutdown the server"""
    print("🛑 Shutting down Granite server...")
    func = request.environ.get('werkzeug.server.shutdown')
    if func is None:
        raise RuntimeError('Not running with the Werkzeug Server')
    func()
    return 'Server shutting down...'

if __name__ == '__main__':
    print("=" * 50)
    print("🚀 PCPOS Granite 3.1 LLM Server")
    print("=" * 50)
    
    # Load model on startup
    if not load_model():
        print("Failed to load model. Exiting.")
        sys.exit(1)
    
    print("\n📡 Starting Flask server on http://127.0.0.1:5001")
    print("   Endpoints:")
    print("   - GET  /health")
    print("   - POST /generate")
    print("   - POST /shutdown")
    print("\n✨ Ready for requests!\n")
    
    # Run Flask server
    app.run(host='127.0.0.1', port=5001, debug=False)
