import torch
import torchaudio
import coremltools as ct
import os

def generate_speaker_encoder():
    print("🚀 Starting Speaker Encoder Generation...")
    
    # 1. Load Pre-trained Wav2Vec2 Model
    print("📥 Downloading Wav2Vec2 base model...")
    bundle = torchaudio.pipelines.WAV2VEC2_ASR_BASE_960H
    original_model = bundle.get_model()
    original_model.eval()
    
    # Wrapper to extract only the tensor output
    class ModelWrapper(torch.nn.Module):
        def __init__(self, model):
            super().__init__()
            self.model = model
            
        def forward(self, x):
            # Wav2Vec2 returns (output, lengths) or similar structure
            # We just want the features
            output = self.model(x)
            # Depending on the specific model version, output might be a tuple or object
            # torchaudio Wav2Vec2 usually returns (features, lengths)
            if isinstance(output, tuple):
                return output[0]
            return output

    model = ModelWrapper(original_model)
    model.eval()
    
    # 2. Trace with Dummy Input
    print("⚡️ Tracing model with dummy input...")
    dummy_input = torch.randn(1, 16000) # 1 second of audio at 16kHz
    traced_model = torch.jit.trace(model, dummy_input)
    
    # 3. Convert to CoreML
    print("🔄 Converting to CoreML format...")
    mlmodel = ct.convert(
        traced_model,
        inputs=[ct.TensorType(name="audio", shape=(1, 16000))],
        outputs=[ct.TensorType(name="embedding")]
    )
    
    # 4. Save
    output_path = "SpeakerEncoder.mlpackage"
    mlmodel.save(output_path)
    print(f"✅ Success! Saved to {os.path.abspath(output_path)}")

if __name__ == "__main__":
    try:
        generate_speaker_encoder()
    except Exception as e:
        print(f"❌ Error: {e}")
        print("Tip: Make sure you installed dependencies: pip install torch torchaudio coremltools")
