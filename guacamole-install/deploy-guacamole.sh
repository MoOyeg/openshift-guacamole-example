#!/bin/bash

# Deploy Guacamole on OpenShift
# This script deploys all the components in the correct order

set -e

echo "🚀 Starting Guacamole deployment on OpenShift..."

# Apply namespace and secrets first
echo "📦 Creating namespace and secrets..."
oc apply -f guacamole-namespace.yaml
oc apply -f mysql-serviceaccount.yaml
oc apply -f mysql-rolebinding.yaml

# Deploy MySQL
echo "🐬 Deploying MySQL database..."
oc apply -f mysql-deployment.yaml

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
oc wait --for=condition=ready pod -l app=mysql -n guacamole --timeout=300s

# Initialize Guacamole database
echo "🔧 Initializing Guacamole database..."
oc apply -f guacamole-db-init.yaml

# Wait for database initialization to complete
echo "⏳ Waiting for database initialization to complete..."
oc wait --for=condition=complete job/guacamole-db-init -n guacamole --timeout=300s

# Deploy Guacd daemon
echo "🛠️ Deploying Guacd daemon..."
oc apply -f guacd-deployment.yaml

# Wait for Guacd to be ready
echo "⏳ Waiting for Guacd to be ready..."
oc wait --for=condition=ready pod -l app=guacd -n guacamole --timeout=300s

# Deploy Guacamole web application
echo "🌐 Deploying Guacamole web application..."
oc apply -f guacamole-deployment.yaml

# Wait for Guacamole to be ready
echo "⏳ Waiting for Guacamole to be ready..."
oc wait --for=condition=ready pod -l app=guacamole -n guacamole --timeout=300s

# Create route for external access
echo "🌍 Creating OpenShift route..."
oc apply -f guacamole-route.yaml

# Get the route URL
ROUTE_URL=$(oc get route guacamole -n guacamole -o jsonpath='{.spec.host}')

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "====================="
echo "Namespace: guacamole"
echo "Route URL: https://${ROUTE_URL}/guacamole/"
echo ""
echo "🔑 Default Credentials:"
echo "Username: guacadmin"
echo "Password: guacadmin"
echo ""
echo "🔍 Useful Commands:"
echo "- Check pods: oc get pods -n guacamole"
echo "- Check services: oc get svc -n guacamole"
echo "- Check route: oc get route -n guacamole"
echo "- View logs: oc logs -l app=guacamole -n guacamole"
echo ""
echo "🚪 Access your Guacamole instance at: https://${ROUTE_URL}/guacamole/"