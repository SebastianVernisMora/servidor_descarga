#!/bin/bash
cd /home/sebastianvernis/servidor_descarga
export PATH="$(pwd)/venv/bin:$PATH"
python3 app_optimized.py > dynamic_app.log 2>&1 &
echo $! > app.pid
echo "Aplicación iniciada con PID: $(cat app.pid)"