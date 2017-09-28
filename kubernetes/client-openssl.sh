#!/bin/bash
# setup kubectl via openssl
#
SERVER_URL=${SERVER_URL:-"https://127.0.0.1:6443"}
NAMESPACE=${NAMESPACE:-"demo"}
USER=${USER:-"demo"}
GROUP=${GROUP:-"demo"}

# create client key and cert 
openssl genrsa -out $USER.key 2048
openssl req -new -key $USER.key -out $USER.csr -subj "/CN=$USER/O=$GROUP"

# Sign the client certificates
# 
# * Sign method I: using existing cluster certs *
# openssl x509 -req -in $USER.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out $USER.crt -days 365
# openssl x509 -in $USER.crt -clrtrust -out $USER.crt
#
# * Sign method II: using CertificateSigningRequest *
CERTIFICATE_NAME=$USER.$NAMESPACE
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $CERTIFICATE_NAME
spec:
  groups:
  - system:authenticated
  request: $(cat $USER.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF
kubectl certificate approve $CERTIFICATE_NAME
kubectl get csr $CERTIFICATE_NAME -o jsonpath='{.status.certificate}'  | base64 -D > $USER.crt


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
kubectl config set-cluster k8s --server="$SERVER_URL" --insecure-skip-tls-verify
kubectl config set-credentials $USER --client-certificate=$USER.crt --client-key=$USER.key
kubectl config set-context k8s --cluster=k8s --user=$USER --namespace=$NAMESPACE
kubectl config use-context k8s
