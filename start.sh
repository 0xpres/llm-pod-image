#!/bin/bash
set -e

MODEL_NAME="${MODEL_NAME:-Qwen/Qwen2.5-72B-Instruct-AWQ}"
QUANTIZATION="${QUANTIZATION-awq}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.95}"
TENSOR_PARALLEL_SIZE="${TENSOR_PARALLEL_SIZE:-1}"
HF_CACHE_DIR="${HF_CACHE_DIR:-/workspace/hf-cache}"
WEBUI_DATA_DIR="${WEBUI_DATA_DIR:-/workspace/openwebui-data}"

mkdir -p "$HF_CACHE_DIR" "$WEBUI_DATA_DIR"
export HF_HOME="$HF_CACHE_DIR"

QUANT_ARGS=()
if [ -n "$QUANTIZATION" ]; then
  QUANT_ARGS=(--quantization "$QUANTIZATION")
fi

echo "[start.sh] Subindo vLLM com modelo: $MODEL_NAME (tensor-parallel-size=$TENSOR_PARALLEL_SIZE, quantization='$QUANTIZATION')"
python3 -m vllm.entrypoints.openai.api_server \
  --model "$MODEL_NAME" \
  "${QUANT_ARGS[@]}" \
  --max-model-len "$MAX_MODEL_LEN" \
  --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION" \
  --tensor-parallel-size "$TENSOR_PARALLEL_SIZE" \
  --enable-auto-tool-choice \
  --tool-call-parser hermes \
  --download-dir "$HF_CACHE_DIR" \
  --port 8000 \
  --host 0.0.0.0 &

echo "[start.sh] Aguardando vLLM ficar pronto..."
until curl -sf http://localhost:8000/v1/models > /dev/null 2>&1; do
  sleep 5
done
echo "[start.sh] vLLM pronto."

echo "[start.sh] Subindo OpenWebUI..."
export OPENAI_API_BASE_URL="http://localhost:8000/v1"
export OPENAI_API_KEY="none"
export WEBUI_AUTH="False"
export ENABLE_SIGNUP="false"
export DATA_DIR="$WEBUI_DATA_DIR"

exec open-webui serve --port 8080
