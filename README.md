# ksten-nfs
## Install NFS server

```console
apt update
apt install nfs-kernel-server
```

#Create and configure directory to share
mkdir -p /srv/nfs_share
chown nobody:nogroup /srv/nfs_share
chmod 755 /srv/nfs_share

#Configure exports
#Example:
#/srv/nfs_share    192.168.1.0/24(rw,sync,no_subtree_check)
#/srv/nfs_share    127.0.0.1/24(rw,sync,no_subtree_check)
echo "/srv/nfs_share    127.0.0.1/24(rw,sync,no_subtree_check)" | tee -a /etc/exports

#Apply modification and restart service
exportfs -a
systemctl restart nfs-kernel-server

#Mount share on client
apt install nfs-common
mkdir -p /mnt/nfs_share
mount 127.0.0.1:/srv/nfs_share /mnt/nfs_share

#Automate Mount in /etc/fstab
# Example: 192.168.1.10:/srv/nfs_share /mnt/nfs_share nfs defaults 0 0
echo "127.0.0.1:/srv/nfs_share /mnt/nfs_share nfs defaults 0 0" | tee -a /etc/fstab

#Create a PV defining the exported NFS share
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
      path: /mnt/nfs_share
      server: 127.0.0.1
EOF

#Create PVC
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


kind: Profile
apiVersion: config.kio.kasten.io/v1alpha1
metadata:
  name: nfs-share
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

