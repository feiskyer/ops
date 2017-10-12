#!/bin/bash
## Ingress DEMO (assuming an existing Kubernetes cluster).

# Setup nginx ingress controller
kubectl apply -f .

# create a service
kubectl run echoheaders --image=gcr.io/google_containers/echoserver:1.8 --replicas=1 --port=8080
kubectl expose deployment echoheaders --port=80 --target-port=8080 --name=echoheaders-x
kubectl expose deployment echoheaders --port=80 --target-port=8080 --name=echoheaders-y

# create an ingress
cat <<EOF | kubectl apply -f -
# This is the Ingress resource that creates a HTTP Loadbalancer configured
# according to the Ingress rules.
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: echomap
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /foo
        backend:
          serviceName: echoheaders-x
          servicePort: 80
  - host: bar.baz.com
    http:
      paths:
      - path: /bar
        backend:
          serviceName: echoheaders-y
          servicePort: 80
      - path: /foo
        backend:
          serviceName: echoheaders-x
          servicePort: 80
EOF

kubectl describe ingress
# Name:             echomap
# Namespace:        default
# Address:          10.146.0.2
# Default backend:  default-http-backend:80 (<none>)
# Rules:
#   Host         Path  Backends
#   ----         ----  --------
#   foo.bar.com
#                /foo   echoheaders-x:80 (<none>)
#   bar.baz.com
#                /bar   echoheaders-y:80 (<none>)
#                /foo   echoheaders-x:80 (<none>)

echo "$(minikube ip) mini-echo.io mini-web.io" | sudo tee -a /etc/hosts
echo "Visit http://mini-echo.io, http://mini-web.io/echo and http://echo.$(minikube ip).xip.io"