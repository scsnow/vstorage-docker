FROM 10.28.29.130:5000/vz7-minimal
RUN yum install -y vstorage-chunk-server vstorage-metadata-server && \
yum clean all
ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
