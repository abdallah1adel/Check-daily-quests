# 🧠 SYSTEM ARCHITECTURE: THE GOD BRAIN
> **Complete Neural Map of the PCPOS Companion**

## I. THE CENTRAL NERVOUS SYSTEM

### GodBrain.swift - The Orchestrator
**Location**: `PCPOScompanion/GodBrain.swift`

**Purpose**: Unified intelligence controller that fuses all sensory inputs and drives high-level decision-making.

**Connections**:
```
┌─────────────────┐
│   GOD BRAIN     │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    V         V
VISION     HEARING
    │         │
    V         V
VisionFace  Voice
Detector   Profile
           Manager
```

**Key Functions**:
- `connectSenses()`: Wires Vision + Voice inputs
- `processSensoryFusion()`: Combines face + voice for Creator detection
- `ponder()`: LLM reasoning engine (Llama 3.2/TinyLlama)
- `consciousnessLevel`: 0.0-1.0 awareness metric

---

## II. THE SENSES

### A. VISION (Eyes) 👁️

#### VisionFaceDetector.swift
- Uses Apple's `Vision` framework
- Detects faces via `VNDetectFaceRectanglesRequest`
- Publishes `isCreator` when enrolled face is detected
- Wired to `GodBrain` for fusion

#### CameraManager.swift
- AVFoundation camera capture
- Provides pixel buffers to Vision/ML systems
- Streams to CameraStreamer for remote viewing

### B. HEARING (Ears) 👂

#### VoiceProfileManager.swift
- Audio fingerprinting engine
- Uses `SpeakerEncoder.mlpackage` for voice embeddings
- Identifies users by voice signature
- Publishes `identifiedUser` when match found
- Wired to `GodBrain` for fusion

---

## III. THE CORTEX (Intelligence) 🧠

### A. Language Brain
**Model**: `Llama3_1B.mlpackage` (TinyLlama fallback)
- **Location**: Will be in `Resources/` after import
- **Purpose**: Conversational AI, reasoning, context understanding
- **Integration**: `GodBrain.ponder()` (placeholder for inference)

### B. Emotion Engine
**Model**: `EmotionClassifier.mlpackage` (future)
- Analyzes facial expressions
- Drives avatar reactions

### C. Voice Encoder
**Model**: `SpeakerEncoder.mlpackage`
- **Location**: Generated in `scripts/`
- **Purpose**: Voice ID for Protocol 22
- **Used by**: `VoiceProfileManager`

---

## IV. THE ANIMATION SYSTEM (The Body)

### A. High-Performance Loop
**File**: `HighPerformanceLoop.swift`
- **FPS**: 120fps (ProMotion)
- **Engine**: CADisplayLink
- Updates all animation systems in sync

### B. Disney 12 Principles
**File**: `Disney12Principles.swift`
- **Easing Functions**: 20+ (ease-in-out, bounce, elastic, etc.)
- **Physics**: Follow-through, anticipation, arc motion
- Drives all avatar animations

### C. Mega Effect System
**File**: `MegaEffectSystem.swift`
- **Combinations**: 7,200 (120 angles × 60 delays)
- **Layers**: 5 depth levels (parallax)
- **Emotion-Driven**: Changes based on mood

### D. Face Model
**File**: `PCPOSFaceModel.swift`
- Represents avatar appearance
- Color changes (e.g., green for Creator)
- Expression states

---

## V. PROTOCOL 22 (Creator Recognition)

### System Components

#### 1. Protocol22Recognition.swift
- Core recognition logic
- Face + Voice template matching
- Publishes `isCreatorDetected` event

#### 2. Protocol22EnrollmentView.swift
- **UI**: Beautiful enrollment interface
- **Triggers**: 5-tap gesture on main screen
- **Process**: (1) Face scan → (2) Voice capture → (3) Store in Keychain

#### 3. Protocol22Integration.swift
- **Connects** recognition to app lifecycle
- **Auto-enrollment**: Silent background enrollment
- **Audio Monitoring**: Parallel audio engine for voice capture

