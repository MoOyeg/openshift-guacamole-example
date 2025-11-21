#!/bin/bash

# Cleanup Guacamole deployment from OpenShift

set -e

echo "🗑️ Cleaning up Guacamole deployment..."

# Delete all resources
echo "Deleting Guacamole resources..."
oc delete -f guacamole-route.yaml --ignore-not-found=true
oc delete -f guacamole-deployment.yaml --ignore-not-found=true
oc delete -f guacd-deployment.yaml --ignore-not-found=true
oc delete -f guacamole-db-init.yaml --ignore-not-found=true
oc delete -f mysql-deployment.yaml --ignore-not-found=true
oc delete -f mysql-rolebinding.yaml --ignore-not-found=true
oc delete -f mysql-serviceaccount.yaml --ignore-not-found=true

# Delete PVC (this will remove all data!)
echo "⚠️  Deleting persistent volume claim (this will delete all data)..."
oc delete pvc mysql-pvc -n guacamole --ignore-not-found=true

# Delete namespace and secrets
oc delete -f guacamole-namespace.yaml --ignore-not-found=true

echo "✅ Cleanup completed!"