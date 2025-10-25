#!/bin/bash

# Prime Visualization App - ULTRA SIMPLE VERSION
# Bypasses complex dependencies and gets the app running

echo "🚀 Deploying SIMPLE Prime Visualization App..."

# Configuration
APP_NAME="prime-visualization"
APP_DIR="/var/www/$APP_NAME"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Run with sudo"
    exit 1
fi

print_status "Installing minimal dependencies..."
apt update
apt install -y python3 python3-pip nginx

print_status "Clean start..."
systemctl stop $APP_NAME 2>/dev/null || true
rm -rf $APP_DIR
mkdir -p $APP_DIR/templates
cd $APP_DIR

print_status "Installing basic Python packages..."
pip3 install --break-system-packages flask matplotlib numpy pillow

print_status "Creating minimal app..."

cat > app.py << 'EOF'
from flask import Flask, render_template, request, jsonify
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import io
import base64
import math

app = Flask(__name__)

def sieve(n):
    if n < 2: return []
    is_prime = [True] * (n + 1)
    is_prime[0] = is_prime[1] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            for j in range(i*i, n + 1, i):
                is_prime[j] = False
    return [i for i in range(2, n + 1) if is_prime[i]]

def create_image(circles, segments):
    plt.clf()
    fig, ax = plt.subplots(figsize=(10, 10), facecolor='black')
    ax.set_facecolor('black')
    ax.set_aspect('equal')
    
    total = circles * segments
    primes = set(sieve(total))
    
    for n in range(1, total + 1):
        ring = n // segments
        seg = n % segments
        if ring >= circles: continue
        
        r_inner = 0.5 + ring * 0.8
        r_outer = r_inner + 0.8
        angle1 = seg * (360 / segments)
        angle2 = (seg + 1) * (360 / segments)
        
        color = '#FF0000' if n in primes else '#333333'
        
        theta1, theta2 = np.radians([angle1, angle2])
        theta = np.linspace(theta1, theta2, 20)
        
        x_inner = r_inner * np.cos(theta)
        y_inner = r_inner * np.sin(theta)
        x_outer = r_outer * np.cos(theta)
        y_outer = r_outer * np.sin(theta)
        
        x = np.concatenate([x_inner, x_outer[::-1], [x_inner[0]]])
        y = np.concatenate([y_inner, y_outer[::-1], [y_inner[0]]])
        
        ax.fill(x, y, color=color, alpha=0.8, edgecolor='white', linewidth=0.1)
    
    ax.set_xlim([-circles-1, circles+1])
    ax.set_ylim([-circles-1, circles+1])
    ax.axis('off')
    ax.text(0, circles+0.5, f'Prime Numbers - {circles} Rings, {segments} Segments', 
            ha='center', color='white', fontsize=14, weight='bold')
    
    buf = io.BytesIO()
    plt.savefig(buf, format='png', dpi=200, bbox_inches='tight', 
                facecolor='black', edgecolor='none')
    buf.seek(0)
    img_data = base64.b64encode(buf.read()).decode()
    plt.close()
    buf.close()
    
    return img_data, len([p for p in primes if p <= total])

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/generate', methods=['POST'])
def generate():
    try:
        data = request.json
        circles = int(data.get('circles', 10))
        segments = int(data.get('segments', 36))
        
        if not (1 <= circles <= 50): 
            return jsonify({'error': 'Circles must be 1-50'}), 400
        if not (4 <= segments <= 100): 
            return jsonify({'error': 'Segments must be 4-100'}), 400
        
        img, prime_count = create_image(circles, segments)
        return jsonify({
            'image': img,
            'primes': prime_count,
            'total': circles * segments
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Prime Number Visualization</title>
    <style>
        body { font-family: Arial; background: #2c3e50; color: white; padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; }
        .controls { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        input, button { padding: 10px; margin: 5px; border: none; border-radius: 5px; }
        button { background: #3498db; color: white; cursor: pointer; }
        button:hover { background: #2980b9; }
        .result { text-align: center; background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; }
        .stats { display: flex; justify-content: space-around; margin-top: 20px; }
        .stat { text-align: center; }
        .loading { display: none; }
        .error { color: #e74c3c; display: none; }
        img { max-width: 100%; border-radius: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔢 Prime Number Visualization</h1>
        
        <div class="controls">
            <label>Circles: <input type="number" id="circles" value="10" min="1" max="50"></label>
            <label>Segments: <input type="number" id="segments" value="36" min="4" max="100"></label>
            <button onclick="generate()">Generate</button>
            <div class="loading" id="loading">⏳ Generating...</div>
            <div class="error" id="error"></div>
        </div>
        
        <div class="result">
            <div id="image"></div>
            <div class="stats" id="stats"></div>
        </div>
    </div>

    <script>
        async function generate() {
            const loading = document.getElementById('loading');
            const error = document.getElementById('error');
            const image = document.getElementById('image');
            const stats = document.getElementById('stats');
            
            loading.style.display = 'block';
            error.style.display = 'none';
            
            try {
                const response = await fetch('/generate', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        circles: parseInt(document.getElementById('circles').value),
                        segments: parseInt(document.getElementById('segments').value)
                    })
                });
                
                const data = await response.json();
                
                if (!response.ok) throw new Error(data.error);
                
                image.innerHTML = `<img src="data:image/png;base64,${data.image}">`;
                stats.innerHTML = `
                    <div class="stat"><h3>${data.primes}</h3><p>Prime Numbers</p></div>
                    <div class="stat"><h3>${data.total}</h3><p>Total Numbers</p></div>
                    <div class="stat"><h3>${(data.primes/data.total*100).toFixed(1)}%</h3><p>Prime Density</p></div>
                `;
                
            } catch (err) {
                error.textContent = err.message;
                error.style.display = 'block';
            } finally {
                loading.style.display = 'none';
            }
        }
        
        // Generate on load
        window.onload = () => setTimeout(generate, 500);
    </script>
</body>
</html>
EOF

print_status "Setting up direct Python service..."

cat > /etc/systemd/system/$APP_NAME.service << SERVICE_EOF
[Unit]
Description=Simple Prime Visualization
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE_EOF

print_status "Configuring nginx..."
cat > /etc/nginx/sites-available/$APP_NAME << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 300s;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/

print_status "Starting services..."
nginx -t && systemctl restart nginx
systemctl daemon-reload
systemctl enable $APP_NAME
systemctl start $APP_NAME

sleep 3

print_status "Checking status..."
if systemctl is-active --quiet $APP_NAME; then
    print_success "✅ App is running!"
else
    echo "❌ App failed. Logs:"
    journalctl -u $APP_NAME -n 10 --no-pager
fi

if systemctl is-active --quiet nginx; then
    print_success "✅ Nginx is running!"
fi

print_status "Testing..."
if curl -s -f http://localhost/ >/dev/null; then
    print_success "🎉 SUCCESS! App is responding"
    echo ""
    echo "🌐 Access your app at: http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost')"
    echo ""
    echo "📊 Features:"
    echo "  • Interactive prime number visualization"
    echo "  • Adjustable circles and segments"
    echo "  • Real-time statistics"
    echo "  • Clean, responsive interface"
else
    echo "❌ App not responding"
fi

echo ""
echo "🔧 Commands:"
echo "  sudo systemctl status $APP_NAME"
echo "  sudo journalctl -u $APP_NAME -f"
echo "  sudo systemctl restart $APP_NAME"
