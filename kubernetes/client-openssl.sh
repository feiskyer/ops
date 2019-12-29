#!/bin/bash
# setup kubectl via openssl

NAMESPACE=${NAMESPACE:-"default"}
USER_NAME=${USER_NAME:-"user1"}
GROUP_NAME=${GROUP_NAME:-"group1"}
SERVER_URL=$(kubectl cluster-info | awk '/Kubernetes master/{print $NF}' | sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g')

# create client key and cert 
openssl genrsa -out $USER_NAME.key 2048
openssl req -new -key $USER_NAME.key -out $USER_NAME.csr -subj "/CN=$USER_NAME/O=$GROUP_NAME"

# Sign the client certificates
CERTIFICATE_NAME=$USER_NAME-$NAMESPACE
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $CERTIFICATE_NAME
spec:
  groups:
  - system:authenticated
  request: $(cat $USER_NAME.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
kubectl certificate approve $CERTIFICATE_NAME
kubectl get csr $CERTIFICATE_NAME -o jsonpath='{.status.certificate}'  | base64 --decode > $USER_NAME.crt

# setup RBAC Roles
cat <<EOF | kubectl create -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: $NAMESPACE
  name: $USER_NAME-role
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
kubectl create rolebinding $USER_NAME-rolebinding --user=$USER_NAME --namespace=$NAMESPACE --role=$USER_NAME-role

# setup kubectl
kubectl config set-cluster $USER_NAME --server="$SERVER_URL" --insecure-skip-tls-verify
kubectl config set-credentials $USER_NAME --client-certificate=$USER_NAME.crt --client-key=$USER_NAME.key
kubectl config set-context $USER_NAME --cluster=$USER_NAME --user=$USER_NAME --namespace=$NAMESPACE
kubectl config use-context $USER_NAME
