#!/bin/bash

# ============================================================================
# CHERNARUS DISTRIBUTED ARCHITECTURE VERIFICATION
# ============================================================================
# This script verifies the distributed architecture where:
# - rpi.terrerov.com (192.168.0.2) = Master node with Traefik, Pi-hole, SSL
# - lenlab.terrerov.com (192.168.0.3) = Worker node with PostgreSQL, Prometheus
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RPI_HOST="rpi.terrerov.com"
LENLAB_HOST="lenlab.terrerov.com"
DOMAIN="terrerov.com"

print_header() {
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_connectivity() {
    print_header "NETWORK CONNECTIVITY CHECK"

    echo "Checking basic connectivity..."

    # Check rpi connectivity
    if ping -c 2 "$RPI_HOST" >/dev/null 2>&1; then
        print_success "rpi.terrerov.com is reachable"
    else
        print_error "rpi.terrerov.com is NOT reachable"
    fi

    # Check lenlab connectivity
    if ping -c 2 "$LENLAB_HOST" >/dev/null 2>&1; then
        print_success "lenlab.terrerov.com is reachable"
    else
        print_error "lenlab.terrerov.com is NOT reachable"
    fi

    # Check internet connectivity
    if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connectivity is working"
    else
        print_error "Internet connectivity is NOT working"
    fi

    echo ""
}

check_rpi_services() {
    print_header "RPI SERVICES (Master Node) - $RPI_HOST"

    # Check Traefik Dashboard
    echo "Checking Traefik Dashboard..."
    if curl -s -I "http://$RPI_HOST:8080/dashboard/" | head -1 | grep -q "200\|301\|302"; then
        print_success "Traefik Dashboard is accessible on $RPI_HOST:8080"
    else
        print_error "Traefik Dashboard is NOT accessible on $RPI_HOST:8080"
    fi

    # Check Pi-hole
    echo "Checking Pi-hole..."
    if curl -s -I "http://$RPI_HOST/admin/" | head -1 | grep -q "200\|301\|302"; then
        print_success "Pi-hole Admin interface is accessible"
    else
        print_error "Pi-hole Admin interface is NOT accessible"
    fi

    # Check Pi-hole DNS
    echo "Checking Pi-hole DNS functionality..."
    if dig @"$RPI_HOST" "$DOMAIN" +short >/dev/null 2>&1; then
        print_success "Pi-hole DNS is responding"
        echo "  DNS result: $(dig @"$RPI_HOST" "$DOMAIN" +short | head -1)"
    else
        print_error "Pi-hole DNS is NOT responding"
    fi

    # Check n8n (direct access)
    echo "Checking n8n direct access..."
    if curl -s -I "http://$RPI_HOST:5678/" | head -1 | grep -q "200\|301\|302"; then
        print_success "n8n is accessible directly on $RPI_HOST:5678"
    else
        print_warning "n8n is NOT accessible directly (may be behind Traefik only)"
    fi

    # Check Grafana (direct access)
    echo "Checking Grafana direct access..."
    if curl -s -I "http://$RPI_HOST:3000/" | head -1 | grep -q "200\|301\|302"; then
        print_success "Grafana is accessible directly on $RPI_HOST:3000"
    else
        print_warning "Grafana is NOT accessible directly (may be behind Traefik only)"
    fi

    echo ""
}

check_lenlab_services() {
    print_header "LENLAB SERVICES (Worker Node) - $LENLAB_HOST"

    # Check PostgreSQL
    echo "Checking PostgreSQL..."
    if nc -z "$LENLAB_HOST" 5432 2>/dev/null; then
        print_success "PostgreSQL is accessible on $LENLAB_HOST:5432"

        # Try to check if PostgreSQL is responding properly
        if command -v pg_isready >/dev/null 2>&1; then
            if pg_isready -h "$LENLAB_HOST" -p 5432 >/dev/null 2>&1; then
                print_success "PostgreSQL is ready and accepting connections"
            else
                print_warning "PostgreSQL port is open but service may not be ready"
            fi
        else
            print_info "pg_isready not available, install postgresql-client for better checks"
        fi
    else
        print_error "PostgreSQL is NOT accessible on $LENLAB_HOST:5432"
    fi

    # Check Prometheus
    echo "Checking Prometheus..."
    if nc -z "$LENLAB_HOST" 9090 2>/dev/null; then
        print_success "Prometheus is accessible on $LENLAB_HOST:9090"

        # Try to check Prometheus API
        if curl -s "http://$LENLAB_HOST:9090/api/v1/status/runtimeinfo" >/dev/null 2>&1; then
            print_success "Prometheus API is responding"
        else
            print_warning "Prometheus port is open but API may not be responding"
        fi
    else
        print_error "Prometheus is NOT accessible on $LENLAB_HOST:9090"
    fi

    echo ""
}

check_ssl_domains() {
    print_header "SSL DOMAIN CHECKS"

    # List of domains to check
    domains=(
        "n8n.$DOMAIN"
        "grafana.$DOMAIN"
        "traefik.$DOMAIN"
        "hq.$DOMAIN"
    )

    for domain in "${domains[@]}"; do
        echo "Checking SSL for $domain..."

        # Check if domain resolves
        if nslookup "$domain" >/dev/null 2>&1; then
            print_success "$domain resolves"

            # Check SSL certificate
            if echo | timeout 5 openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -text | grep -q "CN.*$domain\|DNS:.*$domain"; then
                print_success "$domain has valid SSL certificate"
            else
                print_warning "$domain SSL certificate may be invalid or not accessible"
            fi
        else
            print_error "$domain does NOT resolve"
        fi
    done

    echo ""
}

check_docker_services() {
    print_header "LOCAL DOCKER SERVICES"

    # Check if we're running on lenlab and what services are running
    current_host=$(hostname)
    print_info "Current host: $current_host"

    if command -v docker >/dev/null 2>&1; then
        print_success "Docker is available"

        echo "Running containers:"
        if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null; then
            print_success "Docker containers listed above"
        else
            print_warning "No running containers or Docker permission issues"
        fi
    else
        print_error "Docker is NOT available"
    fi

    echo ""
}

check_kubernetes() {
    print_header "KUBERNETES CLUSTER STATUS"

    if command -v kubectl >/dev/null 2>&1; then
        print_success "kubectl is available"

        echo "Checking cluster access..."
        if kubectl cluster-info >/dev/null 2>&1; then
            print_success "Kubernetes cluster is accessible"

            echo "Node status:"
            kubectl get nodes -o wide 2>/dev/null || print_warning "Could not get node status"

            echo ""
            echo "Namespace status:"
            kubectl get ns 2>/dev/null || print_warning "Could not get namespaces"
        else
            print_warning "Kubernetes cluster is NOT accessible (may need kubectl configuration)"
        fi
    else
        print_warning "kubectl is NOT available"
    fi

    echo ""
}

main() {
    print_header "CHERNARUS DISTRIBUTED ARCHITECTURE VERIFICATION"
    echo "Architecture:"
    echo "  📡 rpi.terrerov.com (192.168.0.2) - Master Node"
    echo "    └── Traefik, Pi-hole, SSL, n8n, Grafana"
    echo "  💻 lenlab.terrerov.com (192.168.0.3) - Worker Node"
    echo "    └── PostgreSQL, Prometheus"
    echo ""

    check_connectivity
    check_rpi_services
    check_lenlab_services
    check_ssl_domains
    check_docker_services
    check_kubernetes

    print_header "VERIFICATION COMPLETE"
    print_info "Review the results above to ensure all services are properly distributed"
    print_info "If any services are not accessible, check the respective Docker Compose"
    print_info "configurations and ensure services are running on the correct nodes."
}

# Run the verification
main "$@"
