[#ftl]

[@addExtension
    id="sentry_onpremise_auth"
    aliases=[
        "_sentry_onpremise_auth"
    ]
    description=[
        "Callback url setup for userpool auth integration"
    ]
    supportedTypes=[
        EXTERNALSERVICE_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_sentry_onpremise_auth_deployment_setup occurrence ]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]

    [#assign callBackUrls = []]

    [#assign redirectPathSignIn = "/auth/sso/" ]

    [#if _context.Links["lb"]?has_content ]
        [#assign linkUrl = _context.Links["lb"].State.Attributes["URL"] ]
        [#assign callBackUrls += [ "${linkUrl}${redirectPathSignIn}" ]]
    [#else]
        [#assign callBackUrls += [ "https://placeholder_${occurrence.Core.Id}" ] ]
    [/#if]

    [@Settings
        {
            "AUTH_CALLBACK_URL" : callBackUrls?join(","),
            "AUTH_SIGNOUT_URL" : ""
        }
    /]
[/#macro]
