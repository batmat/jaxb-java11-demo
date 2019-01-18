
FROM jenkins/jenkins:2.159
LABEL maintainer="Baptiste Mathus <batmat@batmat.net>"

USER root

RUN apt-get update -y \
    && apt-get install sloccount -y
RUN wget https://download.java.net/java/GA/jdk11/7/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz --output-document=/tmp/jdk11.tgz

RUN cd /usr \
    && tar xvzf /tmp/jdk11.tgz && \
    ls /usr/jdk-11.0.2/

USER jenkins

ENV PATH="/usr/jdk-11.0.2/bin:$PATH"
# Uncomment when 2.161 is out and we can bump to it
# ENV JENKINS_ENABLE_FUTURE_JAVA=true

# sloccount installed here only to pull in transitive workflow dependencies and so on automatically, the plugin is then replaced below
RUN /usr/local/bin/install-plugins.sh \
    configuration-as-code \
    sloccount

# Patch sloccount & add new jaxb plugin dependency until normal releases are out (cf. JENKINS-55681)
# https://github.com/jenkinsci/sloccount-plugin/pull/53
RUN cd  /usr/share/jenkins/ref/plugins && \
    curl -sL https://repo.jenkins-ci.org/incrementals/hudson/plugins/sloccount/sloccount/1.25-rc223.f76d173e4f2d/sloccount-1.25-rc223.f76d173e4f2d.hpi > sloccount.jpi && \
    curl -sL https://repo.jenkins-ci.org/snapshots/io/jenkins/plugins/jaxb/2.2.11-alpha-1-SNAPSHOT/jaxb-2.2.11-alpha-1-20190118.085516-2.hpi > jaxb.jpi

ENV CASC_JENKINS_CONFIG=$JENKINS_HOME/config-as-code.yaml
ENV JENKINS_ADMIN_PASSWORD admin
COPY config-as-code.yaml /usr/share/jenkins/ref/config-as-code.yaml

COPY jobs /usr/share/jenkins/ref/jobs/

ENV JAVA_OPTS=\
"-Djenkins.install.runSetupWizard=false "

CMD ["--enable-future-java"]