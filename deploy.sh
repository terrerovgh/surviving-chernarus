#!/bin/bash

# 🚀 Surviving Chernarus - Deployment Script
# Este script despliega todos los servicios del proyecto

set -e

echo "🏭 =============================================="
echo "🚀 Desplegando Surviving Chernarus"
echo "🏭 =============================================="

# Verificar que Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    exit 1
fi

# Verificar que Docker Compose está disponible
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: Docker Compose no está instalado"
    exit 1
fi

echo "🔍 Verificando configuración..."

# Crear directorios necesarios si no existen
mkdir -p docker/postgres
mkdir -p docker/prometheus
mkdir -p docker/grafana/provisioning
mkdir -p docker/nginx/conf.d
mkdir -p data/postgres
mkdir -p data/grafana

echo "📦 Construyendo imágenes..."
docker-compose build --no-cache

echo "🚀 Iniciando servicios..."
docker-compose up -d

echo "⏳ Esperando que los servicios estén listos..."
sleep 30

echo "🔍 Verificando estado de los servicios..."
docker-compose ps

echo ""
echo "🎉 ¡Despliegue completado!"
echo ""
echo "🌐 Servicios disponibles:"
echo "   📡 API:        http://lenlab.terrerov.com:8000"
echo "   📊 Grafana:    http://lenlab.terrerov.com:3000 (admin/Ch3rn4rusGr4f4n4!)"
echo "   📈 Prometheus: http://localhost:9090"
echo "   🗄️ PostgreSQL: localhost:5432 (survivor/Ch3rn4rus2024!)"
echo ""
echo "📖 Documentación de la API: http://localhost:8000/docs"
echo ""
echo "🏭 ¡Bienvenido a Surviving Chernarus!"
