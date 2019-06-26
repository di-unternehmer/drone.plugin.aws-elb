FROM atlassian/pipelines-awscli:1.16.185

RUN wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh

COPY pipe /
COPY LICENSE.txt README.md pipe.yml /

ENTRYPOINT ["/pipe.sh"]
