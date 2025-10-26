# 🚀 GUÍA DE CONFIGURACIÓN - DESPLIEGUE AUTOMÁTICO

## 📋 PASOS PARA CONFIGURAR AUTO-DEPLOY

### 1. Configurar Sistema Local
```bash
# Ejecutar setup automático
./setup_autodeploy.sh

# Editar secreto del webhook (IMPORTANTE)
nano .env
# Cambiar: WEBHOOK_SECRET=tu-secreto-super-seguro-aqui
```

### 2. Configurar Webhook en GitHub

1. **Ir a tu repositorio en GitHub**
2. **Settings → Webhooks → Add webhook**
3. **Configurar webhook:**
   ```
   Payload URL: http://TU_SERVIDOR_IP:9000/webhook
   Content type: application/json
   Secret: tu-secreto-super-seguro-aqui (mismo que en .env)
   Events: Just the push event
   Active: ✅ Checked
   ```

### 3. Configurar Firewall (si es necesario)
```bash
# Abrir puerto 9000 para webhooks
sudo ufw allow 9000
```

### 4. Verificar Configuración
```bash
# Ver estado del servicio de auto-deploy
sudo systemctl status autodeploy

# Ver logs en tiempo real
tail -f logs/auto_deploy.log

# Probar endpoint de estado
curl http://localhost:9000/status

# Probar despliegue manual
curl -X POST http://localhost:9000/manual-deploy
```

## 🔄 FLUJO DE TRABAJO AUTOMÁTICO

1. **Developer hace push a master/main**
2. **GitHub envía webhook → tu servidor:9000/webhook**
3. **Auto-deploy verifica firma y ejecuta:**
   - `git pull origin master`
   - `pip install -r requirements.txt` (si hay cambios)
   - `./pm2_restart.sh` (si PM2 está corriendo)
   - Health check del servidor en puerto 3000
   - Log del despliegue

## 📊 MONITOREO Y CONTROL

```bash
# Ver historial de despliegues
cat logs/deploy_history.log

# Ver logs detallados
tail -f logs/auto_deploy.log

# Reiniciar servicio si es necesario
sudo systemctl restart autodeploy

# Parar auto-deploy temporalmente
sudo systemctl stop autodeploy
```

## 🔧 PERSONALIZACIÓN AVANZADA

### Cambiar Puerto del Auto-Deploy
```bash
# Editar .env
nano .env
# Cambiar: AUTODEPLOY_PORT=9001

# Reiniciar servicio
sudo systemctl restart autodeploy
```

### Agregar Comandos Post-Deploy
Editar `auto_deploy.py` función `deploy_app()`:
```python
# Ejemplo: limpiar cache después del deploy
success, stdout, stderr = execute_command("curl -X POST http://localhost:3000/cache/clear")
deploy_log.append(f"Cache clear: {'✅ SUCCESS' if success else '⚠️ WARNING'}")
```

### Notificaciones (Opcional)
Agregar notificaciones por Slack/Discord/Email después del deploy exitoso.

## ⚠️ SEGURIDAD

- **WEBHOOK_SECRET**: Debe ser un string aleatorio fuerte (>32 caracteres)
- **Firewall**: Solo abrir puerto 9000 si es necesario (inbound desde GitHub IPs)
- **HTTPS**: Para producción, usar HTTPS con certificado SSL
- **Logs**: Los logs contienen información sensible, proteger acceso

## 🚨 TROUBLESHOOTING

### Auto-deploy no responde
```bash
sudo systemctl status autodeploy
sudo journalctl -u autodeploy -f
```

### Webhook falla verificación
- Verificar que WEBHOOK_SECRET coincida exactamente
- Verificar formato del secreto en GitHub (sin espacios extra)

### Deploy falla
- Verificar permisos de escritura en directorio del repo
- Verificar que PM2 scripts sean ejecutables
- Verificar dependencias de Python instaladas

## 📱 TESTING

```bash
# Simular webhook de GitHub (para testing)
curl -X POST http://localhost:9000/webhook \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -H "X-Hub-Signature-256: sha256=FIRMA_CALCULADA" \
  -d '{"ref":"refs/heads/master","commits":[{"message":"test","author":{"name":"test"}}]}'
```