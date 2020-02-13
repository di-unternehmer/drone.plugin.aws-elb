FROM atlassian/pipelines-awscli:1.16.185

COPY pipe /bin/
COPY LICENSE.txt README.md pipe.yml /

RUN chmod +x /bin/common.sh
RUN chmod +x /bin/pipe.sh

WORKDIR /drone/src

ENTRYPOINT ["/bin/pipe.sh"]
