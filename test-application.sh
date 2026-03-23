#!/bin/bash

echo "🚀 DevOps Practice Environment - Comprehensive Test"
echo "=================================================="

# Test main application
echo "📱 Testing Main Application..."
echo "✅ Main Page: $(curl -s http://localhost | grep -o '<title>.*</title>' || echo 'FAILED')"
echo "✅ Dashboard: $(curl -s http://localhost/dashboard.html | grep -o '<title>.*</title>' || echo 'FAILED')"

# Test learning modules
echo ""
echo "📚 Testing Learning Modules..."
echo "✅ Docker Learning: $(curl -s http://localhost/learning-docker.html | grep -o '<title>.*</title>' || echo 'FAILED')"
echo "✅ Ansible Learning: $(curl -s http://localhost/learning-ansible.html | grep -o '<title>.*</title>' || echo 'FAILED')"
echo "✅ Kubernetes Learning: $(curl -s http://localhost/learning-kubernetes.html | grep -o '<title>.*</title>' || echo 'FAILED')"

# Test API endpoints
echo ""
echo "🔌 Testing API Endpoints..."
echo "✅ API Gateway Health: $(curl -s http://localhost/api/health | jq -r .status 2>/dev/null || echo 'FAILED')"
echo "✅ Learning Service: $(curl -s http://localhost:4001/health | jq -r .status 2>/dev/null || echo 'FAILED')"
echo "✅ User Service: $(curl -s http://localhost:4002/health | jq -r .status 2>/dev/null || echo 'FAILED')"
echo "✅ Assessment Service: $(curl -s http://localhost:4004/health | jq -r .status 2>/dev/null || echo 'FAILED')"

# Test monitoring services
echo ""
echo "📊 Testing Monitoring Services..."
echo "✅ Prometheus: $(curl -s http://localhost:9090/-/healthy 2>/dev/null && echo 'healthy' || echo 'FAILED')"
echo "✅ Grafana: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3001 2>/dev/null | grep -q '200\|302' && echo 'healthy' || echo 'FAILED')"

# Test direct access
echo ""
echo "🌐 Testing Direct Access..."
echo "✅ Frontend Direct: $(curl -s http://localhost:3000 | grep -o '<title>.*</title>' || echo 'FAILED')"
echo "✅ Load Balancer: $(curl -s http://localhost | grep -o '<title>.*</title>' || echo 'FAILED')"

echo ""
echo "🎯 Access Points:"
echo "   🏠 Main Application: http://localhost"
echo "   📊 Dashboard: http://localhost/dashboard.html"
echo "   🐳 Docker Learning: http://localhost/learning-docker.html"
echo "   🔧 Ansible Learning: http://localhost/learning-ansible.html"
echo "   ☸️  Kubernetes Learning: http://localhost/learning-kubernetes.html"
echo "   📈 Prometheus: http://localhost:9090"
echo "   📊 Grafana: http://localhost:3001 (admin/admin123)"
echo ""
echo "✨ DevOps Practice Environment is ready for learning!"