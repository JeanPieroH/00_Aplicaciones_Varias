#!/bin/bash

set -e  # Salir en caso de error

# 1. Descargar get-pip.py
echo "Descargando get-pip.py..."
curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py

# 2. Instalar pip localmente
echo "Instalando pip en ~/.local..."
python3 get-pip.py --user

# 3. Añadir ~/.local/bin al PATH temporalmente para esta sesión
export PATH=$HOME/.local/bin:$PATH

# 4. Instalar virtualenv localmente
echo "Instalando virtualenv..."
pip install --user virtualenv

# 5. Crear entorno virtual con virtualenv
echo "Creando entorno virtual con virtualenv..."
python3 -m virtualenv venv

# 6. Activar entorno virtual
echo "Activando entorno virtual..."
source venv/bin/activate

# 7. Actualizar pip en el entorno virtual
echo "Actualizando pip en entorno virtual..."
pip install --upgrade pip

# 8. Instalar dependencias desde requirements.txt
if [ -f "requirements.txt" ]; then
    echo "Instalando dependencias de requirements.txt..."
    pip install -r requirements.txt
else
    echo "⚠️ Archivo requirements.txt no encontrado. Saltando instalación de dependencias."
fi

echo ""
echo "✅ Entorno virtual creado y listo."
echo "ℹ️ Usa 'source venv/bin/activate' para activarlo en futuras sesiones."
