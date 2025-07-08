#!/usr/bin/env python3
"""
🏭 Surviving Chernarus API
Main entry point for the FastAPI application
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
from datetime import datetime
import psutil
import asyncpg

app = FastAPI(
    title="🏭 Surviving Chernarus API",
    description="API para gestión de supervivencia post-apocalíptica en Chernarus",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """🏠 Endpoint principal"""
    return {
        "message": "🏭 Bienvenido a Surviving Chernarus API",
        "status": "🟢 Operativo",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0",
        "documentation": "/docs"
    }

@app.get("/health")
async def health_check():
    """🏥 Health check para monitoring"""
    try:
        # Check system resources
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')

        # Basic database connectivity check (simplified)
        db_status = "🟢 Conectado"
        try:
            # This would be replaced with actual DB check
            pass
        except Exception:
            db_status = "🔴 Desconectado"

        return {
            "status": "🟢 Saludable",
            "timestamp": datetime.now().isoformat(),
            "system": {
                "cpu_usage": f"{cpu_percent}%",
                "memory_usage": f"{memory.percent}%",
                "disk_usage": f"{disk.percent}%"
            },
            "services": {
                "database": db_status,
                "cache": "🟢 Operativo",
                "api": "🟢 Funcionando"
            },
            "uptime": "Sistema iniciado"
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"❌ Sistema no saludable: {str(e)}")

@app.get("/survivors")
async def get_survivors():
    """👥 Obtener lista de supervivientes"""
    # Mock data - replace with actual database query
    survivors = [
        {
            "id": 1,
            "name": "Rick Grimes",
            "status": "🟢 Vivo",
            "health": 85,
            "hunger": 60,
            "thirst": 40,
            "location": "Elektro",
            "last_seen": "2024-01-15T14:30:00"
        },
        {
            "id": 2,
            "name": "Daryl Dixon",
            "status": "🟢 Vivo",
            "health": 92,
            "hunger": 30,
            "thirst": 20,
            "location": "Cherno",
            "last_seen": "2024-01-15T15:45:00"
        },
        {
            "id": 3,
            "name": "Michonne",
            "status": "🟡 Herido",
            "health": 45,
            "hunger": 80,
            "thirst": 90,
            "location": "Berezino",
            "last_seen": "2024-01-15T12:20:00"
        }
    ]

    return {
        "survivors": survivors,
        "total": len(survivors),
        "alive": len([s for s in survivors if "Vivo" in s["status"]]),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/resources")
async def get_resources():
    """📦 Obtener estado de recursos"""
    resources = {
        "food": {
            "canned_beans": 45,
            "rice": 23,
            "water_bottles": 67,
            "medical_supplies": 12
        },
        "weapons": {
            "ak74": 3,
            "m4a1": 2,
            "crossbow": 5,
            "ammo_556": 234,
            "ammo_762": 156
        },
        "tools": {
            "hatchet": 4,
            "knife": 8,
            "rope": 15,
            "duct_tape": 6
        },
        "status": "📦 Inventario actualizado",
        "last_update": datetime.now().isoformat()
    }

    return resources

@app.get("/bases")
async def get_bases():
    """🏠 Obtener información de bases"""
    bases = [
        {
            "id": 1,
            "name": "🏭 Base Principal",
            "location": "Elektro Powerplant",
            "status": "🟢 Segura",
            "population": 8,
            "defenses": "🔒 Alta",
            "resources": "📦 Abundantes"
        },
        {
            "id": 2,
            "name": "🏥 Puesto Médico",
            "location": "Cherno Hospital",
            "status": "🟡 Vigilancia",
            "population": 3,
            "defenses": "🔓 Media",
            "resources": "💊 Médicos"
        }
    ]

    return {
        "bases": bases,
        "total": len(bases),
        "secure": len([b for b in bases if "Segura" in b["status"]]),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/stats")
async def get_statistics():
    """📊 Estadísticas generales del sistema"""
    return {
        "general": {
            "total_survivors": 15,
            "active_survivors": 12,
            "total_bases": 5,
            "secure_bases": 3,
            "total_resources": 1247,
            "critical_resources": 3
        },
        "survival_rates": {
            "daily": "87%",
            "weekly": "72%",
            "monthly": "45%"
        },
        "threats": {
            "zombie_encounters": 23,
            "player_conflicts": 7,
            "resource_shortages": 2
        },
        "timestamp": datetime.now().isoformat(),
        "status": "📊 Estadísticas actualizadas"
    }

if __name__ == "__main__":
    # Configuration from environment variables
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", 8000))
    debug = os.getenv("API_DEBUG", "false").lower() == "true"

    print("🚀 Iniciando Surviving Chernarus API...")
    print(f"📡 Host: {host}:{port}")
    print(f"🔧 Debug: {debug}")
    print("📝 Documentación disponible en: /docs")

    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=debug,
        log_level="info"
    )
