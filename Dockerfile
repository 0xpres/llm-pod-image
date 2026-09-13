FROM vllm/vllm-openai:latest

# Open WebUI e dependencias de healthcheck
RUN pip install --no-cache-dir open-webui && \
    apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080

ENTRYPOINT ["/start.sh"]
