# Sentry Hamlet Plugin

The sentry Hamlet plugin provides a collection of modules and extensions for working with [sentry](https://sentry.io)

## Modules

### onpremise

Provides an Ec2 based deployment of [sentry on premise](https://github.com/getsentry/onpremise)

The solution includes the following:

- Application load balancer for public access
- ec2 instance which hosts the onpremise docker-compose stack and registers with the load balancer
- datavolume which is mounted to the docker volume dir for persistence and backup
- rds instance for postgres data storage
- S3 bucket for filestore backend
- IAM user which is used for SMTP email support with SES

#### Setup Process

When updating or deploying the onpremise module you will need to run the install.sh script from the ec2 instance created by the module.
The simplest way to do this is through an SSM Session Manager Session

1. Log into the AWS Console and locate the Sentry instance that has been deployed in the Ec2 Console
2. Tick the instance and click the connect button in the top right of the console
3. Select the Session Manager connection option and click Connect
4. This will take you into a console on the instance
5. Run the following to run the install script

    ```bash
    # become the root user who owns the docker-compose service
    sudo su

    cd /home/sentry/docker-sentry
    ./install.sh
    ```

6. The install script will create the required docker volumes and perform administration tasks like database migrations

#### Local User

If you are still in the process of configuring authentication you can create a local admin user within the sentry install

1. Based on the steps in [link](####Setup Process) open an SSM Session
2. Run the following on the instance to open a session on the sentry web container and create a user

    ```bash
    sudo su

    cd /home/sentry/docker-sentry
    docker-compose exec web /bin/sh

    # once you are in the container create your new user
    sentry createuser
    ```

3. Follow the prompts to create your user and set the password. For the first user select that the user will be a super user to ensure you have configuration access

### Integrations

There are a number of integrations available for sentry that can be configured as part of the module

#### Cognito Userpool authentication

This allows you to use a cognito user pool to authenticate with sentry. You can then federate with other auth providers if you want to

You will need to create a new userpool with a client created for for sentry to use:

```json
{
    "Clients" : {
        "sentry" : {
            "EncryptionScheme" : "base64",
            "ClientGenerateSecret" : true,
            "OAuth" : {
                "Scopes" : [
                    "openid",
                    "email",
                    "profile",
                    "phone"
                ],
                "Flows" : [ "code" ]
            },
            "AuthProviders" : [ "GitHub" ],
            "Links" : {
                "sentry" : {
                    "Tier" : "app",
                    "Component" : "sentryauth",
                    "Instance" : "",
                    "Version" : ""
                }
            }
        }
    }
}
```

The link to sentryauth is part of the module and will be available on the privateTier
This will only provide authenticate and claims will not be validated by Sentry

#### Sentry

You can send alerts to sentry based on events created by Sentry

- To do this you will need to create a [Slack App](https://api.slack.com/)
- Enable the sentryIntegration property and provide the slackClientId, slackClientSecret, slackSigningSecret in the sentry module configuration

#### Github

You can integrate with Github to create issues from sentry and to map code commits through to issue tracking

- To do this you will need to create a [GitHubApp](https://docs.github.com/en/developers/apps/getting-started-with-apps/about-apps)
- Create a Private Key, Client Secret and webhook secret in the app once you have it setup
- Enable the githubIntegration and provide the parameters listed in the module under the github* prefix

#### Github Auth

You can use github oauth to authenticate users to sentry instead of the userpool

- To do this you will need to create a [Github OAuth App](https://docs.github.com/en/developers/apps/building-oauth-apps)
- Enable the githbAuthIntegration and provide parameters listed in the module under the githubAuth prefix

**Note** You can only authenticate members based on membership of a single organisation

## Extensions

- sentry_appconfig - provides a standard set of settings for application components to use for sentry configuration
