#!/usr/bin/env python3
"""
Sistema de despliegue automático para nuevos PR fusionados
Escucha webhooks de GitHub y ejecuta despliegue automático
"""

import os
import sys
import json
import hmac
import hashlib
import subprocess
import logging
from datetime import datetime
from flask import Flask, request, jsonify, abort

app = Flask(__name__)

# Configuración
WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET', 'your-github-webhook-secret')
REPO_PATH = '/home/admin/servidor_descarga'
LOG_FILE = os.path.join(REPO_PATH, 'logs/auto_deploy.log')

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)

def verify_signature(payload_body, signature_header):
    """Verifica la firma del webhook de GitHub"""
    if not signature_header:
        return False
    
    sha_name, signature = signature_header.split('=')
    if sha_name != 'sha256':
        return False
    
    mac = hmac.new(
        WEBHOOK_SECRET.encode('utf-8'),
        msg=payload_body,
        digestmod=hashlib.sha256
    )
    return hmac.compare_digest(mac.hexdigest(), signature)

def execute_command(cmd, cwd=REPO_PATH):
    """Ejecuta un comando y retorna el resultado"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minutos timeout
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Comando timeout después de 5 minutos"
    except Exception as e:
        return False, "", str(e)

def deploy_app():
    """Ejecuta el proceso completo de despliegue"""
    deploy_log = []
    
    # 1. Git pull para obtener últimos cambios
    logging.info("🔄 Iniciando git pull...")
    success, stdout, stderr = execute_command("git pull origin master")
    deploy_log.append(f"Git pull: {'✅ SUCCESS' if success else '❌ FAILED'}")
    if not success:
        logging.error(f"Git pull failed: {stderr}")
        return False, deploy_log
    
    # 2. Instalar dependencias si hay cambios
    if os.path.exists(os.path.join(REPO_PATH, 'requirements.txt')):
        logging.info("📦 Instalando dependencias...")
        success, stdout, stderr = execute_command("pip install -r requirements.txt")
        deploy_log.append(f"Dependencies: {'✅ SUCCESS' if success else '⚠️ WARNING'}")
    
    # 3. Reiniciar PM2 si está corriendo
    success, stdout, stderr = execute_command("./pm2_status.sh")
    if success and "background_map_generator" in stdout:
        logging.info("🔄 Reiniciando generador PM2...")
        success, stdout, stderr = execute_command("./pm2_restart.sh")
        deploy_log.append(f"PM2 restart: {'✅ SUCCESS' if success else '❌ FAILED'}")
    
    # 4. Verificar que el servidor responda
    import time
    time.sleep(5)  # Esperar a que el servidor se inicie
    
    success, stdout, stderr = execute_command(
        "python3 -c \"import requests; print(requests.get('http://localhost:3000/api/info').status_code)\""
    )
    deploy_log.append(f"Health check: {'✅ SUCCESS' if success and '200' in stdout else '❌ FAILED'}")
    
    # 5. Log del despliegue
    timestamp = datetime.now().isoformat()
    with open(os.path.join(REPO_PATH, 'logs/deploy_history.log'), 'a') as f:
        f.write(f"{timestamp} - Auto Deploy: {deploy_log}\n")
    
    return True, deploy_log

@app.route('/webhook', methods=['POST'])
def github_webhook():
    """Endpoint para recibir webhooks de GitHub"""
    
    # Verificar firma del webhook
    signature_header = request.headers.get('X-Hub-Signature-256')
    if not verify_signature(request.data, signature_header):
        logging.warning("❌ Firma de webhook inválida")
        abort(401)
    
    # Obtener evento
    event = request.headers.get('X-GitHub-Event')
    payload = request.get_json()
    
    if not payload:
        logging.warning("❌ Payload vacío")
        abort(400)
    
    # Solo procesar eventos de push a master/main
    if event == 'push':
        ref = payload.get('ref', '')
        if ref in ['refs/heads/master', 'refs/heads/main']:
            
            # Obtener información del commit
            commits = payload.get('commits', [])
            if commits:
                commit_msg = commits[-1].get('message', 'No message')
                author = commits[-1].get('author', {}).get('name', 'Unknown')
                logging.info(f"🚀 Nuevo commit de {author}: {commit_msg}")
            
            # Ejecutar despliegue
            logging.info("🔥 Iniciando despliegue automático...")
            success, deploy_log = deploy_app()
            
            status = "success" if success else "failed"
            logging.info(f"📋 Despliegue {status}: {deploy_log}")
            
            return jsonify({
                'status': status,
                'message': f'Auto deploy {"completed" if success else "failed"}',
                'deploy_log': deploy_log,
                'timestamp': datetime.now().isoformat()
            })
    
    # Para otros eventos, solo log
    logging.info(f"📨 Webhook recibido: {event}")
    return jsonify({'status': 'ignored', 'event': event})

@app.route('/status', methods=['GET'])
def status():
    """Endpoint de estado del sistema de auto-deploy"""
    return jsonify({
        'status': 'running',
        'repo_path': REPO_PATH,
        'log_file': LOG_FILE,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/manual-deploy', methods=['POST'])
def manual_deploy():
    """Endpoint para ejecutar despliegue manual"""
    logging.info("🔧 Despliegue manual iniciado...")
    success, deploy_log = deploy_app()
    
    return jsonify({
        'status': 'success' if success else 'failed',
        'message': f'Manual deploy {"completed" if success else "failed"}',
        'deploy_log': deploy_log,
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    # Crear directorio de logs si no existe
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    
    logging.info("🚀 Iniciando servidor de auto-deploy...")
    logging.info(f"📂 Repo path: {REPO_PATH}")
    logging.info(f"📝 Log file: {LOG_FILE}")
    
    # Puerto diferente para evitar conflictos
    port = int(os.environ.get('AUTODEPLOY_PORT', 9000))
    app.run(host='0.0.0.0', port=port, debug=False)