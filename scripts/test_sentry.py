import sentry_sdk
import os

from sentry_sdk import configure_scope

# Allows you to test most of the sentry formatting setups
SENTRY_DSN=os.environ.get('SENTRY_DSN')
SENTRY_ENVIRONMENT=os.environ.get('SENTRY_ENVIRONMENT', default=None)
SENTRY_TEST_LEVEL=os.environ.get('SENTRY_TEST_LEVEL', default='warning' )
SENTRY_TEST_MESSAGE=os.environ.get('SENTRY_TEST_MESSAGE', default='This is an example of an error message.')

sentry_sdk.init(
    dsn=SENTRY_DSN,
    environment=SENTRY_ENVIRONMENT,
)

with configure_scope() as scope:
    scope.level = SENTRY_TEST_LEVEL

sentry_sdk.capture_exception(
    Exception(SENTRY_TEST_MESSAGE)
)
