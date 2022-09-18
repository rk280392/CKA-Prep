# Configmap

   - define application-related data.
   - decouples the application data from the application so that the same application can be ported across different environments
   - provides a way to inject customized data into running services from the same container image.

# Secret

   - Secret is intended to store a small amount (1 MB for a Secret) of sensitive data
   - base64-encoded
   - can also store binary data such as a public or private key
   - Secrets are passed only to the nodes that are running the Pods that need the respective Secrets.

## Type:

   - generic: A generic Secret holds any custom-defined key-value pair.
   - tls: A TLS Secret is a special kind of Secret for holding a public-private key pair for communication using the TLS protocol.
   - docker-registry: This is a special kind of Secret that stores the username, password, and email address to access a Docker registry.
