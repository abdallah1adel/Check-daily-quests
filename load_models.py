# load_models.py
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
import os

# -----------------------------
# Granite 1B
# -----------------------------
granite_model_path = "/Users/pcpos/Desktop/MegamanCompanion/granite-3.1-language-models-main"
if not os.path.exists(granite_model_path):
    raise FileNotFoundError(f"Granite model not found at {granite_model_path}")

print(f"Loading Granite model from '{granite_model_path}' ...")
granite_model = AutoModelForCausalLM.from_pretrained(granite_model_path)
granite_model.eval()
granite_tokenizer = AutoTokenizer.from_pretrained(granite_model_path)
print("Granite 1B model loaded successfully!\n")

# -----------------------------
# LLaMA 1B
# -----------------------------
llama_model_path = "/Users/pcpos/Desktop/MegamanCompanion/llama-1b"  # update this path to your local LLaMA folder
if not os.path.exists(llama_model_path):
    raise FileNotFoundError(f"LLaMA model not found at {llama_model_path}")

print(f"Loading LLaMA model from '{llama_model_path}' ...")
llama_model = AutoModelForCausalLM.from_pretrained(llama_model_path)
llama_model.eval()
llama_tokenizer = AutoTokenizer.from_pretrained(llama_model_path)
print("LLaMA 1B model loaded successfully!\n")

# -----------------------------
# Optional: simple test
# -----------------------------
prompt = "Hello world!"

# Granite test
inputs_granite = granite_tokenizer(prompt, return_tensors="pt")
outputs_granite = granite_model.generate(**inputs_granite, max_new_tokens=20)
print("Granite output:", granite_tokenizer.decode(outputs_granite[0]))

# LLaMA test
inputs_llama = llama_tokenizer(prompt, return_tensors="pt")
outputs_llama = llama_model.generate(**inputs_llama, max_new_tokens=20)
print("LLaMA output:", llama_tokenizer.decode(outputs_llama[0]))
