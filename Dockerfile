FROM sentry:9.0-onbuild

COPY scripts/init /init
RUN chmod ugo+x /init