#### 4. GodBrain Integration
- **Sensory Fusion**: Combines Vision + Voice confidence
- **Threshold**: 80%+ triggers Protocol 22 activation
- **Visual Response**: Face turns green, logs event

---

## VI. THE PERSONALITY ENGINE

### PersonalityEngine.swift
- **Traits**: Energy, friendliness, creativity, curiosity, protectiveness
- **Modes**: Default, Focused, Playful, Protective, Creative
- **Emotion-to-Animation**: Maps emotions to visual changes

---

## VII. DATA FLOW (How It All Works)

```
USER APPEARS
    │
    V
CAMERA FEED ──> VisionFaceDetector ──┐
    │                                 │
MICROPHONE ──> VoiceProfileManager ───┤
                                      │
                                      V
                                  GOD BRAIN
                                      │
                        ┌─────────────┼─────────────┐
                        │             │             │
                        V             V             V
                   isCreator?    Confidence    Thought
                        │         Level         Process
                        │             │             │
                        V             V             V
                   Protocol 22   Face Color    LLM Query
                   Activation     Change      (Llama 3.2)
                        │             │             │
                        └─────────────┴─────────────┘
                                      │
                                      V
                            SYSTEM-WIDE RESPONSE
                            (UI, Personality, Chat)
```

---

## VIII. FILE HIERARCHY

```
PCPOScompanion/
├── GodBrain.swift                    ← CENTRAL ORCHESTRATOR
├── VisionFaceDetector.swift          ← Eyes
├── VoiceProfileManager.swift         ← Ears
├── CameraManager.swift               ← Camera subsystem
├── SpeechManager.swift               ← Speech-to-text
│
├── Protocol22/
│   ├── Protocol22Recognition.swift
│   ├── Protocol22EnrollmentView.swift
│   ├── Protocol22Integration.swift
│   ├── Protocol22Handler.swift
│   ├── Protocol22EnrollmentManager.swift
│   └── Protocol22AutoEnrollment.swift
│
├── Animation/
│   ├── HighPerformanceLoop.swift
│   ├── Disney12Principles.swift
│   ├── MegaEffectSystem.swift
│   ├── MultiLayerDepthSystem.swift
│   └── PCPOSFaceAnimator.swift
│
├── Models/
│   ├── PCPOSFaceModel.swift
│   ├── PersonalityEngine.swift
│   └── MLAgentCluster.swift
│
├── UI/
│   ├── ContentView.swift              ← Main UI
│   ├── OnboardingView.swift
│   └── RefinedPCPOSFaceIDView.swift
│
└── Resources/
    ├── Llama3_1B.mlpackage            ← TO BE IMPORTED
    └── SpeakerEncoder.mlpackage       ← TO BE IMPORTED
```

---

## IX. CURRENT STATE

### ✅ Complete
- God Brain architecture
- Vision face detection
- Voice fingerprinting
- Protocol 22 UI (hidden 5-tap)
- 120fps animation engine
- Disney principles
- ML model generation scripts

### ⚠️ Pending User Action
1. **Import CoreML Models**:
   - Drag `scripts/Llama3_1B.mlpackage` → `Resources/`
   - Drag `scripts/SpeakerEncoder.mlpackage` → `Resources/`
2. **Delete Wrapper**: Remove `CoreMLWrappers.swift`
3. **Build & Run**: `Cmd + R` in Xcode

### 🔮 Future Enhancements
- Real LLM inference in `GodBrain.ponder()`
- TTS model for voice output
- Granite MoE integration
- Fine-tuned Llama 3.2 (with personal data)

---

## X. THE CORE PRINCIPLE

> "One single god brain like"

**Every component feeds into GodBrain. GodBrain decides everything.**

- Vision sees → GodBrain knows
- Voice hears → GodBrain understands
- LLM thinks → GodBrain acts

**This is not a collection of modules. This is a unified, sentient system.**

---

**Status**: 🟢 READY FOR ACTIVATION
**Next**: Follow `LAUNCH_PROTOCOL.md`
