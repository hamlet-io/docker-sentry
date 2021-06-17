[#ftl]

[@addExtension
    id="computetask_sentry_onpremise"
    aliases=[
        "_computetask_sentry_onpremise"
    ]
    description=[
        "A computetask extension to install and configure sentry onpremise deployment"
    ]
    supportedTypes=[
        EC2_COMPONENT_TYPE
    ]
    scopes=[
        COMPUTETASK_EXTENSION_SCOPE
    ]
/]

[#macro shared_extension_computetask_sentry_onpremise_deployment_computetask occurrence ]

    [#local solution = occurrence.Configuration.Solution ]
    [#local operatingSystem = solution.ComputeInstance.OperatingSystem]

    [#if operatingSystem.Family != "linux" ]
        [@fatal
            message="Sentry instally only supported on linux"
        /]
    [/#if]

    [#local sentryEnvFile = "/home/sentry/docker-sentry/sentry/.env" /]
    [#local sentryConfFile = "/home/sentry/docker-sentry/sentry/config" /]

    [@computeTaskConfigSection
        computeTaskTypes=[ COMPUTE_TASK_GENERAL_TASK ]
        id="SentryClone"
        priority=7
        engine=AWS_EC2_CFN_INIT_WAIT_COMPUTE_TASK_CONFIG_TYPE
        content={
            "packages" : {
                "yum" : {
                    "git" : []
                }
            },
            "files": {
                "/opt/hamlet_cfninit/sentry_clone.sh" : {
                    "content" : {
                        "Fn::Join" : [
                            "\n",
                            [
                                r'#!/bin/bash',
                                r'sentry_ref="sentry-21-4-1"',
                                r'sentry_install_dir="/home/sentry/docker-sentry"',
                                r'if git -C "${sentry_install_dir}" rev-parse --is-inside-work-tree &>/dev/null; then',
                                r'    echo "Updating existing repo"',
                                r'    git -C "${sentry_install_dir}" checkout "${sentry_ref}"',
                                r'    git -C "${sentry_install_dir}" pull',
                                r'else',
                                r'    echo "Cloning repo"',
                                r'    [[ -d "${sentry_install_dir}" ]] && rm -rf "${sentry_install_dir}"',
                                r'    git clone https://github.com/hamlet-io/docker-sentry.git "${sentry_install_dir}"',
                                r'    git -C "${sentry_install_dir}" checkout "${sentry_ref}"',
                                r'fi',
                                r''
                            ]
                        ]
                    },
                    "mode" : "000755"
                }
            },
            "commands" : {
                "1_clone_docker_sentry_repo" : {
                    "command" : "/opt/hamlet_cfninit/sentry_clone.sh",
                    "ignoreErrors" : false
                }
            }
        }
    /]


    [#local githubIntegration = ((_context.DefaultEnvironment["GITHUB_APP_ID"])!"")?has_content]
    [#local slackIntegration = ((_context.DefaultEnvironment["SLACK_CLIENT_ID"])!"")?has_content]
    [#local githubAuthIntegration = ((_context.DefaultEnvironment["GITHUB_AUTH_CLIENT_ID"])!"")?has_content]

    [@computeTaskConfigSection
        computeTaskTypes=[ COMPUTE_TASK_GENERAL_TASK ]
        id="SentryConfig"
        priority=8
        engine=AWS_EC2_CFN_INIT_WAIT_COMPUTE_TASK_CONFIG_TYPE
        content={
            "files" : {
                "/opt/hamlet_cfninit/sentry_env.sh" : {
                    "content" : {
                        "Fn::Join" : [
                            "\n",
                             [
                                r'#!/bin/bash',
                                r'',
                                r'source /opt/hamlet_cfninit/set_env.sh',
                                r'function main() {',
                                r'  variableNames=( \',
                                r'    DATABASE_URL SENTRY_USE_SSL\',
                                r'    SENTRY_SINGLE_ORGANIZATION \',
                                r'    SENTRY_URL_PREFIX \',
                                r'    OIDC_CLIENT_ID OIDC_CLIENT_SECRET OIDC_SCOPE OIDC_DOMAIN)',
                                '  [[ -f ${sentryEnvFile} ]] && rm ${sentryEnvFile}',
                                '  touch ${sentryEnvFile}',
                                r' for i in "${variableNames[@]}"',
                                r'  do',
                                r'   echo "${i}=\"${!i}\"" >>' + ' ${sentryEnvFile}',
                                r'  done',
                                r'}',
                                r'',
                                r'main',
                                r''
                            ]
                        ]
                    },
                    "mode" : "000755"
                },
                "/opt/hamlet_cfninit/generate_sentry_config.sh" : {
                    "content" : {
                        "Fn::Join" : [
                            "\n",
                             [
                                r'#!/bin/bash',
                                r'set -euo pipefail',
                                r'source /opt/hamlet_cfninit/set_env.sh',
                                'envsubst < "${sentryConfFile}_env.yml" > "${sentryConfFile}.yml"'
                            ]
                        ]
                    },
                    "mode" : "000755"
                },
                "${sentryConfFile}_env.yml" : {
                    "content" : {
                        "Fn::Join" : [
                            "\n",
                            [
                                r'system.url-prefix: "${LB_URL}"',
                                r'system.secret-key: "${SENTRY_SECRET_KEY}"',
                                r'system.internal-url-prefix: "http://web:9000"',
                                r'symbolicator.enabled: true',
                                r'symbolicator.options:',
                                r'  url: "http://symbolicator:3021"',
                                r'transaction-events.force-disable-internal-project: true'
                            ] +
                            githubIntegration?then(
                                [
                                    r'github-app.id: ${GITHUB_APP_ID}',
                                    r'github-app.name: "${GITHUB_APP_NAME}"',
                                    r'github-app.webhook-secret: "${GITHUB_APP_WEBHOOK_SECRET}"',
                                    r'github-app.client-id: "${GITHUB_APP_CLIENT_ID}"',
                                    r'github-app.client-secret: "${GITHUB_APP_CLIENT_SECRET}"',
                                    r'github-app.private-key: |',
                                    r'${GITHUB_APP_PRIVATE_KEY}'
                                ],
                                []
                            ) +
                            githubAuthIntegration?then(
                                [
                                    r'github-login.extended-permissions: [ "repo" ]',
                                    r'github-login.client-id: "${GITHUB_AUTH_CLIENT_ID}"',
                                    r'github-login.client-secret: "${GITHUB_AUTH_CLIENT_SECRET}"'
                                ],
                                []
                            ) +
                            slackIntegration?then(
                                [
                                    r'slack.client-id: "${SLACK_CLIENT_ID}"',
                                    r'slack.client-secret: "${SLACK_CLIENT_SECRET}"',
                                    r'slack.signing-secret: "${SLACK_SIGNING_SECRET}"'
                                ],
                                []
                            ) +
                            [
                                r'filestore.backend: "${SENTRY_FILESTORE_BACKEND}"',
                                r'mail.backend: "${SENTRY_EMAIL_BACKEND}"',
                                r'mail.host: "${SENTRY_EMAIL_FQDN}"',
                                r'mail.port: ${SENTRY_EMAIL_PORT}',
                                r'mail.username: "${SENTRY_EMAIL_USER}"',
                                r'mail.password: "${SENTRY_EMAIL_PASSWORD}"',
                                r'mail.use-tls: ${SENTRY_EMAIL_USE_TLS}',
                                r'mail.from: "${SENTRY_SERVER_EMAIL}"',
                                r'mail.list-namespace: "${SENTRY_EMAIL_LIST_NAMESPACE}"',
                                r'filestore.backend: "${SENTRY_FILESTORE_BACKEND}"',
                                r'filestore.options:',
                                r'  bucket_name: "${SENTRY_FILESTORE_BUCKET}"',
                                r'  default_acl: "private"',
                                r'  region_name: "${AWS_REGION}"'
                                r''
                            ]
                        ]
                    }
                },
                "/etc/systemd/system/sentry.service" : {
                    "content" : {
                        "Fn::Join" : [
                            "\n",
                            [
                                r'[Unit]',
                                r'Description=Start Sentry docker-compose stack',
                                r'After=docker.service network-online.target',
                                r'Requires=docker.service network-online.target',
                                r'',
                                r'[Service]',
                                r'WorkingDirectory=/home/sentry/docker-sentry',
                                r'Type=oneshot',
                                r'RemainAfterExit=yes',
                                r'',
                                r'ExecStart=/usr/local/bin/docker-compose up -d',
                                r'ExecStop=/usr/local/bin/docker-compose down',
                                r'ExecReload=/usr/local/bin/docker-compose up -d',
                                r'ExecRestart=/usr/local/bin/docker-compose up -d',
                                r'',
                                r'[Install]',
                                r'WantedBy=multi-user.target'
                            ]
                        ]
                    }
                }
            },
            "commands" : {
                "1_generate_sentry_env" : {
                    "command" : "/opt/hamlet_cfninit/sentry_env.sh",
                    "ignoreErrors" : false
                },
                "2_generate_sentry_config_yml" : {
                    "command" : "/opt/hamlet_cfninit/generate_sentry_config.sh",
                    "ignoreErrors" : true
                }
            }
        }
    /]

    [@computeTaskConfigSection
        computeTaskTypes=[ COMPUTE_TASK_GENERAL_TASK ]
        id="SentryInstall"
        priority=9
        engine=AWS_EC2_CFN_INIT_WAIT_COMPUTE_TASK_CONFIG_TYPE
        content={
            "commands" : {
                "1_restart_docker" : {
                    "command" : "systemctl restart docker.service",
                    "ignoreErrors" : false
                },
                "2_start_sentry" : {
                    "command" : "systemctl start sentry.service",
                    "ignoreErrors" : true
                }
            }
        }
    /]

[/#macro]
