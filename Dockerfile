# Incrementals is currently broken unfortunately https://issues.jenkins-ci.org/browse/INFRA-1964
# so building as an initial step in a multi-stages build
FROM maven:3.6.0-jdk-8 as builder

RUN echo hello
RUN git clone http://github.com/jenkinsci/jenkins.git && \
    cd jenkins && \
    git fetch origin pull/3865/head:PR-3865 && \
    git checkout PR-3865 && \
    mvn clean package -DskipTests -pl war -am && \
    cp war/target/jenkins.war /jenkins.war

####################
### End multi-stage
####################

FROM jenkins/jenkins:2.161
LABEL maintainer="Baptiste Mathus <batmat@batmat.net>"

USER root

RUN apt-get update -y \
    && apt-get install sloccount -y
RUN wget --quiet https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz --output-document=/tmp/jdk11.tgz

RUN cd /usr \
    && tar xvzf /tmp/jdk11.tgz && \
    ls /usr/jdk-11.0.2/

# Override the WAR with https://github.com/jenkinsci/jenkins/pull/3865 automatically making JAXB as detached on Java 11
COPY --from=builder /jenkins.war /usr/share/jenkins/jenkins.war

COPY jenkins.sh /usr/local/bin/jenkins.sh
USER jenkins

ENV JENKINS_ENABLE_FUTURE_JAVA=true

# sloccount installed here only to pull in transitive workflow dependencies and so on automatically, the plugin is then replaced below
RUN /usr/local/bin/install-plugins.sh \
    configuration-as-code

ENV CASC_JENKINS_CONFIG=$JENKINS_HOME/config-as-code.yaml
ENV JENKINS_ADMIN_PASSWORD admin
COPY config-as-code.yaml /usr/share/jenkins/ref/config-as-code.yaml

COPY jobs /usr/share/jenkins/ref/jobs/

ENV JAVA_OPTS=\
"-Djenkins.install.runSetupWizard=false "

ENV PATH="/usr/jdk-11.0.2/bin:$PATH"
