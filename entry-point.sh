#!/usr/bin/env bash

set -e
set -u

####
# Pickup any secrets.  
# Turn them into upper case envs.  
# Expand on any variables that contain variables.
###
for f in /etc/secrets/* ; do
    if test -f "$f"; then
        export $(echo $(basename $f) | awk '{print toupper($0)}')="$(eval "echo \"`<$f`\"")"
    fi
done 

####
# Create config file.
# Requires either envs or secrets passed
###
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

####
# Execute the command.
###
exec $@
