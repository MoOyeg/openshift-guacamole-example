# Guacamole on OpenShift Deployment

This repository contains Kubernetes manifests to deploy Apache Guacamole with MySQL on OpenShift.

## Components

- **MySQL Database**: Persistent storage for Guacamole configuration
- **Guacd Daemon**: Guacamole proxy daemon
- **Guacamole Web App**: Main web interface
- **Database Initialization**: Job to set up the database schema

## Quick Start

### Prerequisites
- OpenShift cluster access
- `oc` CLI tool configured

### Deploy
```bash
oc adm policy add-scc-to-user anyuid -z default -n guacamole
# Make the deployment script executable
chmod +x deploy-guacamole.sh

# Run the deployment
./deploy-guacamole.sh
```

### Manual Deployment
If you prefer to deploy manually:

```bash
# 1. Create namespace and secrets
oc apply -f guacamole-namespace.yaml

# 2. Deploy MySQL
oc apply -f mysql-deployment.yaml

# 3. Wait for MySQL to be ready
oc wait --for=condition=ready pod -l app=mysql -n guacamole --timeout=300s

# 4. Initialize database
oc apply -f guacamole-db-init.yaml
oc wait --for=condition=complete job/guacamole-db-init -n guacamole --timeout=300s

# 5. Deploy Guacd
oc apply -f guacd-deployment.yaml
oc wait --for=condition=ready pod -l app=guacd -n guacamole --timeout=300s

# 6. Deploy Guacamole
oc apply -f guacamole-deployment.yaml
oc wait --for=condition=ready pod -l app=guacamole -n guacamole --timeout=300s

# 7. Create route
oc apply -f guacamole-route.yaml
```

## Access

After deployment, get the route URL:
```bash
oc get route guacamole -n guacamole
```

Access Guacamole at: `https://<route-url>/guacamole/`

## Default Credentials

- **Username**: `guacadmin`
- **Password**: `guacadmin`

## Configuration

### Database Credentials
The deployment uses the following default credentials (base64 encoded in secrets):

- MySQL root password: `guacamole123`
- Guacamole user password: `guacpass123`
- Guacamole admin password: `admin123`

### Customization
To change passwords, update the base64 encoded values in `guacamole-namespace.yaml`:

```bash
# Encode new password
echo -n "newpassword" | base64
```

### Storage
- MySQL uses a 10Gi PVC for persistent storage
- Modify the storage size in `mysql-deployment.yaml` if needed

## Security Considerations

1. **Change default passwords** before production use
2. **Use proper RBAC** and security contexts
3. **Enable network policies** if required
4. **Use secrets management** (e.g., OpenShift Vault integration)

## Troubleshooting

### Check pod status
```bash
oc get pods -n guacamole
```

### View logs
```bash
# Guacamole logs
oc logs -l app=guacamole -n guacamole

# MySQL logs
oc logs -l app=mysql -n guacamole

# Guacd logs
oc logs -l app=guacd -n guacamole

# Database init logs
oc logs job/guacamole-db-init -n guacamole
```

### Connect to MySQL
```bash
oc exec -it deployment/mysql -n guacamole -- mysql -u root -p guacamole_db
```

### Port forwarding (for debugging)
```bash
# Forward Guacamole port
oc port-forward svc/guacamole 8080:8080 -n guacamole

# Access at http://localhost:8080/guacamole/
```

## Cleanup

To remove all Guacamole components:
```bash
chmod +x cleanup-guacamole.sh
./cleanup-guacamole.sh
```

**⚠️ Warning**: This will delete all data including the MySQL database.

## File Structure

- `guacamole-namespace.yaml` - Namespace and secrets
- `mysql-deployment.yaml` - MySQL database deployment
- `guacamole-db-init.yaml` - Database initialization job
- `guacd-deployment.yaml` - Guacd daemon deployment
- `guacamole-deployment.yaml` - Main Guacamole application
- `guacamole-route.yaml` - OpenShift route for external access
- `deploy-guacamole.sh` - Automated deployment script
- `cleanup-guacamole.sh` - Cleanup script

## Resource Requirements

- **MySQL**: 512Mi-1Gi memory, 250m-500m CPU
- **Guacd**: 256Mi-512Mi memory, 100m-300m CPU  
- **Guacamole**: 512Mi-1Gi memory, 200m-500m CPU

Total: ~1.3-2.5Gi memory, 550m-1.3 CPU cores