#!/bin/bash

# Exit immediately if any command fails
set -e

# Define namespace
NAMESPACE="argocd"

echo "🚀 Updating Helm repositories..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "🔍 Checking if namespace '$NAMESPACE' exists..."
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    echo "✅ Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE
else
    echo "⚡ Namespace '$NAMESPACE' already exists!"
fi

echo "📦 Installing Argo CD using Helm..."
helm install argocd argo/argo-cd --namespace $NAMESPACE --create-namespace

echo "⏳ Waiting for Argo CD to be ready..."
kubectl rollout status deployment/argocd-server -n $NAMESPACE

echo "🔑 Getting Argo CD admin password..."
ARGOCD_PASSWORD=$(kubectl get secret -n $NAMESPACE argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
echo "🔐 Argo CD admin password: $ARGOCD_PASSWORD"

echo "🌍 Exposing Argo CD via port forwarding..."
echo "➡ Run this command in a separate terminal: kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443"

echo "🎉 Argo CD installation completed successfully!"
