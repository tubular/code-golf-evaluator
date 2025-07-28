FROM code-golf-base

ADD --chown=app:app . /app/code-golf/
# compile it
RUN /app/code-golf/docker/entrypoint.sh code-golf compile

ENTRYPOINT [ "/app/code-golf/docker/entrypoint.sh" ]
