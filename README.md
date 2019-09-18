# Sentry On-Premise

Official bootstrap for running your own [Sentry](https://sentry.io/) with [Docker](https://www.docker.com/).

## Requirements

 * Docker 1.10.0+
 * Compose 1.6.0+ _(optional)_

## Up and Running

Assuming you've just cloned this repository, the following steps
will get you up and running in no time!

There may need to be modifications to the included `docker-compose.yml` file to accommodate your needs or your environment. These instructions are a guideline for what you should generally do.

1. `mkdir -p data/{sentry,postgres}` - Make our local database and sentry config directories.
    This directory is bind-mounted with postgres so you don't lose state!
2. `docker-compose build` - Build and tag the Docker services
3. `docker-compose run --rm web config generate-secret-key` - Generate a secret key.
    Add it to `docker-compose.yml` in `base` as `SENTRY_SECRET_KEY`.
4. `docker-compose run --rm web upgrade` - Build the database.
    Use the interactive prompts to create a user account.
5. `docker-compose up -d` - Lift all services (detached/background mode).
6. Access your instance at `localhost:9000`!

Note that as long as you have your database bind-mounted, you should
be fine stopping and removing the containers without worry.

## Securing Sentry with SSL/TLS

If you'd like to protect your Sentry install with SSL/TLS, there are
fantastic SSL/TLS proxies like [HAProxy](http://www.haproxy.org/)
and [Nginx](http://nginx.org/).

## Updating Sentry

Updating Sentry using Compose is relatively simple. Just use the following steps to update. Make sure that you have the latest version set in your Dockerfile. Or use the latest version of this repository.

Use the following steps after updating this repository or your Dockerfile:
```sh
docker-compose build # Build the services again after updating
docker-compose run --rm web upgrade # Run new migrations
docker-compose up -d # Recreate the services
```

## Configuring the Slack Plugin

With the release of sentry 9.1.2 the slack plugin has moved from a per project integration to an installation wide plugin which uses a Slack App to integrate with one or many slack channels.

Configuring the Slack App itself is covered in this [forum post](https://forum.sentry.io/t/how-to-configure-slack-in-your-on-prem-sentry/3463)

To specify the Slack OAuth Details specify the following environment variables

* SLACK_CLIENT_ID - The Slack App Client Id
* SLACK_CLIENT_SECRET = The Slack App Client Secret
* SLACK_VERIFICATION_TOKEN - The Slack App Verification token

A couple of extra notes:

* when you create the Slack app don’t invite it to the workspace, let it do add from within the Sentry plugin. Otherwise it gets confussed
* The sentry slack environment variables (oauth config) need to be added before adding the Event Subscription URL in Slack, the validation process will fail without

## Resources

* [Documentation](https://docs.sentry.io/server/installation/docker/)
* [Bug Tracker](https://github.com/getsentry/onpremise)
* [Forums](https://forum.sentry.io/c/on-premise)
* [IRC](irc://chat.freenode.net/sentry) (chat.freenode.net, #sentry)
