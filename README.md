Here's a complete `README.md` for your self-hosted GitHub Actions runner setup using Docker, Kubernetes (with sidecar for Docker-in-Docker), and Terraform (for provisioning an Azure VM). It outlines the setup clearly and step-by-step:

---

# 🛠️ Self-Hosted GitHub Actions Runner on Azure VM with Kubernetes + Docker Support

This repository contains a complete setup for deploying a **self-hosted GitHub Actions runner** inside a **Kubernetes pod** running on an **Azure Ubuntu VM**. It supports Docker operations within GitHub Actions using a Docker-in-Docker (DinD) sidecar container.

---

## 📦 Components

- **Dockerfile**: Builds the GitHub Actions runner container.
- **start.sh**: Initializes and runs the self-hosted runner.
- **Helm-style Deployment YAML**: Deploys the runner and Docker daemon as sidecars.
- **Kubernetes Secret**: Stores your GitHub organization name and access token.
- **Terraform**: Provisions an Azure Ubuntu VM.
- **Kind cluster**: Sets up a local Kubernetes cluster.

---

## 🚀 Step-by-Step Setup

---

### 1. 🔧 Provision Azure Ubuntu VM with Terraform

Create a VM on Azure that will host your Kubernetes cluster with custom script 

```bash
#!/bin/bash
# Update packages
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to Docker group
sudo usermod -aG docker $USER

# Set permissions to docker.sock
sudo chmod 666 /var/run/docker.sock
```
------
```bash
# Replace variables in your Terraform config (not included here)
terraform init
terraform apply
```

---

### 2. 🐳 Install Docker & Kind on the VM

SSH into your VM and install Docker and Kind:

```bash
sudo apt update && sudo apt install -y docker.io
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

---

### 3. ☸️ Set Up Kind Kubernetes Cluster

Create your local Kubernetes cluster with this config:

`kind-cluster.yaml`
```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: my-cluster

nodes:
  - role: control-plane
```

```bash
kind create cluster --config kind-cluster.yaml
```

---

### 4. 🐙 Create GitHub Secrets in Kubernetes

Store your GitHub organization and PAT (Personal Access Token) securely:

```bash
kubectl create secret generic github-credentials \
  --from-literal=ORGANIZATION="your-org" \
  --from-literal=ACCESS_TOKEN="your-token"
```

---

### 5. 🏗️ Build and Push Docker Image (Optional)

If pushing to a registry:

```bash
docker build -t yourregistry/github-runner:latest .
docker push yourregistry/github-runner:latest
```

Or use locally within Kind:

```bash
kind load docker-image yourregistry/github-runner:latest
```

---

### 6. 📦 Deploy Runner with DinD Sidecar

Use the following Kubernetes deployment YAML (`deployment.yaml`) with Helm-style templating. The runner container connects to the sidecar Docker daemon using `DOCKER_HOST=tcp://localhost:2375`.

Make sure to update:

- `.Values.env.secretName` = `github-credentials`
- `.Values.image.repository` and `.Values.image.tag`
- Any additional configuration like probes, resources, etc.

---

### 7. 🔄 start.sh – Runner Bootstrap Script

```bash
#!/bin/bash

ORGANIZATION=$ORGANIZATION
ACCESS_TOKEN=$ACCESS_TOKEN

cd /home/adminuser/actions-runner

./config.sh --url https://github.com/$ORGANIZATION --token $ACCESS_TOKEN

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${ACCESS_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
```

---

### 8. 🐳 Dockerfile – Runner Image

```Dockerfile
FROM ubuntu:20.04

ARG RUNNER_VERSION="2.321.0"
ARG DEBIAN_FRONTEND=noninteractive

RUN useradd -m adminuser

RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    sudo curl jq build-essential libssl-dev libffi-dev \
    python3 python3-venv python3-dev python3-pip \
    docker.io apt-transport-https gnupg

RUN echo "adminuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN usermod -aG docker adminuser

RUN cd /home/adminuser && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

RUN chown -R adminuser:adminuser /home/adminuser/actions-runner
RUN /home/adminuser/actions-runner/bin/installdependencies.sh

COPY start.sh /home/adminuser/start.sh
RUN chmod +x /home/adminuser/start.sh

USER adminuser
ENTRYPOINT ["/home/adminuser/start.sh"]
```

---

### 9. ✅ Validate Setup

Deploy your YAML into Kubernetes:

```bash
kubectl apply -f deployment.yaml
```

Verify pods:

```bash
kubectl get pods
```

Check logs:

```bash
kubectl logs -f <runner-pod-name> -c <container-name>
```

You should now see your self-hosted runner appear in your GitHub organization's runner settings.

---

## 🔐 Security Considerations

- Ensure your GitHub token has the correct permissions for managing runners.
- Only use PAT with **read/write:org** and **admin:org** scopes.
- Avoid hardcoding secrets—use Kubernetes Secrets.

---

## 💬 Questions?

Feel free to open an issue or reach out with questions!

---

Let me know if you'd like me to package this into a ready-to-use GitHub repo structure or a Helm chart!
