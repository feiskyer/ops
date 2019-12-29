#!/bin/bash
# Access API via curl within Pods

# Get token and CA
TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Access API
curl --cacert $CACERT --header "Authorization: Bearer $TOKEN"  https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT/api

# Example outputs
#{
#  "kind": "APIVersions",
#  "versions": [
#    "v1"
#  ],
#  "serverAddressByClientCIDRs": [
#    {
#      "clientCIDR": "0.0.0.0/0",
#      "serverAddress": "10.0.1.149:443"
#    }
#  ]
#}
