FROM centos:latest

MAINTAINER "Daniel Vargas" <dlvargas@stanford.edu>

# Set container entrypoint
ENTRYPOINT ["/init.sh"]

# Install Cloudera CDH5 RPM repository
RUN rpm --import https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/RPM-GPG-KEY-cloudera
# RUN curl -o /etc/yum.repos.d/cloudera-cdh5.repo https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/cloudera-cdh5.repo
ADD https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/cloudera-cdh5.repo /etc/yum.repos.d/cloudera-cdh5.repo
# ADD cloudera/cloudera-cdh5.repo /etc/yum.repos.d/cloudera-cdh5.repo

# Install and update packages
RUN yum -y install hadoop-hdfs-fuse java-1.8.0-openjdk-devel unzip
RUN yum -y update && yum clean all && rm -rf /var/cache/yum

# Install Gradle
ADD https://services.gradle.org/distributions/gradle-2.13-all.zip ./gradle-2.13-all.zip
RUN mkdir -p /opt/gradle
RUN unzip ./gradle-2.13-all.zip -d /opt/gradle

# Set environment variables
ENV GRADLE_HOME /opt/gradle/gradle-2.13
ENV PATH $PATH:/opt/gradle/gradle-2.13/bin:/usr/lib/jvm/jre/bin
ENV JAVA_HOME /usr/lib/jvm/jre

# Make EDINA indexer base directory
RUN mkdir /lockss-solr
WORKDIR /lockss-solr

# Add EDINA indexer source
ADD ./src /lockss-solr/src
ADD ./*.gradle /lockss-solr/
ADD ./gradle /lockss-solr/

# Build EDINA indexer JAR
RUN gradle fatJar

# Add entrypoint shell script
ADD scripts/init.sh /init.sh
ADD scripts/watchdir.sh /watchdir.sh
