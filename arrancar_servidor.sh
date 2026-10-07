#!/usr/bin/env bash
# ============================================
#  Lubricantes Arca - Arrancar la API (Backend)
#  Uso:  ./arrancar_servidor.sh
# ============================================

cd "$(dirname "$0")"

echo "⏳ Deteniendo servidor anterior (si existe)..."
if [ -f .runtime/api.pid ]; then
  kill "$(cat .runtime/api.pid)" 2>/dev/null || true
fi
pkill -f 'uvicorn api:app' 2>/dev/null || true
sleep 1

echo "⏳ Activando entorno virtual..."
source .venv/bin/activate

echo "🚀 Iniciando servidor de Lubricantes Arca..."
echo "   PC:      http://127.0.0.1:8000"
echo "   Celular: usa la IP local mostrada por el servidor"
echo "   (Mantén esta terminal abierta. Para detener: Ctrl + C)"
echo "----------------------------------------------"
cd python_backend
python run.py