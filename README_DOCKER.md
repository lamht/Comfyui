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

- Some CUDA-based images may be preferred for maximum compatibility; adjust `FROM` in the `Dockerfile` accordingly if you need a CUDA base image.

Hubface / model downloads:

- The container will run `hubfacedownload.sh` (if present at repository root) when `HF_AUTO_DOWNLOAD` is enabled. Provide a Hugging Face token via `HF_TOKEN` environment variable to download private or gated models.
