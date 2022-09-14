# Service Discovery

   - Enables communication between various components of our application, as well as between different applications

## Types:
   
   - NodePort : Service exposes the application on the same port on all the nodes of the cluster.

      - targetPort: Container port
      - port: port of service
      - nodePort: port on the node that we can use to access the service

   - ClusterIP : exposes the application running on the Pods on an IP address that's accessible from inside the cluster only.

      - targetPort: Container port
      - port: port where the application is exposed.

   - LoadBalancer:  Exposes the application externally using the load balancer provided by the cloud provider.

   - ExternalName: maps a Service to a DNS name. 
      - Redirecting the request happens at the DNS level instead
      - Request comes for the Service, a CNAME record is returned with the value of the DNS name that was set in the Service configuration.

## Ingress

   - Ingress is an object that defines rules that are used to manage external access to the Services in a Kubernetes cluster. Typically, Ingress acts like a middleman between the internet and the Services running inside a cluster.
