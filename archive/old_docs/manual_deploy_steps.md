# 🚀 Manual Deployment Steps for ssh-alibaba

## Option 1: Single Command Deployment

```bash
# Connect to your server via ssh-alibaba
ssh-alibaba

# Once connected, run this single command to deploy everything:
curl -fsSL https://raw.githubusercontent.com/your-repo/deploy.sh | sudo bash
```

## Option 2: Step-by-Step Manual Deployment

### Step 1: Connect to Server
```bash
ssh-alibaba
```

### Step 2: Update System
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv nginx git
```

### Step 3: Create Application Directory
```bash
sudo mkdir -p /var/www/prime-visualization
cd /var/www/prime-visualization
```

### Step 4: Set Up Python Environment
```bash
sudo python3 -m venv venv
sudo chown -R $USER:$USER venv
source venv/bin/activate
pip install Flask numpy matplotlib scipy gunicorn
```

### Step 5: Create Application File
```bash
sudo nano app.py
```

Copy the content from the deploy.sh script (the app.py section) into this file.

### Step 6: Create HTML Template
```bash
sudo mkdir templates
sudo nano templates/index.html
```

Copy the HTML content from the deploy.sh script into this file.

### Step 7: Configure Gunicorn
```bash
sudo nano gunicorn.conf.py
```

Add the Gunicorn configuration from the deploy script.

### Step 8: Create Systemd Service
```bash
sudo nano /etc/systemd/system/prime-visualization.service
```

Copy the systemd service configuration from the deploy script.

### Step 9: Configure Nginx
```bash
sudo nano /etc/nginx/sites-available/prime-visualization
```

Copy the Nginx configuration from the deploy script.

```bash
sudo ln -sf /etc/nginx/sites-available/prime-visualization /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### Step 10: Set Permissions and Start Services
```bash
sudo chown -R www-data:www-data /var/www/prime-visualization
sudo chmod -R 755 /var/www/prime-visualization

sudo systemctl daemon-reload
sudo systemctl enable prime-visualization
sudo systemctl start prime-visualization
sudo systemctl restart nginx
```

### Step 11: Verify Deployment
```bash
systemctl status prime-visualization
systemctl status nginx
curl -I http://localhost
```

## Option 3: Quick Deploy with Copy-Paste

### Copy the entire deploy.sh script content and paste it into a file on the server:

```bash
# On your server after ssh-alibaba:
cat > deploy.sh << 'EOF'
[PASTE THE ENTIRE DEPLOY.SH CONTENT HERE]
EOF

chmod +x deploy.sh
sudo ./deploy.sh
```

## 🔍 Verification Commands

After deployment, run these to verify everything is working:

```bash
# Check application status
curl -I http://localhost
curl -I http://$(curl -s ifconfig.me)

# Check services
systemctl status prime-visualization nginx

# View logs
journalctl -u prime-visualization -n 20
```

## 🌐 Access Your Application

- **Local**: `http://localhost`
- **External**: `http://YOUR_SERVER_IP`
- **With domain**: `http://yourdomain.com` (if DNS is configured)

The application should be accessible and fully functional with the Spanish interface for prime number visualization!