# Setup NFS to create an NFS export location for Veeam Kasten

The aim of this procedure is to configure NFS to be used as an export location for Veeam Kasten.

Below we'll assume that the NFS server will run on the IP 10.10.10.10 and reachable from your worker nodes. 

This procedure needs to be adapted for your own environement.

## Install NFS server

```console
sudo apt-get update
sudo apt-get install nfs-common nfs-kernel-server -y
```

### Create and configure directory to share

```console
sudo mkdir -p /data/nfs
sudo chown nobody:nogroup /data/nfs
sudo chmod 2770 /data/nfs
```

### Configure exports

Be sure to change the IP below:

```console
echo -e "/data/nfs\t10.10.10.10/24(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
```

And automate mount:

```console
echo "10.10.10.10:/srv/nfs_share /mnt/nfs_share nfs defaults 0 0" | tee -a /etc/fstab
```

### Apply modification and restart service

```console
sudo exportfs -av
sudo systemctl restart nfs-kernel-server
sudo systemctl status nfs-kernel-server
```

### Check your export details

Do not forget to change IP by the NFS server one below:

```console
/sbin/showmount -e 10.10.10.10
```

## Install NFS client packages on K8s nodes

Reminder: all nodes must have the NFS client packages installed.

```console
sudo apt update
sudo apt install nfs-common -y
```

### Install NFS provisioner

Do not forget to change IP by the NFS server one below:

```console
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
kubectl create namespace nfs-storage
helm upgrade --install -n nfs-storage --create-namespace nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=10.10.10.10 \
    --set nfs.path=/data/nfs \
    --set storageClass.name=nfs \
    --set storageClass.archiveOnDelete=false
```

### Create a PV on the exported NFS share

Do not forget to change IP by the NFS server one below:

```console
echo | kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
   name: nfs-pv
spec:
   capacity:
      storage: 10Gi
   volumeMode: Filesystem
   accessModes:
      - ReadWriteMany
   persistentVolumeReclaimPolicy: Retain
   storageClassName: nfs
   mountOptions:
      - hard
      - nfsvers=4.1
   nfs:
      path: /data/nfs
      server: 10.10.10.10
EOF
```

### Create the NFS PVC

```console
echo | kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
   name: nfs-pvc
   namespace: kasten-io
spec:
   storageClassName: nfs
   accessModes:
      - ReadWriteMany
   resources:
      requests:
         storage: 10Gi
EOF
```

### Create the NFS location profile for Veeam Kasten

```console
echo | kubectl apply -f - << EOF
kind: Profile
apiVersion: config.kio.kasten.io/v1alpha1
metadata:
  name: nfs
  namespace: kasten-io
spec:
  locationSpec:
    type: FileStore
    fileStore:
      claimName: nfs-pvc
      path: /
    credential:
      secretType: ""
      secret:
        apiVersion: ""
        kind: ""
        name: ""
        namespace: ""
  type: Location
EOF
```

