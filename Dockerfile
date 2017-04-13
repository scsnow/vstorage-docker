FROM vz7-minimal:7.3
RUN yum install -y vstorage-chunk-server vstorage-metadata-server && \
yum clean all
ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
