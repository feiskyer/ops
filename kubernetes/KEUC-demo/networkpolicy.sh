#!/bin/bash
## Network Policy DEMO (assuming an existing Kubernetes cluster).

# Create nginx service
kubectl run nginx --image=nginx --replicas=2
kubectl expose deployment nginx --port=80

# nginx is accessible outside
kubectl run busybox -it --rm --image=busybox sh
# wget --spider --timeout=1 nginx

# create a default deny service
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector:
    matchLabels:
  policyTypes:
  - Ingress
EOF

# nginx is not accessible now
kubectl run busybox -it --rm --image=busybox sh
# wget --spider --timeout=1 nginx

# Now create another network policy
cat <<EOF | kubectl apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-nginx
spec:
  podSelector:
    matchLabels:
      run: nginx
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: "true"
EOF

# 不带access=true标签的Pod还是无法访问nginx服务
kubectl run busybox2 -it --rm --image=busybox sh
# wget --spider --timeout=1 nginx


# 而带有access=true标签的Pod可以访问nginx服务
kubectl run busybox3 -it --rm --labels="access=true" --image=busybox sh
# wget --spider --timeout=1 nginx

# 开启nginx服务的外部访问：
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: external-access
spec:
  podSelector:
    matchLabels:
      run: nginx
  ingress:
    - ports:
        - protocol: TCP
          port: 80
EOF

# 现在所有容器可以访问了
kubectl run busybox4 -it --rm --image=busybox sh
# wget --spider --timeout=1 nginx
