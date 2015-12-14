#!/bin/bash

#Pickup any secrets
for f in /etc/secrets/* ; do
    if test -f "$f"; then
        export $(echo $(basename $f) | awk '{print toupper($0)}')="$(eval "echo \"`<$f`\"")"
    fi
done 

cat <<- EOF > ${PWD}/keycloak-proxy/config.json
{
  "target-url": "${TARGETURL}",
  "send-access-token": ${SENDACCESSTOKEN:-true},
  "http-port": "${HTTPPORT}",
  "bind-address": "${BINDADDRESS:-localhost}",
  "applications": [
    {
      "base-path": "/",
      "adapter-config": {
        "realm": "${REALM}",
        "realm-public-key": "${REALMPUBLICKEY}",
        "auth-server-url": "${AUTHSERVERURL}",
        "ssl-required": "${SSLREQUIRED:-external}",
        "resource": "${RESOURCE}",
        "credentials": {
          "secret": "${SECRET}"
        }
      },
      "constraints": [
        {
          "pattern": "${PATTERN}",
          "authenticate": true
        }
      ]
    }
  ]
}
EOF

cat ${PWD}/keycloak-proxy/config.json

exec java -jar ${PWD}/keycloak-proxy/bin/launcher.jar ${PWD}/keycloak-proxy/config.json
