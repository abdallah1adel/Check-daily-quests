import torch
import coremltools as ct
from transformers import AutoModelForCausalLM, AutoTokenizer
import os

def convert_llama():
    print("🧠 Loading Llama 3.2 1B-Instruct...")
    model_id = "meta-llama/Llama-3.2-1B-Instruct"
    
    try:
        tokenizer = AutoTokenizer.from_pretrained(model_id)
        model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float32)
        model.eval()
    except Exception as e:
        print(f"❌ Error loading {model_id}: {e}")
        if "403" in str(e) or "gated" in str(e).lower():
            print("\n⚠️ ACCESS DENIED: You have not accepted the license for Llama 3.2 on Hugging Face.")
            print("👉 Go here to accept it: https://huggingface.co/meta-llama/Llama-3.2-1B-Instruct")
            print("\n🔄 Falling back to 'TinyLlama-1.1B-Chat' so you have a working brain...")
            model_id = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
            try:
                tokenizer = AutoTokenizer.from_pretrained(model_id)
                model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float32)
                model.eval()
                print(f"✅ Successfully loaded fallback model: {model_id}")
            except Exception as fallback_error:
                print(f"❌ Fallback failed too: {fallback_error}")
                return
        else:
            return

    print("⚡️ Creating Traceable Wrapper...")
    class LlamaWrapper(torch.nn.Module):
        def __init__(self, model):
            super().__init__()
            self.model = model
        
        def forward(self, input_ids):
            outputs = self.model(input_ids)
            return outputs.logits

    wrapper = LlamaWrapper(model)
    wrapper.eval()

    # Dummy Input
    print("🎲 Tracing model...")
    example_input = torch.randint(0, tokenizer.vocab_size, (1, 10)) # Batch 1, Seq 10
    traced_model = torch.jit.trace(wrapper, example_input)

    # Convert
    print("🔄 Converting to CoreML (Float16)...")
    # Define flexible input shape
    # coremltools 7+ uses 'shape' directly with EnumeratedShapes or RangeDim
    # For simple dynamic shape, we pass the tuple with RangeDim directly to TensorType
    input_shape = ct.Shape(shape=(1, ct.RangeDim(1, 2048)))
    
    mlmodel = ct.convert(
        traced_model,
        inputs=[ct.TensorType(name="input_ids", shape=input_shape, dtype=int)],
        outputs=[ct.TensorType(name="logits")],
        compute_units=ct.ComputeUnit.CPU_AND_NE,
        minimum_deployment_target=ct.target.iOS16
    )

    output_path = "Llama3_1B.mlpackage"
    mlmodel.save(output_path)
    print(f"✅ Saved Llama 3.2 1B to {output_path}")

if __name__ == "__main__":
    convert_llama()
