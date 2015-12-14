FROM quay.io/ukhomeofficedigital/java7-mvn

RUN yum install -y unzip && yum clean all

RUN adduser app -d /opt/jboss
ENV VERSION 1.7.0.Final

USER app
WORKDIR /opt/jboss
RUN curl -o keycloak.zip https://downloads.jboss.org/keycloak/${VERSION}/keycloak-proxy-${VERSION}.zip && unzip keycloak.zip && rm keycloak.zip && mv keycloak-proxy-${VERSION} keycloak-proxy

COPY entry-point.sh /entry-point.sh
ENTRYPOINT /entry-point.sh
