#!/bin/bash
## Network Policy DEMO for minikube.

# Create local cluster.
minikube start --docker-env HTTP_PROXY=${PROXY_SERVER} \
    --docker-env HTTPS_PROXY=${PROXY_SERVER} \
    --vm-driver=xhyve --network-plugin=cni \
    --extra-config=kubelet.ClusterCIDR=172.168.0.0/16 \
    --extra-config=proxy.ClusterCIDR=172.168.0.0/16 \
    --extra-config=controller-manager.ClusterCIDR=172.168.0.0/16

# Setup calico
curl -O -L https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
sed -i -e '/nodeSelector/d' calico.yaml
sed -i -e '/node-role.kubernetes.io\/master: ""/d' calico.yaml
sed -i -e 's/10\.96\.232/10.0.0/' calico.yaml
sed -i -e 's/192\.168/172.168/' calico.yaml
kubectl apply -f calico.yaml

# create nginx service
kubectl run nginx --image=nginx --replicas=2
kubectl expose deployment nginx --port=80 --type=NodePort

# nginx is accessible outside
wget --spider --timeout=1 $(minikube service nginx --url)

# create a default deny service
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
EOF

# nginx is not accessible now
wget --spider --timeout=1 $(minikube service nginx --url)

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
kubectl run busybox -it --rm --image=busybox sh
# wget --spider --timeout=1 nginx


# 而带有access=true标签的Pod可以访问nginx服务
kubectl run busybox2 -it --rm --labels="access=true" --image=busybox sh
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

# 现在外网可以访问了
curl $(minikube service nginx --url)
