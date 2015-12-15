# docker-keycloakproxy

Used to authenticate your apps to keycloak.

## Settings

These settings can either be set in the environment or added in secret files.  See usage for example of secrets file.

* AUTHSERVERURL - The URL of your keycloak server.
* BINDADDRESS - The bindaddress keycloak listens on.  Default is localhost which is fine for kubernetes, but you may have to bind an external address in your implementation.
* HTTPPORT -  The port Keycloak Listens on.
* PATTERN - The pattern you want to auth.  An example would be "/example-path" instead.  Example in usage auth's the entire site.
* REALM - The name of the keycloak relam you want to auth to.
* REALMPUBLICKEY - The public key for the realm you're using.
* RESOURCE - Keycloak Resource
* SECRET - Your keycloak Secret
* TARGETURL - The URL you're passing auth'd results too.  Usually your app.


### Usage

The example below will run a keycloak container.

```
docker run --rm=true \
       -p 8081:8081 \
       -v ${PWD}/secrets:/etc/secrets \
       quay.io/ukhomeofficedigital/keycloak-proxy:v0.0.1
```

This assumes you have first create the secrets folder and have populate appopriately.  The secrets are kubernetes compatible, thus if you're not using kubernetes, the name of the secret is the filename and the value is the content of said file.  Thus your secrets folder will look like this:-

```
authserverurl
bindaddress
httpport
pattern
realm
realmpublickey
resource
secret
targeturl
```

In the event you are using kubernetes, you can generate a secrets files thusly:-

```
cat << EOF > ./keycloak-sect.yaml
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-secrets
type: Opaque
data:
  authserverurl: $(echo "https://keycloak.example.com/auth" | base64)
  bindaddress: $(echo "127.0.0.1" | base64)
  httpport: $(echo "8081" | base64)
  pattern: $(echo "/*" | base64)
  realm: $(echo "example" | base64)
  realmpublickey: $(echo "your-keycloak-realm-public-key" | base64)
  resource: $(echo "example-api" | base64)
  secret: $(echo "your-keycloak-secret" | base64)
  targeturl: $(echo "http://localhost:8000" | base64)
EOF
```
The container and thus the example secrets have been created with the intention that the proxy will live in a kubernetes pod with a waf, terminating TLS before keycloak, passing to keycloak-proxy, which then passes onto the app.  Thus you'd have a ReplicationController which looks like this:-

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: example
spec:
  replicas: 3
  selector:
    name: example
  template:
    metadata:
      labels:
        name: example
    spec:
      containers:
      - name: tls
        image: quay.io/ukhomeofficedigital/nginx-proxy:v1.0.0
        imagePullPolicy: Always
        ports:
        - containerPort: 443
        env:
        - name: PROXY_SERVICE_HOST
          value: 127.0.0.1
        - name: PROXY_SERVICE_PORT
          value: "8000"
        volumeMounts:
          - name: external-tls
            mountPath: /etc/keys
            readOnly: true
      - name: keycloak-proxy
        image: quay.io/ukhomeofficedigital/keycloak-proxy:v0.0.1
        imagePullPolicy: Always
        ports:
        - containerPort: 8081
        volumeMounts:
          - name: keycloak-secrets
            mountPath: /etc/secrets
            readOnly: true
      - name: app
        image: quay.io/ukhomeofficedigital/example-app:v0.0.1
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
      volumes:
        - name: external-tls
          secret:
            secretName: external-tls
        - name: keycloak-secrets
          secret:
            secretName: keycloak-secrets
```
Alternativly you can run the container environment by passing enviornment variables like so:-

```
docker run --rm=true \
       -p 8081:8081 \
       -v ${PWD}/secrets:/etc/secrets \
       -e AUTHSERVERURL=$(echo "https://keycloak.example.com/auth" | base64) \
       -e BINDADDRESS=$(echo "127.0.0.1" | base64) \
       -e HTTPPORT=$(echo "8081" | base64) \
       -e PATTERN=$(echo "/*" | base64) \
       -e REALM=$(echo "example" | base64) \
       -e REALMPUBLICKEY=$(echo "your-keycloak-realm-public-key" | base64) \
       -e RESOURCE=$(echo "example-api" | base64) \
       -e SECRET=$(echo "your-keycloak-secret" | base64) \
       -e TARGETURL=$(echo "http://localhost:8000" | base64) \
       quay.io/ukhomeofficedigital/keycloak-proxy:v0.0.1
```

