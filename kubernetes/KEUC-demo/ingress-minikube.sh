#!/bin/bash
## Network Policy DEMO for minikube.

# 创建Minikube本地集群
minikube start --docker-env HTTP_PROXY=${PROXY_SERVER} \
    --docker-env HTTPS_PROXY=${PROXY_SERVER} \
    --vm-driver=xhyve

# Enable ingress
minikube addons enable ingress
kubectl get pods -n kube-system

# create a service
kubectl run echoserver --image=gcr.io/google_containers/echoserver:1.4 --port=8080
kubectl expose deployment echoserver --type=NodePort
minikube service echoserver --url

# create an ingress
cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: echo
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  backend:
    serviceName: default-http-backend
    servicePort: 80
  rules:
  - host: mini-echo.io
    http:
      paths:
      - path: /
        backend:
          serviceName: echoserver
          servicePort: 8080
  - host: mini-web.io
    http:
      paths:
      - path: /echo
        backend:
          serviceName: echoserver
          servicePort: 8080
  - host: echo.$(minikube ip).xip.io
    http:
      paths:
      - path: /
        backend:
          serviceName: echoserver
          servicePort: 8080
EOF

echo "$(minikube ip) mini-echo.io mini-web.io" | sudo tee -a /etc/hosts
echo "Visit http://mini-echo.io, http://mini-web.io/echo and http://echo.$(minikube ip).xip.io"
