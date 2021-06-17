[#ftl]

[@addExtension
    id="sentry_onpremise_smtp"
    aliases=[
        "_sentry_onpremise_smtp"
    ]
    description=[
        "An extension to setup an ec2 user for SMTP for sentry onpremise"
    ]
    supportedTypes=[
        USER_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_sentry_onpremise_smtp_deployment_setup occurrence ]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=AWS_SIMPLE_EMAIL_SERVICE
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]
    [@Policy getSESSendStatement() /]

[/#macro]
