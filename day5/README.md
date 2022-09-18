# Volumes
   
   The lifetime of a Kubernetes Volume is the same as that of the pod that uses it. In other words, even if the containers within a pod restart, the same Volume will be used by the new container as well. Hence, the data isn't lost across container restarts. However, once a pod
terminates or is restarted, the Volume ceases to exist, and the data is lost.

   ## Types:

      - emptyDir


         - Empty directory that's created when a pod is assigned to a node.
         - All the containers running inside the pod have the ability to write and read files from this directory.
         - Same emptyDir Volume can be mounted on different paths for different containers.

         - Use a RAM-based filesystem (tmpfs) to store the Volume
         - tmpfs storage is cleared on the system reboot of the node on which the pod is running. 
         - Second, the data stored in a memory-based Volume counts against the memory limits of the container.

      ### Use Cases
         
         - Temporary scratch space for computations requiring a lot of space, such as on-disk merge sort.

         - Storage required for storing checkpoints for a long computation, such as training machine learning models where the progress needs to be saved to recover from crashes

      - hostPath

         - Mount a file or a directory from the host node's filesystem to a pod
         
      ### Use Cases

         - Allowing pods to be created only if a particular host path exists on the host node before running the pod. For example, a pod may require some Secrets or credentials to be present in a file on the host before it can run

         - Running a container that needs access to Docker internals. We can do that by setting hostPath to /var/lib/docker.

   ``` SHELL

     volumes:
   - name: data-volume
     emptyDir:
        medium: Memory
``` 

# Persistent Volume

   - Kubernetes object that represents a block of storage in the cluster.
   - not scoped to a single namespace
   - PersistentVolumeClaim (PVC) needs to be created
   - PVCs are scoped by namespaces, so pods can only access the PVCs created within the same namespace.

### Spec

   - storageClassName 
      
      - provides a way for administrators to describe the different types or profiles of storages they support.
      - A PV belonging to a certain storage class can only be bound to a PVC requesting that particular class

   - capacity

      - storage capacity of the PV
       
   - volumeMode

      - Filesystem : traditional filesystem on the persistent volume
      - Block : raw block device as storage

   - accessModes

      - ReadWriteOnce (RWO)
      - ReadOnlyMany (ROX)
      - ReadWriteMany (RWX)

   - persistentVolumeReclaimPolicy

      - Retain : data stored in the PV is kept in storage even after the PV has been released
      - Recycle : PV is released, the data on the volume is deleted using a basic rm -rf command
      - Delete : PV is released, both the PV as well as the data stored in the underlying storage will be deleted.

### PV Status

   - Available: This indicates that the PV is available to be claimed.
   - Bound: This indicates that the PV has been bound to a PVC.   
   - Released: This indicates that the PVC bound to this resource has been deleted; however, it's yet to be reclaimed by some other PVC.
   - Failed: This indicates that there was a failure during
reclamation


   
# Persistent Volume Claim

   - storageClassName: 

      - PVs of the same storage class can be bound.
      - If the storageClassName field is set to an empty string (""),these PVCs will only be bound to PVs that have no storage class set.
      - If the storageClassName field in the PVC is not set, then it depends on whether DefaultStorageClass has been enabled by the administrator. If a default storage class is set for the cluster, the PVCs with no storageClassName field set will be bound to PVs with that default storage class. Otherwise, PVCs with no storageClassName field set will only be bound to PVs that have no storage class set

   - resources:

      - PVs satisfying the resource requests can be bound to a PVC.

   - volumeMode:

      - A PVC can only be bound to a PV that has the same Volume mode as the one specified in the PVC configuration.

   - accessMode: 
      
      - A PVC should specify the access mode that it needs, and a PV is assigned as per the availability based on that access mode.

   - selectors:

      - Only the PVs whose labels satisfy the conditions specified in the selectors field are considered for a claim. When both of these fields are used together as selectors, the conditions specified by the two fields are combined using an AND operation.


## Provisioning

   - Static: provision several PVs beforehand, and only then are they available to PVCs as available resources.
   
   - Dynamic: the cluster will dynamically provision the PV for the PVC based on the storage class requested


