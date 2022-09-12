#Today's Readings

##   - API Severs

      - In Kubernetes, all communications and operations between the control plane components and external clients, such as kubectl, are translated into RESTful API calls that are handled by the API server.

      - It acts a frontend component that acts as a gateway to and from the outside world. It is accessible by all the clients including the cluster components
      
      - It is the only component that interacts with etcd

##   - HTTP Request Flow
      
#### Authentication:

      - HTTP requests sent to API server needs to go through authentication first. Request must containe required informations such as the username, user ID, and group. Authentication method is determined by either the header or the certificate of the request, tokens and X.509 client certificates are used mostly. Read more here https://kubernetes.io/docs/reference/access-authn-authz/authentication/.

      - API server calls those plugins one by one until one of them authenticates the request. If all of them fail, authentication is rejected. Once authentication succeeds, request proceeds to the authorization phase.

#### Authorization:

      - Authorization phase defines what kind of operations can be performed through the request.

      - Check your authorization `kubectl auth can-i get pods -A

      - Authorization modules are checked sequencly. In case of multiple authorization modules, if any authorizer approves or denies a request, that decision is immediately returned, and no authorizer will be contacted.

####  Admission Control:
      
      - After authentication and authorization request goes to admission control. These can modify or reject requests.

      - For readonly requests, admission control is bypassed

      - Admission control is triggered if request is trying to create, modify, or delete.

      - Examples: NamespaceLifecycle, NamespaceExists

```SHELL

      - kubectl describe pod kube-apiserver-minikube -n kube-system | grep enable-admission-plugins
