FROM centos:7
RUN echo $'[virtuozzo]\n\
name=Virtuozzo\n\
baseurl=http://repo.virtuozzo.com/vz/releases/7.0/x86_64/os/\n\
enabled=1\n\
gpgcheck=0\n'\
>> /etc/yum.repos.d/virtuozzo.repo && \
yum install -y vstorage-chunk-server vstorage-metadata-server && \
yum clean all
ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
