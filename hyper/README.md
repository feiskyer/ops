# HyperContainer

* Website: <https://hypercontainer.io/>
* Github: <https://github.com/hyperhq/hyperd>

## Build deb package

```sh
docker run -v $(pwd):/data --rm feisky/hyper-build
```

## Build RPM for CentOS

```
docker run -it gnawux/buildenv:centos
```

## Hyperd API Usage

### Create a Pod via REST API

```sh
curl --unix-socket /var/run/hyper.sock -X POST "http://localhost/pod/create" \
-H -H "Content-Type: application/json"
-d $'{
    "id": "test",
    "hostname": "test",
    "resource": {
        "vcpu": 1,
        "memory": 64
    },
    "tty": true
}'
```

### Create a container via REST API

```sh
curl --unix-socket /var/run/hyper.sock -X POST "http://localhost/container/create?podId=test&name=test" \
     -H "Content-Type: application/json" \
     -d $'{
  "name": "file-tester",
  "image": "busybox:latest",
  "workdir": "/",
  "volumes": [
    {
      "path": "/data",
      "volume": "testvol",
      "readOnly": true,
      "detail": {
        "name": "testvol",
        "source": "/tmp",
        "format": "vfs"
      }
    }
  ],
  "command": [
    "sh",
    "-c",
    "cat /data/test"
  ]
}'
```

