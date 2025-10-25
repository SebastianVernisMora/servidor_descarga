# 🚀 Deployment Guide - Prime Visualization App

## 📋 Prerequisites

Before deploying, ensure you have:
- Access to a remote server (Ubuntu/Debian recommended)
- SSH access with sudo privileges
- `ssh-alibaba` command configured and working

## 🛠️ Deployment Process

### Step 1: Prepare Deployment Files
```bash
# All files are ready in the deploy directory:
cd /home/sebastianvernis/deploy
ls -la
# Should show:
# - deploy.sh (main deployment script)
# - requirements.txt (Python dependencies)
# - README_deployment.md (this file)
```

### Step 2: Connect to Remote Server
```bash
# Use your ssh-alibaba command
ssh-alibaba

# Once connected, you should be on the remote server
```

### Step 3: Transfer and Run Deployment
```bash
# On the remote server, download the deployment script
# (You can copy-paste the deploy.sh content or use wget/curl if hosted)

# Make it executable
chmod +x deploy.sh

# Run the deployment (requires sudo)
sudo ./deploy.sh
```

## 🔧 What the Deployment Script Does

### System Setup
- ✅ Updates system packages
- ✅ Installs Python 3, pip, nginx, supervisor
- ✅ Creates application directory at `/var/www/prime-visualization`

### Application Setup
- ✅ Creates Python virtual environment
- ✅ Installs required dependencies (Flask, NumPy, Matplotlib, SciPy)
- ✅ Configures matplotlib for headless operation
- ✅ Creates optimized Flask application
- ✅ Sets up Gunicorn WSGI server

### Web Server Configuration
- ✅ Configures Nginx reverse proxy
- ✅ Sets up systemd service for auto-start
- ✅ Configures proper permissions
- ✅ Enables services and starts application

### Monitoring & Management
- ✅ Creates status check script
- ✅ Sets up logging
- ✅ Provides management commands

## 🌐 Application Features (Production Version)

### Core Functionality
- **Prime Pattern Visualization**: Concentric circles showing prime distributions
- **Real-time Generation**: Dynamic visualization based on user parameters
- **High-Quality Rendering**: Matplotlib backend for crisp images
- **Statistical Analysis**: Prime gaps, twin primes, density metrics

### User Interface
- **Spanish Interface**: Complete localization
- **Responsive Design**: Works on desktop and mobile
- **Interactive Controls**: Adjustable parameters
- **Error Handling**: User-friendly error messages

### Performance Optimizations
- **Gunicorn WSGI**: Production-grade Python server
- **Nginx Proxy**: Efficient static file serving and load balancing
- **Matplotlib Optimization**: Headless rendering for server environment
- **Systemd Integration**: Automatic service management

## 📊 Application Access

After successful deployment:

### Public Access
```bash
# External access (replace with your server IP)
http://YOUR_SERVER_IP/

# If using domain name
http://yourdomain.com/
```

### Local Server Access
```bash
# Direct access from server
http://localhost/
http://127.0.0.1/
```

## 🔍 Monitoring & Management

### Check Application Status
```bash
# Quick status check
prime-viz-status

# Individual service status
systemctl status prime-visualization
systemctl status nginx
```

### View Logs
```bash
# Application logs (live)
journalctl -u prime-visualization -f

# Application logs (last 50 lines)
journalctl -u prime-visualization -n 50

# Nginx access logs
tail -f /var/log/nginx/access.log

# Nginx error logs
tail -f /var/log/nginx/error.log
```

### Service Management
```bash
# Restart application
sudo systemctl restart prime-visualization

# Restart web server
sudo systemctl restart nginx

# Stop application
sudo systemctl stop prime-visualization

# Start application
sudo systemctl start prime-visualization
```

## 🛠️ Troubleshooting

### Common Issues & Solutions

#### Application Won't Start
```bash
# Check logs for errors
journalctl -u prime-visualization -n 20

# Verify Python dependencies
cd /var/www/prime-visualization
source venv/bin/activate
pip list

# Test application manually
python app.py
```

#### Nginx Issues
```bash
# Test nginx configuration
sudo nginx -t

# Check nginx status
systemctl status nginx

# Restart nginx
sudo systemctl restart nginx
```

#### Permission Issues
```bash
# Fix permissions
sudo chown -R www-data:www-data /var/www/prime-visualization
sudo chmod -R 755 /var/www/prime-visualization
```

#### Port Conflicts
```bash
# Check what's using port 5000
sudo netstat -tlnp | grep :5000

# Check what's using port 80
sudo netstat -tlnp | grep :80
```

### Performance Monitoring
```bash
# Check system resources
htop
free -h
df -h

# Check application processes
ps aux | grep gunicorn
ps aux | grep nginx
```

## 🔒 Security Considerations

### Firewall Configuration
```bash
# Allow HTTP traffic
sudo ufw allow 80/tcp

# Allow HTTPS traffic (if using SSL)
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### SSL/HTTPS Setup (Optional)
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d yourdomain.com
```

## 📈 Production Optimizations

### For High Traffic
- Increase Gunicorn workers in `gunicorn.conf.py`
- Add Redis for caching
- Use CDN for static assets
- Implement rate limiting

### For Better Performance
- Optimize matplotlib rendering
- Add result caching
- Use asynchronous processing
- Monitor and tune system resources

## 🔄 Updates & Maintenance

### Updating the Application
```bash
# Navigate to app directory
cd /var/www/prime-visualization

# Activate virtual environment
source venv/bin/activate

# Update dependencies
pip install --upgrade -r requirements.txt

# Restart application
sudo systemctl restart prime-visualization
```

### Regular Maintenance
- Monitor disk space and logs
- Keep system packages updated
- Review application performance
- Backup configuration files

---

## 🎯 Success Verification

After deployment, verify these endpoints:

1. **Main Application**: `http://YOUR_SERVER_IP/`
2. **API Endpoint**: `http://YOUR_SERVER_IP/generar` (POST request)
3. **Health Check**: Application should load without errors
4. **Functionality**: Generate visualization with different parameters

The application should now be fully operational and accessible from anywhere on the internet!