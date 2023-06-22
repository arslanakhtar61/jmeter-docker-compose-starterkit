#Step 1
FROM ubuntu:18.04
LABEL VENDOR=SAP \
PRODUCT=arslan.akhtar \
Version=1.0.1

# Step 2
ARG JMETER_VERSION="5.5"
ARG CMDRUNNER_JAR_VERSION="2.3"
ARG JMETER_PLUGINS_MANAGER_VERSION="1.9"
ENV JMETER_HOME /opt/jmeter
ENV JMETER_LIB_FOLDER ${JMETER_HOME}/lib/
ENV JMETER_PLUGINS_FOLDER ${JMETER_LIB_FOLDER}ext/

#Step 3:
RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-get install -y wget gnupg curl tzdata unzip bash coreutils \
    && mkdir -p /opt/jmeter/results \
    && mkdir /opt/jmeter/logs/ \
    && mkdir /temp

WORKDIR /
ENTRYPOINT ["/opt/entrypoint.sh"]
COPY ./entrypoint.sh /opt/entrypoint.sh
ENV HOME /opt/jmeter/

# Step 4:
# Download Apache JMeter
WORKDIR ${JMETER_HOME}
RUN wget https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz
RUN tar -xzf apache-jmeter-${JMETER_VERSION}.tgz
RUN mv apache-jmeter-${JMETER_VERSION}/* ${JMETER_HOME}
RUN rm -r /opt/jmeter/apache-jmeter-${JMETER_VERSION}

WORKDIR /
COPY ./apache-jmeter-${JMETER_VERSION}/bin/jmeter.properties ${JMETER_HOME}/bin/
COPY ./apache-jmeter-${JMETER_VERSION}/bin/user.properties ${JMETER_HOME}/bin/
WORKDIR ${JMETER_HOME}

# Step 5:
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
&& apt-get update \
&& apt-get install -y --no-install-recommends \
git \
openjdk-8-jre-headless

# Step 6:
# Download Command Runner and move it to lib folder
WORKDIR ${JMETER_LIB_FOLDER}
RUN wget https://repo1.maven.org/maven2/kg/apc/cmdrunner/${CMDRUNNER_JAR_VERSION}/cmdrunner-${CMDRUNNER_JAR_VERSION}.jar

# Step 7:
# Download JMeter Plugins manager and move it to lib/ext folder
WORKDIR ${JMETER_PLUGINS_FOLDER}
RUN wget https://repo1.maven.org/maven2/kg/apc/jmeter-plugins-manager/${JMETER_PLUGINS_MANAGER_VERSION}/jmeter-plugins-manager-${JMETER_PLUGINS_MANAGER_VERSION}.jar

# Step 8:
WORKDIR ${JMETER_LIB_FOLDER}
RUN java  -jar cmdrunner-${CMDRUNNER_JAR_VERSION}.jar --tool org.jmeterplugins.repository.PluginManagerCMD install-all-except jpgc-hadoop,jpgc-oauth,ulp-jmeter-autocorrelator-plugin,ulp-jmeter-videostreaming-plugin,ulp-jmeter-gwt-plugin,tilln-iso8583

# Step 10:
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:${PATH}"
RUN update-ca-certificates

#WORKDIR ${JMETER_HOME}
WORKDIR /
