[#ftl]

[@addExtension
    id="sentry_onpremise_instance"
    aliases=[
        "_sentry_onpremise_instance"
    ]
    description=[
        "An extension to setup an ec2 instance for sentry onpremise"
    ]
    supportedTypes=[
        EC2_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_sentry_onpremise_instance_deployment_setup occurrence ]

    [@DefaultEnvironmentVariables enabled=true /]

    [@DataVolumeMount
        volumeLinkId="datastore"
        deviceId="/dev/xvds"
        mountPath="/home/sentry"
    /]

    [@DataVolumeMount
        volumeLinkId="volumestore"
        deviceId="/dev/xvdv"
        mountPath="/var/lib/docker/volumes"
    /]

    [@Settings
        {
            "SENTRY_EMAIL_BACKEND" : "smtp",
            "SENTRY_EMAIL_FQDN" : "email-smtp.${productObject.SES.Region}.amazonaws.com",
            "SENTRY_EMAIL_PORT" : "2587",
            "SENTRY_EMAIL_USE_TLS" : true,
            "SENTRY_FILESTORE_BACKEND" : "s3",
            "SENTRY_USE_SSL" : true,
            "AWS_REGION" : regionId
        }
    /]


    [@Settings
        {
            "GITHUB_APP_ID" : (_context.DefaultEnvironment["GITHUB_APP_ID"])!"",
            "GITHUB_APP_NAME" : (_context.DefaultEnvironment["GITHUB_APP_NAME"])!"",
            "GITHUB_APP_WEBHOOK_SECRET" : (_context.DefaultEnvironment["GITHUB_APP_WEBHOOK_SECRET"])!"",
            "GITHUB_APP_CLIENT_ID" : (_context.DefaultEnvironment["GITHUB_APP_CLIENT_ID"])!"",
            "GITHUB_APP_CLIENT_SECRET" : (_context.DefaultEnvironment["GITHUB_APP_CLIENT_SECRET"])!"",
            "GITHUB_APP_PRIVATE_KEY" : (_context.DefaultEnvironment["GITHUB_APP_PRIVATE_KEY"])!""
        }
    /]

    [@Settings
        {
            "SLACK_CLIENT_ID" : (_context.DefaultEnvironment["SLACK_CLIENT_ID"])!"",
            "SLACK_CLIENT_SECRET" : (_context.DefaultEnvironment["SLACK_CLIENT_SECRET"])!"",
            "SLACK_SIGNING_SECRET" : (_context.DefaultEnvironment["SLACK_SIGNING_SECRET"])!""
        }
    /]

    [@Settings
        {
            "GITHUB_AUTH_CLIENT_ID" : (_context.DefaultEnvironment["GITHUB_AUTH_CLIENT_ID"])!"",
            "GITHUB_AUTH_CLIENT_SECRET" : (_context.DefaultEnvironment["GITHUB_AUTH_CLIENT_SECRET"])!""
        }
    /]


    [#if  ((_context.DefaultEnvironment["USERPOOL_CLIENT"])!"")?has_content ]
        [@AltSettings
            {
                "OIDC_CLIENT_ID" : "USERPOOL_CLIENT",
                "OIDC_CLIENT_SECRET" : "USERPOOL_SECRET",
                "OIDC_DOMAIN" : "USERPOOL_OIDC_ISSUER"
            }
        /]
    [/#if]

    [@Settings
        [
            "SENTRY_SINGLE_ORGANIZATION",
            "LB_URL",
            "SENTRY_SECRET_KEY",
            "SENTRY_SERVER_EMAIL",
            "SENTRY_EMAIL_LIST_NAMESPACE"
        ]
    /]

    [@AltSettings
        {
            "SENTRY_URL_PREFIX" : "LB_URL",
            "SENTRY_EMAIL_USER" : "SMTP_ACCESS_KEY",
            "SENTRY_EMAIL_PASSWORD" : "SMTP_SES_SMTP_PASSWORD",
            "SENTRY_FILESTORE_BUCKET" : "FILESTORE_NAME",
            "DATABASE_URL" : "SENTRY_DB_URL"
        }
    /]

[/#macro]