```

#### Validation:
      
      - After request has passed authentication, authorization and admission control, API control validates the object.

      - It checks whether the object specification, which is carried in JSON format in the response body, meets the required format and standard.

      - After successful validation API server updates etcd and retrums a response to the client.


### Kubernetes API HTTP verbs

   INSERT IMAGE HERE

   - kubectl get pods -n kube-system

   - kubectl invokes an HTTP GET request to the API server endpoint and requests information from /api/v1/namespaces/kube-system/pods.

   - Enable verbose by adding --v=<level>. Eg. --v=8. Higher number more details

### Scope of API Resources

   - namespace scope

      - Return the information about a specific pod in a namespace: 

      `GET /api/v1/namespaces/{my-namespace}/pods/{pod-name}`

      - Return the information about a collection of all Deployments in a namespace:

      `GET /apis/apps/v1/namespaces/{my-namespace}/deployments`

      - Return the information about all instances of the resource type (in this case, services) across all namespaces:

      `GET /api/v1/services`

Notice that when we are looking for information against all namespaces, it will not have namespace in the URL.

      - Get full list of namespace-scoped API resurces:

      `kubectl api-resources --namespaced=true`

   - Clustered scope

      - Namespace scope is is clusterd scope
      
      - Return the information about a specific node in the cluster:

      `GET /api/v1/nodes/{node-name}`

      - Return the information of all instances of the resource type (in this case, nodes) in the cluster:

      `GET /api/v1/nodes`

      - You can get a full list of cluster-scoped API resources by using the following command:

      `kubectl api-resources --namespaced=false`


### API Groups
   
   - An API group is a collection of resources that are logically related to each other. For example, Deployments, ReplicaSets, and DaemonSets
all belong to the apps API group: apps/v1.
   
   #### Core Group
     
   - It contains objects such as pods, services, nodes, and namespaces. The URL path for these is /api/v1, and nothing other than the version is  specified in the apiVersion field.

   - `kubectl api-resources --api-group=''`

   #### Named Group

   - This group includes objects for whom the request URL is in the /apis/$NAME/$VERSION format. Unlike the core group, namedgroups contain the group name in the URL.

   - Eg `kubectl api-resources --api-group='apps'`


   #### System Wide

   - This group consists of system-wide API endpoints, such as /version, /healthz, /logs, and /metrics.

   - Eg. `kubectl version --short --v=6`. This goes to the /version special entity, as seen in the GET request URL.


### API Versions

   - Alpha 

      - The alpha version of resources is disabled by default as it is not intended for production clusters but can be used by early adopters and developers who are willing to provide feedback and suggestions and report bugs. Also, support for alpha resources may be dropped without notice by
the time the final stable version of Kubernetes is finalized. 
      
      - Eg. /apis/batch/v1alpha1

   - Beta
      
      - The beta version of resources is enabled by default, and the code behind it is well tested. However, using it is recommended for scenarios
that are not business-critical because it is possible that changes in subsequent releases may reduce incompatibilities; that is, some features may not be supported for a long time.

      - Eg. /apis/certificates.k8s.io/v1beta1

   - Stable

      - The Stable version of resources is supported for many subsequent versions releases of Kubernetes. So, this version of API resources is recommended for any critical use cases.

      - Eg. /apis/networking.k8s.io/v1

   - List of the API versions enabled in your cluster `kubectl api-versions` 


## Interacting with Clusters Using the Kubernetes API

###  kubectl proxy 
      
      kubectl proxy routes the requests from our HTTP client to the API server while taking care of authentication by itself. Authentication is
also handled by using the current configuration in our kubeconfig file

    - curl -X POST <URL-path> -H 'Content-Type: application/yaml' --data <spec/manifest>. Example:

   ``` SHELL
   - curl -X POST http://127.0.0.1:8001/apis/apps/v1/namespaces/example/deployments -H 'Content-Type: application/yaml' --data 
   "apiVersion: apps/v1
   kind: Deployment
   metadata:
      labels:
      run: nginx-example
      name: nginx-example
   spec:
      replicas: 3
      selector:
         matchLabels:
            run: nginx-example
      strategy: {}
      template:
         metadata:
            labels:
               run: nginx-example
         spec:
            containers:
            - image: nginx:latest
              name: nginx-example
              resources: {}
   status: {}"

   ```

### Direct Access to the Kubernetes API Using Authentication Credentials

    - Instead of using kubectl in proxy mode, we can provide the location and credentials directly to the HTTP client.

    - Client certificates
    - ServiceAccount bearer tokens
    - Authenticating proxy
    - HTTP basic auth

Refer https://kubernetes.io/docs/reference/access-authn-authz/authentication/

   - check what authentication plugins are enabled in our cluster

   ``` SHELL

   kubectl exec -it kube-apiserver-minikube -n kube-system -- /bin/sh -c "apt update ; apt -y install procps ; ps aux | grep kube-apiserver"

   ```

####   Method 1- Using Client Certificate Authentication

   - kubectl config view
   - curl --cert <ClientCertificate> --key <PrivateKey> --cacert <CertificateAuthority> https://<APIServerAddress:port>/api

#### Method 2: Using a ServiceAccount Bearer Token

   - ServiceAccounts authenticates processes running within the cluster, eg pods.

   - Allow communication with API server.

   - Use JWT to authenticate with server, these tokens are stored in K8s object as secrets.

   - It is stored inside secret in Base64-encoded format

   - Each ServiceAccount needs to have secret associated with it. 

   - Secret is mounted on the pod and the bearer token is decoded and then mounted at /run/secrets/kubernetes.io/serviceaccount.

   - ServiceAccount needs to be accompanied with RBAC policies.

   - Create Roles and then use RoleBinding to bind those Roles to certain users or ServiceAccounts.

   - Role defines actions allowed.

   - Rolebinding defines which user or ServiceAccount can assume the Role.

   - Every namespace contains default ServiceAccount called 'default'.

   - Eg. curl --cacert $CACERT -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/$NAMESPACE/pods

## Pods
   
   - Smallest unit inside kubernetes.

   - Can contain one ore more containes depending on requirements.

   - Spec:

      ```SHELL
        apiVersion: Version of the Kubernetes API
        kind: The kind of Kubernetes object we are trying to create
        metadata: Metadata or information that uniquely identifies the object
        spec: Specification of our pod, such as container name, image name, volumes, and resource requests.
     ```

     - Cannot have two pods with the same name within the same namespace. However, it's possible to have two pods with the same name in two different namespaces.

     - Exposing port
      
      ``` SHELL
      spec:
         containers:
         - name: container-with-exposed-port
           image: nginx
           ports:
           - containerPort: 80
      ```

    - Resources

      - limits: Describes the maximum amount of resources allowed for thie container.
      - requests: Describes the minimum amount of resources required for this container.

      ``` SHELL
      spec:
         containers:
         - name: container-with-resource-requirements
           image: nginx
           resources:
              limits:
                 memory: "128M"
                 cpu: "1"
              requests:
                 memory: "64M"
                 cpu: "0.5"
       ```

      - A pod will only be scheduled on a node that satisfies all its resource requirements. If we do not specify a resource (memory or CPU) limit, there's no upper bound on the number of resources a pod can use.

      - Lifecycle
         
         - Pending: This means that the pod has been submitted to the cluster, but the controller hasn't created all its containers yet. It may be downloading images or waiting for the pod to be scheduled on one of the cluster nodes.

         - Running: This state means that the pod has been assigned to one of the cluster nodes and at least one of the containers is either running or is in the process of starting up.

         - Succeeded: This state means that the pod has run, and all of its containers have been terminated with success.

         - Failed: This state means the pod has run and at least one of the containers has terminated with a non-zero exit code, that is, it
has failed to execute its commands.

         - Unknown: This means that the state of the pod could not be found. This may be because of the inability of the controller to connect with the node that the pod was assigned to.


      - Health Checks

         - Liveness Probe

            - whether a particular container is running or not.

            - Restart if fails

         - Readiness Probe

            - whether a particular container is ready to receive requests or not
            
            - if fails, the Kubernetes controller will ensure that the pod doesn't receive any requests until it passes.

      - Implementation of Health checks

         - Command Probe

            - execute the specified command in order to perform the probe on the container 

            ```SHELL
            livenessProbe:
               exec:
                  command:
                  - cat
                  - /tmp/health
               initialDelaySeconds:
               periodSeconds: 15
               failureThreshold: 3
            readinessProbe:
               exec:
                  command:
                  - cat
                  - /tmp/health
               initialDelaySeconds:
               periodSeconds: 15

```

         - HTTP Request Probe

            - controller will send a GET HTTP request to the given address (host and port) to perform the probe on the container.

            ``` SHELL
            livenessProbe:
               httpGet:
                  path: /health-check
                  port: 8080
               initialDelaySeconds: 10
               periodSeconds: 20
           ````

         - TCP Socket Probe

            - controller will try to establish a connection on the given host and the specified port number.

            ``` SHELL
            livenessProbe:
               tcpSocket:
                  port: 8080
               initialDelaySeconds: 10
               periodSeconds: 20
            ```

         - Restart Policy

            - Always: Always restart the pod when it terminates.

            - OnFailure: Restart the pod only when it terminates with failure.

            - Never: Never restart the pod after it terminates.

