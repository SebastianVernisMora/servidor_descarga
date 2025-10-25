# 🔐 Configuración SSL con Let's Encrypt

## Requisitos Previos
1. **Dominio válido** apuntando a la IP del servidor: `172.31.7.132`
2. **Acceso root** al servidor
3. **Puertos abiertos**: 80 (HTTP) y 443 (HTTPS)

## Pasos para Configurar SSL

### 1. Configurar DNS
Antes de continuar, asegúrate de que tu dominio apunte a la IP del servidor:
```bash
# Verificar resolución DNS
nslookup tu-dominio.com
dig tu-dominio.com A
```

### 2. Ejecutar Script de Configuración
```bash
sudo ./setup_ssl.sh
```

El script realizará:
- ✅ Instalación de nginx y certbot
- ✅ Configuración de proxy reverso
- ✅ Obtención de certificado SSL
- ✅ Configuración de renovación automática

### 3. Iniciar Aplicación SSL-Ready
```bash
python3 update_app_ssl.py
```

## Configuración Manual (Alternativa)

Si prefieres configurar manualmente:

### Instalar dependencias
```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

### Configurar nginx
```bash
sudo nano /etc/nginx/sites-available/prime-viz
```

### Obtener certificado
```bash
sudo certbot --nginx -d tu-dominio.com
```

## Verificación

### Comprobar certificado
```bash
sudo certbot certificates
```

### Verificar renovación automática
```bash
sudo certbot renew --dry-run
```

### Estado de servicios
```bash
sudo systemctl status nginx
sudo systemctl status certbot.timer
```

## Acceso Final

Una vez configurado:
- 🌐 **HTTP**: `http://tu-dominio.com` (redirige automáticamente a HTTPS)
- 🔒 **HTTPS**: `https://tu-dominio.com` (acceso seguro)
- 📱 **Aplicación**: Totalmente funcional con SSL/TLS

## Troubleshooting

### Error: Dominio no resuelve
```bash
# Verificar DNS
dig +short tu-dominio.com
```

### Error: Puerto no accesible
```bash
# Verificar firewall
sudo ufw status
sudo ufw allow 80
sudo ufw allow 443
```

### Error: Certificado expirado
```bash
# Renovar manualmente
sudo certbot renew
```