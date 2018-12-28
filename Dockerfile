FROM atlassian/pipelines-awscli:1.16.18

COPY pipe /usr/bin/

ENTRYPOINT ["/usr/bin/pipe.sh"]
