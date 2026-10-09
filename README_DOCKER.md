Quick Docker setup for ComfyUI

Build (CPU):

```bash
docker build -t comfyui:latest .
```

Run (CPU):

```bash
docker run -d --name comfyui -p 8188:8188 -e HF_AUTO_DOWNLOAD=1 -e HF_TOKEN="$HF_TOKEN" comfyui:latest
```

Using Docker Compose:

```bash
HF_TOKEN=hf_... docker compose up -d --build
```

GPU notes:

- To enable NVIDIA GPU support, install the NVIDIA Container Toolkit on the host and run the container with `--gpus all`:

```bash
docker run --gpus all -d --name comfyui -p 8188:8188 -e HF_AUTO_DOWNLOAD=1 -e HF_TOKEN="$HF_TOKEN" comfyui:latest
```

- The image uses CUDA 13.0 and Python 3.12, and installs PyTorch from the CUDA 13.0 wheel index for newer NVIDIA GPUs. The host still needs a compatible NVIDIA driver and NVIDIA Container Toolkit.
- The build verifies that `comfy-kitchen` exposes `stochastic_rounding_fp8` and `comfy_kitchen.tensor.w4a8_int8_linear`. The check confirms the APIs are installed; ComfyUI only runs those operations when the selected model/quantization path uses them.

Hubface / model downloads:

- The container will run `hubfacedownload.sh` (if present at repository root) when `HF_AUTO_DOWNLOAD` is enabled. Provide a Hugging Face token via `HF_TOKEN` environment variable to download private or gated models.
