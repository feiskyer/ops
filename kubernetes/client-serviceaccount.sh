#!/bin/bash
# setup kubectl via default service account
NAMESPACE=${NAMESPACE:-"default"}
SERVICE_ACCOUNT_NAME=${SERVICE_ACCOUNT_NAME:-"demo"}
SERVER_URL=$(kubectl cluster-info | awk '/Kubernetes master/{print $NF}' | sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g')

# create sa
kubectl -n $NAMESPACE create sa $SERVICE_ACCOUNT_NAME

# get secret and token
secret=$(kubectl -n $NAMESPACE get sa $SERVICE_ACCOUNT_NAME -o jsonpath='{.secrets[0].name}')
token=$(kubectl -n $NAMESPACE get secret $secret -o jsonpath='{.data.token}' | base64 -d)
kubectl -n $NAMESPACE get secret $secret -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt

# setup RBAC Roles
cat <<EOF | kubectl create -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: $NAMESPACE
  name: $SERVICE_ACCOUNT_NAME-role
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
kubectl create rolebinding $SERVICE_ACCOUNT_NAME-rolebinding --serviceaccount=$NAMESPACE:$SERVICE_ACCOUNT_NAME --namespace=$NAMESPACE --role=$SERVICE_ACCOUNT_NAME-role

# setup kubectl
kubectl config set-cluster $SERVICE_ACCOUNT_NAME --embed-certs=true --server=${SERVER_URL} --certificate-authority=./ca.crt
kubectl config set-credentials $SERVICE_ACCOUNT_NAME --token=$token
kubectl config set-context $SERVICE_ACCOUNT_NAME --cluster=$SERVICE_ACCOUNT_NAME --user=$SERVICE_ACCOUNT_NAME --namespace=$NAMESPACE
kubectl config use-context $SERVICE_ACCOUNT_NAME
