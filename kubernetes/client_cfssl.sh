#!/bin/bash
# setup kubectl via cfssl
#
SERVER_URL=${SERVER_URL:-"https://127.0.0.1:6443"}
NAMESPACE=${NAMESPACE:-"demo"}
USER=${USER:-"demo"}

# install cfssl
go get -u github.com/cloudflare/cfssl/cmd/...

# create client key and cert
cat >ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "43800h"
        },
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

cat >$USER-csr.json <<EOF
{
  "CN": "$USER",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "Kubernetes",
      "OU": "Cluster"
    }
  ]
}
EOF

cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key -config=ca-config.json -profile=client $USER-csr.json | cfssljson -bare $USER

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

# bind role
kubectl create rolebinding $USER-rolebinding --user=$USER --namespace=$NAMESPACE --role=$USER-role

# setup kubectl
# kubectl -s $SERVER_URL --client-key=$USER.key --client-certificate=$USER.pem --insecure-skip-tls-verify get pods
kubectl config set-cluster k8s --server="$SERVER_URL"  --insecure-skip-tls-verify
kubectl config set-credentials $USER --client-certificate=$USER.pem --client-key=$USER.key
kubectl config set-context k8s --cluster=k8s --user=$USER --namespace=$NAMESPACE
kubectl config use-context k8s
