FROM atlassian/pipelines-awscli:1.16.18

COPY task /usr/bin/

ENTRYPOINT ["/usr/bin/task.sh"]
