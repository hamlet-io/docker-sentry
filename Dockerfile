FROM sentry:9.1-onbuild

COPY scripts/ /

RUN chmod ugo+x /init