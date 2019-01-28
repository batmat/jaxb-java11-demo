
FROM jenkins/jenkins:2.159
LABEL maintainer="Baptiste Mathus <batmat@batmat.net>"

USER root

RUN apt-get update -y \
    && apt-get install sloccount -y
RUN wget --quiet https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz --output-document=/tmp/jdk11.tgz

RUN cd /usr \
    && tar xvzf /tmp/jdk11.tgz && \
    ls /usr/jdk-11.0.2/

# Override the WAR with https://github.com/jenkinsci/jenkins/pull/3865 automatically making JAXB as detached on Java 11
# Incrementals is currently broken unfortunately https://issues.jenkins-ci.org/browse/INFRA-1964
RUN wget --quiet https://ci.jenkins.io/job/Core/job/jenkins/job/PR-3865/lastSuccessfulBuild/artifact/org/jenkins-ci/main/jenkins-war/2.163-rc27905.f02266439f5c/jenkins-war-2.163-rc27905.f02266439f5c.war \
    --output-document /usr/share/jenkins/jenkins.war

COPY jenkins.sh /usr/local/bin/jenkins.sh
USER jenkins

ENV JENKINS_ENABLE_FUTURE_JAVA=true

# sloccount installed here only to pull in transitive workflow dependencies and so on automatically, the plugin is then replaced below
RUN /usr/local/bin/install-plugins.sh \
    configuration-as-code \
    sloccount

ENV CASC_JENKINS_CONFIG=$JENKINS_HOME/config-as-code.yaml
ENV JENKINS_ADMIN_PASSWORD admin
COPY config-as-code.yaml /usr/share/jenkins/ref/config-as-code.yaml

COPY jobs /usr/share/jenkins/ref/jobs/

ENV JAVA_OPTS=\
"-Djenkins.install.runSetupWizard=false "

ENV PATH="/usr/jdk-11.0.2/bin:$PATH"
