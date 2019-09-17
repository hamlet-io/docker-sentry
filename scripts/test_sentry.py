import sentry_sdk
import os

sentry_sdk.init(
    dsn=os.environ.get('SENTRY_DSN'),
    environment=os.environ.get('SENTRY_ENVIRONMENT', default='unknown'),
)
sentry_sdk.capture_exception(
    Exception(
        os.environ.get('SENTRY_TEST_MESSAGE', default='This is an example of an error message.')
    )
)
