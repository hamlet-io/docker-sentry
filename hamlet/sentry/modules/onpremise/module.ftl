[#ftl]

[@addModule
    name="onpremise"
    description="Deploys the sentry onpremise docker deployment to an instance"
    provider=SENTRY_PROVIDER
    properties=[
        {
            "Names" : "loadBalancerTier",
            "Description" : "The Tier to place the load balancer into",
            "Types" : STRING_TYPE,
            "Default" : "elb"
        },
        {
            "Names" : "privateTier",
            "Description" : "The tier to place the private resources into",
            "Types" : STRING_TYPE,
            "Default" : "app"
        },
        {
            "Names" : "databaseTier",
            "Description" : "The tier to palce the database into",
            "Types" : STRING_TYPE,
            "Default" : "db"
        },
        {
            "Names" : "idPrefix",
            "Description" : "A prefix that is applied to all component Ids",
            "Types" : STRING_TYPE,
            "Default" : "sentry"
        },
        {
            "Names" : "instance",
            "Description" : "The instance Id to use for this instance of the module",
            "Types" : STRING_TYPE,
            "Default" : "default"
        },
        {
            "Names" : "publicIPAddressGroups",
            "Description" : "An array of IPAddressGroups that are allowed to access the load balancer",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : [ "_global" ]
        },
        {
            "Names" : "emailAddress",
            "Description" : "The Email address that will be used to send emails from sentry",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "emailListNamespace",
            "Description" : "The email domain namespace for mailing lists ",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "secretKey",
            "Description" : "A long key to use for the session management - Encryption recommended",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "singleOrganisation",
            "Description" : "Configure sentry as a single organisation instance",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "slackIntegration",
            "Description" : "Enable Slack alert integration",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "slackClientId",
            "Description" : "The client Id of your slack App",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "slackClientSecret",
            "Description" : "The client secret of your slack App - Encryption recommended",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "slackSigningSecret",
            "Description" : "The signing secret of your slack App - Encryption recommended",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubIntegration",
            "Description" : "Enable the Github repo integration",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "githubAppId",
            "Description" : "The app Id of your Github App",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubAppName",
            "Description" : "The name of your Github App",
            "Types": STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubWebHookSecret",
            "Description" : "The webhook secret for your Github App - Encryption recommended",
            "Types": STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubPrivateKey",
            "Description" : "The private key of your github app with single space indents for each line - Encryption recommended",
            "Types": STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubClientId",
            "Description" : "The oauth clientId of your github App",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubClientSecret",
            "Description" : "The oauth client secret of your github App",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubAuth",
            "Description" : "Use Github for authentication to sentry",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "githubAuthClientId",
            "Description" : "A github oauth app client id",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubAuthClientSecret",
            "Description" : "A github oauth app client secret - Encryption recommended",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "userpoolIntegratedAuth",
            "Description" : "Enable cognito integrated authentication",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "userPoolClientLink",
            "Description" : "A link to a userpool client that will be used for integrated auth",
            "Ref" : LINK_ATTRIBUTESET_TYPE
        }
    ]
/]

[#macro sentry_module_onpremise
        loadBalancerTier
        privateTier
        databaseTier
        idPrefix
        instance
        emailAddress
        emailListNamespace
        secretKey
        singleOrganisation
        githubIntegration
        githubAppId
        githubAppName
        githubClientId
        githubClientSecret
        githubWebHookSecret
        githubPrivateKey
        slackIntegration
        slackClientId
        slackClientSecret
        slackSigningSecret
        githubAuth
        githubAuthClientId
        githubAuthClientSecret
        publicIPAddressGroups
        userpoolIntegratedAuth
        userPoolClientLink
        ]

    [#local product = getActiveLayer(PRODUCT_LAYER_TYPE) ]
    [#local environment = getActiveLayer(ENVIRONMENT_LAYER_TYPE)]
    [#local segment = getActiveLayer(SEGMENT_LAYER_TYPE)]

    [#local rawInstance = instance ]
    [#local instance = (instance == "default")?then("", instance)]

    [#local namespace = formatName(product["Name"], environment["Name"], segment["Name"])]

    [#local lbId = formatName(idPrefix, "lb")]
    [#local s3Id = formatName(idPrefix, "s3")]
    [#local ec2Id = formatName(idPrefix, "ec2")]

    [#local ec2SettingsNamespace = formatName( namespace, privateTier, ec2Id, (instance == "default")?then("", instance)) ]

    [#local dataVolumeId = formatName(idPrefix, "datavolume")]
    [#local smtpUserId = formatName( "${idPrefix}smtp", "user")]
    [#local databaseId = formatName(idPrefix, "db")]

    [#local authId = "${idPrefix}auth" ]

    [#if githubIntegration ]
        [@loadModule
            settingSets=[
                {
                    "Type" : "Settings",
                    "Scope" : "Products",
                    "Namespace" : ec2SettingsNamespace,
                    "Settings" : {
                        "GitHub": {
                            "app": {
                                "id": githubAppId,
                                "name": githubAppName,
                                "webhook_secret": githubWebHookSecret,
                                "private_key": githubPrivateKey,
                                "client_id": githubClientId,
                                "client_secret" : githubClientSecret
                            }
                        }
                    }
                }
            ]
        /]
    [/#if]

    [#if slackIntegration ]
        [@loadModule
            settingSets=[
                {
                    "Type" : "Settings",
                    "Scope" : "Products",
                    "Namespace" : ec2SettingsNamespace,
                    "Settings" : {
                        "Slack" : {
                            "client_id" : slackClientId,
                            "client_secret" : slackClientSecret,
                            "signing_secret" : slackSigningSecret
                        }
                    }
                }
            ]
        /]
    [/#if]

    [#if githubAuth ]
        [@loadModule
            settingSets=[
                {
                    "Type" : "Settings",
                    "Scope" : "Products",
                    "Namespace" : ec2SettingsNamespace,
                    "Settings" : {
                        "GitHub" : {
                            "auth" : {
                                "client_id" : githubAuthClientId,
                                "client_secret" : githubAuthClientSecret
                            }
                        }
                    }
                }
            ]
        /]
    [/#if]

    [@loadModule
        settingSets=[
            {
                "Type" : "Settings",
                "Scope" : "Products",
                "Namespace" : ec2SettingsNamespace,
                "Settings" : {
                    "SENTRY_SERVER_EMAIL" : emailAddress,
                    "SENTRY_EMAIL_LIST_NAMESPACE" : emailListNamespace,
                    "SENTRY_SECRET_KEY" : secretKey,
                    "SENTRY_SINGLE_ORGANIZATION" : singleOrganisation
                }
            }
        ]
    /]

    [@loadModule
        blueprint={
            "Tiers" : {
                loadBalancerTier : {
                    "Components" : {
                        lbId : {
                            "lb" : {
                                "Instances" : {
                                    rawInstance: {
                                        "deployment:Unit" : lbId
                                    }
                                },
                                "Engine" : "application",
                                "IPAddressGroups" : publicIPAddressGroups,
                                "PortMappings" : {
                                    "https" : {
                                        "HostFilter" : true,
                                        "Priority" : 100,
                                        "Certificate" : {},
                                        "Forward" : {
                                            "TargetType" : "instance"
                                        },
                                        "Mapping" : "sentryhttps"
                                    },
                                    "httpredirect" : {
                                        "Redirect" : {}
                                    }
                                }
                            }
                        }
                    }
                },
                privateTier : {
                    "Components": {
                        s3Id : {
                            "s3" : {
                                "Instances" : {
                                    rawInstance : {
                                        "deployment:Unit" : s3Id
                                    }
                                }
                            }
                        },
                        authId : {
                            "externalservice" : {
                                "Instances" : {
                                    rawInstance : {}
                                },
                                "Profiles" : {
                                    "Placement" : "external"
                                },
                                "Extensions" : [ "_sentry_onpremise_auth" ],
                                "Links" : {
                                    "lb" : {
                                        "Tier" : loadBalancerTier,
                                        "Component" : lbId,
                                        "Instance" : instance,
                                        "PortMapping" : "https"
                                    }
                                }
                            }
                        },
                        ec2Id : {
                            "MultiAZ" : false,
                            "ec2": {
                                "deployment:Priority" : 200,
                                "Instances": {
                                    rawInstance: {
                                        "deployment:Unit" : ec2Id
                                    }
                                },
                                "Extensions" : [
                                    "noenv",
                                    "_sentry_onpremise_instance"
                                ],
                                "Profiles" : {
                                    "Deployment" : [ "_awslinux2"],
                                    "Processor" : "sentry"
                                },
                                "Links" : {
                                    "SENTRY_DB" : {
                                        "Tier" : databaseTier,
                                        "Component" : databaseId,
                                        "Instance" : instance,
                                        "ActiveRequired" : true
                                    },
                                    "datastore" : {
                                        "Tier" : privateTier,
                                        "Component" : dataVolumeId,
                                        "Instance" : instance,
                                        "Version" : "datastore",
                                        "ActiveRequired" : true
                                    },
                                    "volumestore" : {
                                        "Tier" : privateTier,
                                        "Component" : dataVolumeId,
                                        "Instance" : instance,
                                        "Version" : "volumestore",
                                        "ActiveRequired" : true
                                    },
                                    "SMTP" : {
                                        "Tier" : privateTier,
                                        "Component" : smtpUserId,
                                        "Instance" : instance,
                                        "ActiveRequired" : true
                                    },
                                    "LB" : {
                                        "Tier": loadBalancerTier,
                                        "Component"  : lbId,
                                        "PortMapping" : "https",
                                        "Instance" : instance,
                                        "ActiveRequired" : true
                                    },
                                    "FILESTORE" : {
                                        "Tier" : privateTier,
                                        "Component" : s3Id,
                                        "Instance" : instance,
                                        "Role" : "all",
                                        "ActiveRequired" : true
                                    }
                                } +
                                attributeIfTrue(
                                    "USERPOOL"
                                    userpoolIntegratedAuth,
                                    userPoolClientLink + { "ActiveRequired" : true }
                                ),
                                "Permissions" : {
                                    "Decrypt" : true
                                },
                                "ComputeInstance" : {
                                    "ComputeTasks": {
                                        "Extensions" :[
                                            "_computetask_awslinux_cfninit_wait",
                                            "_computetask_linux_hamletenv",
                                            "_computetask_linux_volumemount",
                                            "_computetask_awslinux_ospatching",
                                            "_computetask_linux_filedir",
                                            "_computetask_linux_sshkeys",
                                            "_computetask_awscli",
                                            "_computetask_awslinux_cwlog",
                                            "_computetask_awslinux_efsmount",
                                            "_computetask_linux_userbootstrap",
                                            "_computetask_awslinux_vpc_lb",

                                            [#-- sentry specific compute tasks --]
                                            "_computetask_linux_docker",
                                            "_computetask_linux_docker_compose",
                                            "_computetask_sentry_kms",
                                            "_computetask_sentry_onpremise"
                                        ]
                                    }
                                }
                            }
                        },
                        dataVolumeId : {
                            "MultiAZ" : false,
                            "datavolume" : {
                                "Instances" : {
                                    rawInstance  : {
                                        "deployment:Unit" : dataVolumeId,
                                        "Versions" : {
                                            "datastore" : {
                                                "Size" : 20
                                            },
                                            "volumestore" : {
                                                "Size" : 50
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        smtpUserId : {
                            "user" : {
                                "Instances" : {
                                    rawInstance : {
                                        "deployment:Unit" : smtpUserId
                                    }
                                },
                                "Extensions" : [ "_sentry_onpremise_smtp" ],
                                "GenerateCredentials" : {
                                    "Formats" : ["system"],
                                    "EncryptionScheme" : "base64"
                                }
                            }
                        }
                    }
                },
                databaseTier : {
                    "Components" : {
                        databaseId : {
                            "db" : {
                                "Instances" : {
                                    rawInstance : {
                                        "deployment:Unit" : databaseId
                                    }
                                },
                                "Engine" : "postgres",
                                "EngineVersion" : "9.6",
                                "GenerateCredentials" : {
                                    "Enabled" : true,
                                    "MasterUserName" : "postgres",
                                    "EncryptionScheme" : "base64"
                                },
                                "Size" : 20
                            }
                        }
                    }
                }
            },
            "Processors" : {
                "sentry" : {
                    "EC2": {
                        "Processor": "m5a.large"
                    }
                }
            },
            "Ports" :  {
                "sentry" : {
                    "Port": 9000,
                    "Protocol": "HTTP",
                    "IPProtocol": "tcp",
                    "HealthCheck" : {
                        "Path" : "/_health/",
                        "Interval" : "30",
                        "Timeout" : "29",
                        "HealthyThreshold" : "2",
                        "UnhealthyThreshold" : "10"
                    }
                }
            },
            "PortMappings" : {
                "sentryhttps": {
                    "Source": "https",
                    "Destination": "sentry"
                }
            }
        }
    /]
[/#macro]
