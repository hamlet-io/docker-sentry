[#ftl]

[@addExtension
    id="sentry_appconfig"
    aliases=[
        "_sentry_appconfig"
    ]
    description=[
        "An extension which configures the required sentry environment variables"
    ]
    supportedTypes=[ "*" ]
/]

[#macro shared_extension_sentry_appconfig_deployment_setup occurrence ]

    [@Settings
        [
            "SENTRY_DSN"
        ]
    /]

    [@AltSettings
        {
            "SENTRY_ENVIRONMENT" : "ENVIRONMENT"
        }
    /]

    [#if (_context.DefaultEnvironment["BUILD_REFERENCE"]!"")?has_content ]
        [@AltSettings
            {
                "SENTRY_RELEASE" : "BUILD_REFERENCE"
            }
        /]
    [/#if]

[/#macro]
