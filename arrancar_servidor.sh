#!/usr/bin/env bash
# ============================================
#  Lubricantes Arca - Arrancar la API (Backend)
#  Uso:  ./arrancar_servidor.sh
# ============================================

cd "$(dirname "$0")"

echo "⏳ Deteniendo servidor anterior (si existe)..."
pkill -f 'uvicorn api:app' 2>/dev/null
sleep 1

echo "⏳ Activando entorno virtual..."
source .venv/bin/activate

echo "🚀 Iniciando servidor en http://127.0.0.1:8000 ..."
echo "   (Mantén esta terminal abierta. Para detener: Ctrl + C)"
echo "----------------------------------------------"
cd python_backend
python -m uvicorn api:app --host 127.0.0.1 --port 8000