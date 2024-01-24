---
Title: Install RedisInsight on Kubernetes
date: 2024-01-30 10:00:00
weight: 40
categories: ["RI"]
path: install/install-redisinsight/install-on-k8s/
altTag: Install RedisInsight on Kubernetes
---
In this walkthrough, we will install RedisInsight on [Kubernetes](https://kubernetes.io/).
This is an easy way to use RedisInsight with a [Redis Enterprise K8s deployment](https://redis.io/docs/about/redis-enterprise/#:~:text=and%20Multi%2Dcloud-,Redis%20Enterprise%20Software,-Redis%20Enterprise%20Software).

## Create the RedisInsight deployment and service

Below is an annotated YAML file that will create a RedisInsight
deployment and a service in a k8s cluster.

1. Create a new file redisinsight.yaml with the content below

```yaml
# RedisInsight service with name 'redisinsight-service'
apiVersion: v1
kind: Service
metadata:
  name: redisinsight-service       # name should not be 'redisinsight'
                                   # since the service creates
                                   # environment variables that
                                   # conflicts with redisinsight
                                   # application's environment
                                   # variables `RI_APP_HOST` and
                                   # `RI_APP_PORT`
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 5540
  selector:
    app: redisinsight
---
# RedisInsight deployment with name 'redisinsight'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redisinsight #deployment name
  labels:
    app: redisinsight #deployment label
spec:
  replicas: 1 #a single replica pod
  selector:
    matchLabels:
      app: redisinsight #which pods is the deployment managing, as defined by the pod template
  template: #pod template
    metadata:
      labels:
        app: redisinsight #label for pod/s
    spec:
      containers:

      - name:  redisinsight #Container name (DNS_LABEL, unique)
        image: redis/redisinsight:latest #repo/image
        imagePullPolicy: IfNotPresent #Installs the latest RedisInsight version
        volumeMounts:
        - name: data #Pod volumes to mount into the container's filesystem. Cannot be updated.
          mountPath: /data
        ports:
        - containerPort: 5540 #exposed container port and protocol
          protocol: TCP
      volumes:
      - name: data
        emptyDir: {} # node-ephemeral volume https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
```

2. Create the RedisInsight deployment and service

```sh
kubectl apply -f redisinsight.yaml
```

3. Once the deployment and service are successfully applied and complete, access RedisInsight. This can be accomplished by listing the using the `<external-ip>` of the service we created to reach redisinsight.

```sh
$ kubectl get svc redisinsight-service
NAME                   CLUSTER-IP       EXTERNAL-IP      PORT(S)         AGE
redisinsight-service   <cluster-ip>     <external-ip>    80:32143/TCP    1m
```

4. If you are using minikube, run `minikube list` to list the service and access RedisInsight at `http://<minikube-ip>:<minikube-service-port>`.
```
$ minikube list
|-------------|----------------------|--------------|---------------------------------------------|
|  NAMESPACE  |         NAME         | TARGET PORT  |           URL                               |
|-------------|----------------------|--------------|---------------------------------------------|
| default     | kubernetes           | No node port |                                             |
| default     | redisinsight-service |           80 | http://<minikube-ip>:<minikubeservice-port> |
| kube-system | kube-dns             | No node port |                                             |
|-------------|----------------------|--------------|---------------------------------------------|
```

## Create the RedisInsight deployment with persistant storage

Below is an annotated YAML file that will create a RedisInsight
deployment in a K8s cluster. It will assign a peristent volume created from a volume claim template.
Write access to the container is configured in an init container. When using deployments
with persistent writeable volumes, it's best to set the strategy to `Recreate`. Otherwise you may find yourself
with two pods trying to use the same volume.

1. Create a new file `redisinsight.yaml` with the content below.

```yaml
# RedisInsight service with name 'redisinsight-service'
apiVersion: v1
kind: Service
metadata:
  name: redisinsight-service       # name should not be 'redisinsight'
                                   # since the service creates
                                   # environment variables that
                                   # conflicts with redisinsight
                                   # application's environment
                                   # variables `RI_APP_HOST` and
                                   # `RI_APP_PORT`
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 5540
  selector:
    app: redisinsight
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redisinsight-pv-claim
  labels:
    app: redisinsight
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: default
---
# RedisInsight deployment with name 'redisinsight'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redisinsight #deployment name
  labels:
    app: redisinsight #deployment label
spec:
  replicas: 1 #a single replica pod
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: redisinsight #which pods is the deployment managing, as defined by the pod template
  template: #pod template
    metadata:
      labels:
        app: redisinsight #label for pod/s
    spec:
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: redisinsight-pv-claim
      initContainers:
        - name: init
          image: busybox
          command:
            - /bin/sh
            - '-c'
            - |
              chown -R 1001 /data
          resources: {}
          volumeMounts:
            - name: data
              mountPath: /data
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      containers:
        - name:  redisinsight #Container name (DNS_LABEL, unique)
          image: redis/redisinsight:latest #repo/image
          imagePullPolicy: IfNotPresent #Always pull image
          volumeMounts:
          - name: data #Pod volumes to mount into the container's filesystem. Cannot be updated.
            mountPath: /data
          ports:
          - containerPort: 5540 #exposed container port and protocol
            protocol: TCP
```

2. Create the RedisInsight deployment and service.

```sh
kubectl apply -f redisinsight.yaml
```

## Create the RedisInsight deployment without a service.

Below is an annotated YAML file that will create a RedisInsight
deployment in a K8s cluster.

1. Create a new file redisinsight.yaml with the content below

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redisinsight #deployment name
  labels:
    app: redisinsight #deployment label
spec:
  replicas: 1 #a single replica pod
  selector:
    matchLabels:
      app: redisinsight #which pods is the deployment managing, as defined by the pod template
  template: #pod template
    metadata:
      labels:
        app: redisinsight #label for pod/s
    spec:
      containers:
      - name:  redisinsight #Container name (DNS_LABEL, unique)
        image: redis/redisinsight:latest #repo/image
        imagePullPolicy: IfNotPresent #Always pull image
        env:
          # If there's a service named 'redisinsight' that exposes the
          # deployment, we manually set `RI_APP_HOST` and
          # `RI_APP_PORT` to override the service environment
          # variables.
          - name: RI_APP_HOST
            value: "0.0.0.0"
          - name: RI_APP_PORT
            value: "5540"
        volumeMounts:
        - name: data #Pod volumes to mount into the container's filesystem. Cannot be updated.
          mountPath: /data
        ports:
        - containerPort: 5540 #exposed conainer port and protocol
          protocol: TCP
      volumes:
      - name: data
        emptyDir: {} # node-ephemeral volume https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
```

2. Create the RedisInsight deployment

```sh
kubectl apply -f redisinsight.yaml
```

{{< note >}}
If the deployment will be exposed by a service whose name is 'redisinsight', set `RI_APP_HOST` and `RI_APP_PORT` environment variables to override the environment variables created by the service.
{{< /note >}}

3. Once the deployment has been successfully applied and the deployment complete, access RedisInsight. This can be accomplished by exposing the deployment as a K8s Service or by using port forwarding, as in the example below:

```sh
kubectl port-forward deployment/redisinsight 5540
```

Open your browser and point to <http://localhost:5540>
