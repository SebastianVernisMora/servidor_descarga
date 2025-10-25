#!/usr/bin/env python3
"""
Configuration loader for .blackbox file
"""
import os
import sys

def load_blackbox_config():
    """Load configuration from .blackbox file"""
    config = {}
    blackbox_file = os.path.join(os.path.dirname(__file__), '.blackbox')
    
    if not os.path.exists(blackbox_file):
        print("⚠️  .blackbox file not found, using defaults")
        return get_default_config()
    
    try:
        with open(blackbox_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    
                    # Convert boolean strings
                    if value.lower() in ('true', 'false'):
                        value = value.lower() == 'true'
                    # Convert numeric strings
                    elif value.isdigit():
                        value = int(value)
                    
                    config[key] = value
    except Exception as e:
        print(f"❌ Error loading .blackbox config: {e}")
        return get_default_config()
    
    # Fill in defaults for missing values
    defaults = get_default_config()
    for key, default_value in defaults.items():
        if key not in config:
            config[key] = default_value
    
    return config

def get_default_config():
    """Default configuration values"""
    return {
        'APP_PORT': 5001,
        'DOMAIN': 'ec2-44-195-68-60.compute-1.amazonaws.com',
        'SSL_EMAIL': 'admin@amazonaws.com',
        'ENABLE_SSL': True,
        'FLASK_ENV': 'production',
        'DEBUG_MODE': False,
        'THREADED': True,
        'HOST': '127.0.0.1',
        'UPSTREAM_PORT': 5001,
        'USE_NGINX_PROXY': True,
        'DEPLOY_METHOD': 'flask',
        'WORKERS': 4,
        'ENABLE_CACHE': True,
        'CACHE_TTL': 3600,
        'CACHE_MAX_SIZE': 100,
        'BLACKBOX_API_KEY': '',
        'ENABLE_IA_ANALYSIS': False,
        'MAX_CONTENT_LENGTH': 52428800,
        'ENABLE_CORS': False,
        'ALLOWED_ORIGINS': '',
        'ENABLE_MONITORING': True,
        'LOG_LEVEL': 'INFO'
    }

def print_config(config):
    """Print current configuration"""
    print("📋 Current Configuration:")
    print("-" * 40)
    for key, value in sorted(config.items()):
        print(f"  {key}: {value}")
    print("-" * 40)

if __name__ == '__main__':
    config = load_blackbox_config()
    print_config(config)