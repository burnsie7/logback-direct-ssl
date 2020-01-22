# sudo docker network create <NETWORK_NAME>
# docker run -d --name app --network <NETWORK_NAME> my-company/my-app:latest
# docker run -d -p 8080:8080 -p 7199:7199 dogdemo/java_web_project:latest

# build servlet and create war file
FROM maven:latest AS warfile
WORKDIR /usr/src/java-web-project
COPY pom.xml .
RUN mvn -B -f pom.xml -s /usr/share/maven/ref/settings-docker.xml dependency:resolve
COPY . .
RUN mvn -B -s /usr/share/maven/ref/settings-docker.xml package

# build tomcat and copy run.sh
FROM tomcat:9.0-jre8-alpine
WORKDIR /usr/local/tomcat/bin
COPY run.sh run.sh
RUN chmod +x run.sh

# copy war file
WORKDIR /usr/local/tomcat/webapps
COPY  --from=warfile /usr/src/java-web-project/target/java-web-project.war java-web-project.war

# set datadog environment variables
#DD_SERVICE_NAME=JAVA_APM_SERVICE_NAME
#DD_AGENT_HOST=DD_AGENT_HOST
ENV DD_TRACE_AGENT_PORT=8126
ENV DD_JMXFETCH_ENABLED="true"
ENV DD_LOGS_INJECTION="true"
ENV DD_TRACE_ANALYTICS_ENABLED="true"
ENV DD_JDBC_ANALYTICS_ENABLED="true"
ENV DD_JMS_ANALYTICS_ENABLED="true"

# expose ports
EXPOSE 8080
EXPOSE 7199

# copy datadog java agent
WORKDIR /usr/local/tomcat/bin
COPY dd-java-agent.jar .

# run start script
CMD ["run.sh"]
