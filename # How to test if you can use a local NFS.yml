# How to test if you can use a local NFS PVC

echo | kubectl apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: basic-app
  namespace: kasten-io
  labels:
    app: basic-app
spec:
  strategy:
    type: Recreate
  replicas: 1
  selector:
    matchLabels:
      app: basic-app
  template:
    metadata:
      labels:
        app: basic-app
    spec:
      containers:
      - name: basic-app-container   
        image: docker.io/alpine:latest
        resources:
            requests:
              memory: 256Mi
              cpu: 100m
        command: ["tail"]
        args: ["-f", "/dev/null"]         
        volumeMounts:
        - name: data
          mountPath: /data        
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: nfs-pvc
EOF

#ensure you can connect to the pod and write on /data (adapt basic-app pod name to your current situation)
kubectl exec -n kasten-io -it basic-app-pod prhb -- sh