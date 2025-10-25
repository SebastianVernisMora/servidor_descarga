# 🚀 Comandos para SSL en AWS EC2

## Dominio: `ec2-44-195-68-60.compute-1.amazonaws.com`

### 1. Ejecutar configuración automática
```bash
sudo ./setup_aws_ssl.sh
```

### 2. Si prefieres paso a paso:

#### Instalar dependencias
```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

#### Iniciar aplicación Flask (si no está corriendo)
```bash
nohup python3 app_optimized.py > app.log 2>&1 &
```

#### Configurar nginx
```bash
sudo tee /etc/nginx/sites-available/prime-viz << 'EOF'
server {
    listen 80;
    server_name ec2-44-195-68-60.compute-1.amazonaws.com;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/prime-viz /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

#### Obtener certificado SSL
```bash
sudo certbot --nginx -d ec2-44-195-68-60.compute-1.amazonaws.com --agree-tos --email admin@amazonaws.com
```

### 3. Verificación post-instalación

#### Comprobar servicios
```bash
sudo systemctl status nginx
sudo systemctl status certbot.timer
```

#### Verificar certificado
```bash
sudo certbot certificates
```

#### Probar renovación
```bash
sudo certbot renew --dry-run
```

### 4. Acceso final
- 🌐 **HTTP**: `http://ec2-44-195-68-60.compute-1.amazonaws.com` (redirige a HTTPS)
- 🔒 **HTTPS**: `https://ec2-44-195-68-60.compute-1.amazonaws.com`

### 5. Logs útiles
```bash
# Logs de nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Log de la aplicación Flask
tail -f /home/admin/app.log

# Logs de certbot
sudo journalctl -u certbot.timer
```

### 6. Troubleshooting

#### Si nginx falla al iniciar:
```bash
sudo nginx -t  # Verificar configuración
sudo systemctl status nginx  # Ver error específico
```

#### Si certbot falla:
```bash
# Verificar conectividad
curl -I http://ec2-44-195-68-60.compute-1.amazonaws.com

# Limpiar certificados anteriores si existen
sudo certbot delete --cert-name ec2-44-195-68-60.compute-1.amazonaws.com
```

#### AWS Security Groups:
Asegúrate de que el Security Group permita:
- Puerto 80 (HTTP) desde 0.0.0.0/0
- Puerto 443 (HTTPS) desde 0.0.0.0/0