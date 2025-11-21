# Guacamole on OpenShift Setup Guide

This guide walks you through deploying Apache Guacamole on OpenShift with a sample Fedora VNC VM.

## Notes
- This example uses the vnc/rdp inside the guest OS VM option
- As of this writing the vnc via qemu in kubevirt [is not supported yet](https://github.com/kubevirt/kubevirt/issues/14798)

## Prerequisites

- OpenShift cluster with admin access
- OpenShift Virtualization (CNV) installed
- `oc` CLI tool configured

## Step 1: Deploy Guacamole

Deploy the complete Guacamole stack including MySQL database, Guacd daemon, and the web application:

```bash
cd guacamole-install
./deploy-guacamole.sh
```

This script will:
- Create the `guacamole` namespace
- Deploy MySQL with persistent storage
- Initialize the Guacamole database schema
- Deploy Guacd (Guacamole proxy daemon)
- Deploy Guacamole web application
- Create an OpenShift route for external access

Wait for all pods to be ready:
```bash
oc get pods -n guacamole -w
```

## Step 2: Access Guacamole

Get the route URL:
```bash
oc get route guacamole -n guacamole
```

Access Guacamole at: `https://<route-url>/guacamole/`

Default credentials:
- **Username:** `guacadmin`
- **Password:** `guacadmin`

## Step 3: Deploy Sample Fedora VNC VM

Create the Fedora virtual machine with VNC server:

```bash
oc apply -f sample-vm/fedora-vm.yaml
```

This creates:
- A Fedora VM with 2Gi RAM and 1 CPU
- VNC server configured on port 5901
- A Service exposing VNC at `fedora-vnc.guacamole.svc.cluster.local:5901`

VM credentials:
- **Username:** `fedora`
- **Password:** `fedora`
- **VNC Password:** `fedora`

Check VM status:
```bash
oc get vm -n guacamole
oc get vmi -n guacamole
```

Wait for the VM to be running and the VNC server to start (may take a few minutes for cloud-init to complete).

## Step 4: Add VM to Guacamole

### Option A: Automatic (Using Job)

Run the job to automatically add the VNC connection:

```bash
oc apply -f guacamole-add-connection-job.yaml
```

Check job status:
```bash
oc logs job/guacamole-add-vnc-connection -n guacamole -f
```

The connection "Fedora VNC VM" will appear in Guacamole after the job completes.

### Option B: Manual (Via Web UI)

1. Log into Guacamole web interface
2. Click on your username (top right) → Settings
3. Go to "Connections" tab
4. Click "New Connection"
5. Fill in the details:
   - **Name:** Fedora VNC VM
   - **Protocol:** VNC
   - **Hostname:** `fedora-vnc.guacamole.svc.cluster.local`
   - **Port:** `5901`
   - **Password:** `fedora`
6. Click "Save"

## Step 5: Connect to VM

1. Return to Guacamole home screen
2. Click on "Fedora VNC VM" connection
3. You should see the Fedora desktop with an xterm terminal

## Cleanup

To remove all resources:

```bash
oc delete -f ./guacamole-add-connection-job.yaml
oc delete -f ./sample-vm/fedora-vm.yaml
./guacamole-install/cleanup-guacamole.sh
```

This will delete:
- All deployments and services
- The virtual machine
- Persistent volume claims (⚠️ **deletes all data!**)
- The guacamole namespace

## Troubleshooting

### Guacamole not accessible
```bash
# Check pods status
oc get pods -n guacamole

# Check logs
oc logs -l app=guacamole -n guacamole
oc logs -l app=mysql -n guacamole
```

### VM not starting
```bash
# Check VM events
oc describe vm fedora-vnc -n guacamole

# Check VMI status
oc get vmi -n guacamole

# View console
virtctl console fedora-vnc -n guacamole
```

### VNC connection fails
```bash
# Check if VNC service is accessible
oc run test -n guacamole --rm -it --image=busybox -- nc -zv fedora-vnc 5901

# Check VM logs via console
virtctl console fedora-vnc -n guacamole

# Verify VNC server is running (from VM console)
ps aux | grep vnc
```

### Database initialization failed
```bash
# Check init job logs
oc logs job/guacamole-db-init -n guacamole

# Restart by deleting the job
oc delete job guacamole-db-init -n guacamole
oc apply -f guacamole-db-init.yaml
```

## Architecture

```
┌─────────────────┐
│  OpenShift      │
│  Route          │
└────────┬────────┘
         │
    ┌────▼─────────┐
    │  Guacamole   │
    │  (Web App)   │
    └────┬─────────┘
         │
    ┌────▼─────────┐       ┌──────────────┐
    │   Guacd      │──────▶│  Fedora VM   │
    │  (Proxy)     │       │  VNC :5901   │
    └────┬─────────┘       └──────────────┘
         │
    ┌────▼─────────┐
    │   MySQL      │
    │  (Database)  │
    └──────────────┘
```

## Notes

- All components run in the `guacamole` namespace
- MySQL uses the Red Hat RHEL9 MySQL 8.4 image
- The mysql ServiceAccount has `anyuid` SCC for proper file permissions
- VNC connections are unencrypted within the cluster
- Consider using TLS for the OpenShift route in production
