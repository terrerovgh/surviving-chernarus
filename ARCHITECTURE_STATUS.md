# Chernarus Architecture Status & Migration Plan

## Current Reality vs. Planned Architecture

### 🏗️ **CURRENT ARCHITECTURE (Docker Compose on lenlab)**

**Status**: ✅ **WORKING** - All services running locally on `lenlab.terrerov.com`

```
lenlab.terrerov.com (192.168.0.3) - All Services
├── 🌐 Traefik Proxy        → localhost:8080 (Dashboard)
├── 🗄️ PostgreSQL           → localhost:5432
├── 🤖 n8n Automation       → localhost:5678
├── 📊 Hugo Dashboard       → localhost:80
├── 🎨 Cuba Tattoo Studio   → localhost:80
├── 📁 Hosting Manager      → localhost:80
└── ☸️ Kubernetes Worker    → Joined to cluster
```

**Access Points:**
- Traefik Dashboard: `http://localhost:8080`
- n8n Automation: `http://localhost:5678`
- PostgreSQL: `localhost:5432`
- All websites via Traefik reverse proxy

---

### 🎯 **PLANNED DISTRIBUTED ARCHITECTURE**

**Status**: 🚧 **PLANNED** - Future distributed setup

```
rpi.terrerov.com (192.168.0.2) - Master Node
├── 🌐 Traefik Proxy + SSL   → :8080 (Dashboard), :80/:443 (Services)
├── 🛡️ Pi-hole DNS          → :53 (DNS), :80/admin (Web)
├── 🤖 n8n Automation       → via Traefik SSL
├── 📊 Grafana Monitoring   → via Traefik SSL
├── ☸️ Kubernetes Master    → Control Plane
└── 🔐 SSL Certificate Mgmt  → Cloudflare + Let's Encrypt

lenlab.terrerov.com (192.168.0.3) - Worker Node
├── 🗄️ PostgreSQL           → :5432
├── 📈 Prometheus           → :9090
├── ☸️ Kubernetes Worker    → Data & Compute Node
└── 💾 Data Storage         → Persistent volumes
```

---

## 🔄 Migration Phases

### **Phase 1: Domain Resolution Setup** ✅ **COMPLETE**
- [x] Configure `/etc/hosts` for local domain resolution
- [x] Update all scripts to use domain names
- [x] Test basic connectivity between nodes

### **Phase 2: Current State Documentation** ✅ **COMPLETE**
- [x] Document actual vs planned architecture
- [x] Create verification scripts
- [x] Update VS Code tasks to reflect reality

### **Phase 3: Kubernetes Distribution** 🚧 **IN PROGRESS**
- [x] K8s cluster operational (rpi=master, lenlab=worker)
- [ ] Migrate services to appropriate nodes via K8s
- [ ] Configure service distribution according to plan

### **Phase 4: Service Migration** 📋 **PLANNED**
- [ ] Move Traefik to rpi with SSL termination
- [ ] Setup Pi-hole on rpi for DNS management
- [ ] Migrate n8n and Grafana to run via Traefik on rpi
- [ ] Keep PostgreSQL and Prometheus on lenlab
- [ ] Test all service connectivity

### **Phase 5: SSL & Domain Integration** 📋 **PLANNED**
- [ ] Configure Cloudflare DNS for external access
- [ ] Setup SSL certificates via Traefik + Let's Encrypt
- [ ] Enable HTTPS for all services
- [ ] Test external domain access

---

## 🔧 Available Commands

### **Current Environment (Docker Compose)**
```bash
# Deploy current stack (all on lenlab)
docker-compose up -d

# Check running services
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### **Architecture Verification**
```bash
# Verify current distributed setup
./scripts/verify-distributed-architecture.sh

# Check Kubernetes cluster status
kubectl get nodes -o wide
kubectl get all -A
```

### **VS Code Tasks Available**
- `🚀 Deploy Chernarus Services` - Start Docker Compose stack
- `🔍 Verify Distributed Architecture` - Check service distribution
- `📊 Chernarus Health Check` - Network and service connectivity
- `☸️ K8s Cluster Status` - Kubernetes cluster overview

---

## 🌐 Service Access

### **Development (Current)**
| Service | Local Access | Domain Access (Planned) |
|---------|-------------|------------------------|
| Traefik Dashboard | `localhost:8080` | `http://rpi.terrerov.com:8080` |
| n8n Automation | `localhost:5678` | `https://n8n.terrerov.com` |
| PostgreSQL | `localhost:5432` | `lenlab.terrerov.com:5432` |
| Hugo Dashboard | via Traefik | `https://hq.terrerov.com` |

### **Production (Planned)**
| Service | Access URL |
|---------|------------|
| HQ Dashboard | `https://hq.terrerov.com` |
| n8n Automation | `https://n8n.terrerov.com` |
| Grafana Monitoring | `https://grafana.terrerov.com` |
| Traefik Dashboard | `https://traefik.terrerov.com` |

---

## 🚨 Important Notes

1. **Current State**: Everything runs on `lenlab` via Docker Compose
2. **Domain Resolution**: Local `/etc/hosts` entries enable domain-based access
3. **Kubernetes**: Cluster is operational but services not yet migrated
4. **SSL**: Not yet configured - requires service distribution first
5. **External Access**: Not yet available - requires Cloudflare DNS setup

---

## 🎯 Next Steps

1. **Test Current Setup**: Run verification script to ensure all services work
2. **Plan K8s Migration**: Create Kubernetes manifests for service distribution
3. **Setup Service Distribution**: Move services to planned nodes
4. **Configure SSL**: Setup Traefik SSL termination on rpi
5. **Enable External Access**: Configure Cloudflare DNS and routing

---

## 📞 Troubleshooting

### **If Services Don't Start**
```bash
# Check Docker status
docker-compose ps
docker-compose logs [service_name]

# Restart problematic service
docker-compose restart [service_name]
```

### **If Domains Don't Resolve**
```bash
# Check /etc/hosts entries
cat /etc/hosts | grep terrerov.com

# Test resolution
nslookup rpi.terrerov.com
nslookup lenlab.terrerov.com
```

### **If Kubernetes Issues**
```bash
# Check cluster status
kubectl get nodes
kubectl cluster-info

# Check service status
kubectl get all -A
```
