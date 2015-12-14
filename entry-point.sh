#!/bin/bash

#Pickup any secrets
for f in /etc/secrets/* ; do
    if test -f "$f"; then
        export $(basename $f)="$(eval "echo \"`<$f`\"")"
    fi
done 

cat <<- EOF > ${PWD}/keycloak-proxy/config.json
{
  "target-url": "${targeturl}",
  "send-access-token": ${sendaccesstoken:-true},
  "http-port": "${httpport}",
  "bind-address": "${bindaddress:-localhost}",
  "applications": [
    {
      "base-path": "/",
      "adapter-config": {
        "realm": "${realm}",
        "realm-public-key": "${realmpublickey}",
        "auth-server-url": "${authserverurl}",
        "ssl-required": "${sslrequired:-external}",
        "resource": "${resource}",
        "credentials": {
          "secret": "${secret}"
        }
      },
      "constraints": [
        {
          "pattern": "${pattern}",
          "authenticate": true
        }
      ]
    }
  ]
}
EOF

exec java -jar ${PWD}/keycloak-proxy/bin/launcher.jar ${PWD}/keycloak-proxy/config.json
