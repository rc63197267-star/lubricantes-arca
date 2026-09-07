FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app/python_backend

COPY python_backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY python_backend/ ./

# Render proporciona PORT automáticamente; 8000 sirve para ejecutar localmente.
ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "exec uvicorn api:app --host 0.0.0.0 --port ${PORT:-8000}"]