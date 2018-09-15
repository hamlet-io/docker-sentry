FROM sentry:9.0-onbuild

COPY init.sh /usr/src/sentry/init.sh
RUN chmod ugo+x /usr/src/sentry/init.sh