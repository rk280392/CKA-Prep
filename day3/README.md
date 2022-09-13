# Labels and Annotations

## Labels
   
   - key:value pairs that can be attached to objects

   - Keys must be unique

   - Objects can be indexed and searched using labels

   ### Constraints of labels:
      
      - Label Keys: Example label_prefix.com/worker-node-1
         
            - Label prefix 
               
               - Must be a DNS subdomain
               - Cannot be longer than 253 characters, no spaces
               - If no prefix is used, the label key is assumed to be private to the user.
               - kubernetes.io/ and k8s.io/, are reserved for Kubernetes core systems.
            
            - Label name

               - Required field and 63 characters long
               - (a-z A-Z 0-9 -_.) are allowed
               - No spaces allowed

      
      - Label Values: 
         
            - 63 charachters long
            - (a-z A-Z 0-9 -_.) are allowed
            - No spaces allowed

      
   ###   Use Cases:
         
         - Running Selective Pods on Specific Nodes ( label the node and use NodeSelector in Pod spec)
         - Organizing Pods by Organization/Team/Project

   ### Selecting Kubernetes Objects Using Label Selectors: 

         - kubectl get pods -l {label_selector}

   #### Equality-Based Selectors

         - operators: =, ==, and !=.
   #### Set-Based Selectors
      
         - operators: in, notin, and exists


## Annotations

   - Annotations are also key-value pairs that can be used to store the unstructured information pertaining to the Kubernetes objects.
   
### Constraints for Annotations

   - key-value pairs of annotations are notstored in a lookup-efficient data structure.

   #### Annotation Keys
      
      - two parts: a prefix and a name.
      - Eg. annotation_prefix.com/worker-node-identifier

   #### Annotation Values

      - There are no restrictions in terms of what kinds of data annotation values may contain.

   ###   Use Cases:

      - used to add timestamps, commit SHA, issue tracker links, or names/information
      - add information about client libraries or tools.
      - store the previous pod configuration deployed
      - store the configuration or checkpoints that can be helpful in the deployment process for our applications.


# Kubernetes Controllers

   - ReplicaSets
      
      - Creates and maintains number of replicas

   - Deployment

      - wrapper around a ReplicaSet
      - manage the ReplicaSet and the Pods created by the ReplicaSet
      - maintains a history of revisions.
      - a new revision of the ReplicaSet is recorded by the Deployment. This way, using a Deployment makes it easy to roll back to a previous state or version. Keep in mind that every rollback will also create a new revision for the Deployment.

  - StatefulSets

     - StatefulSets are used to manage stateful replicas
     - Pods managed by a StatefulSet will persist their sticky identity (integer ordinal) even if the Pod restarts. For example, if a particular Pod crashes or is deleted, a new Pod will be created and assigned the same sticky identity as that of the old Pod.

  - DaemonSets

     - Run specific instance of pod on each node.
     - When new nodes are added, pods will be be created on them as well.
     - Logging, Local data caching, Monitoring

  - Jobs

     - A Job is a supervisor in Kubernetes that can be used to manage Pods that are supposed to run a determined task and then terminate gracefully.    
     - When a specified number of Pods complete successfully, the Job is considered complete

