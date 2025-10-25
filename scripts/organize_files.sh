#!/bin/bash
# Script para organizar archivos obsoletos

echo "🗂️  ORGANIZANDO ARCHIVOS OBSOLETOS..."
echo "======================================"

# Crear directorios de archivo
mkdir -p archive/{old_scripts,old_docs,old_todos,old_apps,ssl_stuff}

echo "📦 Moviendo scripts de deploy obsoletos..."
# Scripts de deploy obsoletos (mantener solo los útiles)
mv deploy.sh archive/old_scripts/ 2>/dev/null
mv deploy_final_fixed.sh archive/old_scripts/ 2>/dev/null
mv deploy_fixed.sh archive/old_scripts/ 2>/dev/null
mv deploy_full.sh archive/old_scripts/ 2>/dev/null
mv deploy_integrated_complete.sh archive/old_scripts/ 2>/dev/null
mv deploy_simple.sh archive/old_scripts/ 2>/dev/null
mv redeploy.sh archive/old_scripts/ 2>/dev/null
mv redeploy_fixed.sh archive/old_scripts/ 2>/dev/null
mv update_app.sh archive/old_scripts/ 2>/dev/null
mv update_deploy_v3.sh archive/old_scripts/ 2>/dev/null

echo "🔐 Moviendo archivos SSL obsoletos..."
mv setup_aws_ssl.sh archive/ssl_stuff/ 2>/dev/null
mv setup_ssl.sh archive/ssl_stuff/ 2>/dev/null
mv aws_ssl_commands.md archive/ssl_stuff/ 2>/dev/null
mv ssl_instructions.md archive/ssl_stuff/ 2>/dev/null
mv update_app_ssl.py archive/ssl_stuff/ 2>/dev/null

echo "📋 Moviendo TODOs completados/obsoletos..."
mv TODO_*.md archive/old_todos/ 2>/dev/null

echo "📚 Moviendo docs obsoletos..."
mv DEPLOYMENT_SUMMARY.md archive/old_docs/ 2>/dev/null
mv README_deployment.md archive/old_docs/ 2>/dev/null
mv manual_deploy_steps.md archive/old_docs/ 2>/dev/null

echo "🐍 Moviendo apps obsoletas..."
mv app_configurable.py archive/old_apps/ 2>/dev/null

echo "📊 Archivos organizados:"
echo "Mantenidos (ACTIVOS):"
echo "- app_optimized.py (aplicación principal)"
echo "- test_*.py (tests)"
echo "- monitor_memory.sh (monitoreo)"
echo "- *_fixes.sh (scripts de corrección actuales)"
echo "- CRUSH.md (documentación principal)"
echo ""
echo "Archivados:"
find archive -type f | wc -l | xargs echo "Total archivos archivados:"

echo ""
echo "✅ Organización completada!"