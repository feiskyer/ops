#!/bin/bash
# setup kubectl via openssl
#
SERVER_URL=${SERVER_URL:-"https://127.0.0.1:6443"}
NAMESPACE=${NAMESPACE:-"demo"}
USER=${USER:-"demo"}

# create client key and cert 
openssl genrsa -out $USER.key 2048
openssl req -new -key $USER.key -out $USER.csr -subj "/CN=$USER"
openssl x509 -req -in $USER.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out $USER.pem -days 365
openssl x509 -in $USER.pem -clrtrust -out $USER.pem

# setup role
cat <<EOF | kubectl create -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  namespace: $NAMESPACE
  name: $USER-role
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

# bind role to the user
kubectl create rolebinding $USER-rolebinding --user=$USER --namespace=$NAMESPACE --role=$USER-role

# setup kubectl
# kubectl -s $SERVER_URL --client-key=$USER1.key --client-certificate=$USER1.pem --insecure-skip-tls-verify get pods
kubectl config set-cluster k8s --server="$SERVER_URL"  --insecure-skip-tls-verify
kubectl config set-credentials $USER --client-certificate=$USER.pem --client-key=$USER.key
kubectl config set-context k8s --cluster=k8s --user=$USER --namespace=$NAMESPACE
kubectl config use-context k8s
