#!/bin/bash
# setup kubectl via default service account
#
SERVER_URL=${SERVER_URL:-"https://127.0.0.1:6443"}
NAMESPACE=${NAMESPACE:-"demo"}

kubectl create namespace $NAMESPACE

# verify default sa has been created.
kubectl --namespace=$NAMESPACE get sa

# get secret and token
secret=$(kubectl -n $NAMESPACE get sa default -o jsonpath='{.secrets[0].name}')
token=$(kubectl -n $NAMESPACE get secret $secret -o jsonpath='{.data.token}' | base64 -d)
kubectl -n $NAMESPACE get secret $secret -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt

# setup kubectl
kubectl config set-cluster kubernetes --embed-certs=true --server=${SERVER_URL} --certificate-authority=./ca.crt
kubectl config set-credentials $NAMESPACE --token=$token
kubectl config set-context kubernetes --cluster=kubernetes --user=$NAMESPACE --namespace=$NAMESPACE
kubectl config use-context kubernetes

# setup RBAC Roles
cat <<EOF | kubectl create -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  namespace: $NAMESPACE
  name: $NAMESPACE-role
rules:
  - apiGroups:
    - ''
    - extensions
    - apps
    - batch
    resources:
    - '*'
    verbs:
    - '*'
EOF

# bind sa to the role
kubectl create rolebinding $NAMESPACE-rolebinding --serviceaccount=$NAMESPACE:default --namespace=$NAMESPACE --role=$NAMESPACE-role

# setup cluster role
cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1alpha1
kind: ClusterRole
metadata:
  name: $NAMESPACE-clusterrule
rules:
- apiGroups:
  - extensions
  resources:
  - thirdpartyresources
  verbs:
  - create
- apiGroups:
  - monitoring.kubernetes.io
  resources:
  - alertmanagers
  - prometheuses
  - servicemonitors
  verbs:
  - "*"
EOF

# bind sa to cluster role
kubectl create clusterrolebinding $NAMESPACE-clusterrolebinding --clusterrole=$NAMESPACE-clusterrule --serviceaccount=$NAMESPACE:default
