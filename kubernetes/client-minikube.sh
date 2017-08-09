#!/bin/bash
# 配置minikube RBAC示例
# minikube start --feature-gates=AllAlpha=true --extra-config=apiserver.Authorization.Mode=RBAC

# 生成客户证书
openssl genrsa -out employee.key 2048
openssl req -new -key employee.key -out employee.csr -subj "/CN=employee/O=groupname"
openssl x509 -req -in employee.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out employee.crt -days 500

# 配置kubectl
kubectl config set-credentials employee --client-certificate=employee.crt  --client-key=employee.key
kubectl config set-context employee-context --cluster=minikube --namespace=office --user=employee

# 创建namespace
kubectl create namespace office

# 配置RBAC授权
cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: staff
  namespace: office
rules:
- apiGroups:
  - ""
  - externsions
  - apps
  resources:
  - pods
  - replicasets
  - deployments
  verbs:
  - get
  - list
  - watch
  - create
  - delete
EOF

kubectl create rolebinding employee-rolebinding --user=employee --namespace=office --role=staff

# 现在可以操作office namespace的pod了
kubectl --context=employee-context get pods

# 但其他namespace操作会拒绝
kubectl --context=employee-context get pods -n default
