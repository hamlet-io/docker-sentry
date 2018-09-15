FROM sentry:9.0-onbuild

COPY scripts/ /

RUN chmod ugo+x /init