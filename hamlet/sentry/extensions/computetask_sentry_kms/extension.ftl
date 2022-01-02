[#ftl]

[@addExtension
    id="computetask_sentry_kms"
    aliases=[
        "_computetask_sentry_kms"
    ]
    description=[
        "A computetask extension to decrypt and inject kms secrets into the env file"
    ]
    supportedTypes=[
        EC2_COMPONENT_TYPE
    ]
    scopes=[
        COMPUTETASK_EXTENSION_SCOPE
    ]
/]

[#macro shared_extension_computetask_sentry_kms_deployment_computetask occurrence ]

    [@computeTaskConfigSection
        computeTaskTypes=[ COMPUTE_TASK_GENERAL_TASK ]
        id="KMSEnvDecrypt"
        priority=9
        engine=AWS_EC2_CFN_INIT_COMPUTE_TASK_CONFIG_TYPE
        content={
            "files" : {
                "/opt/hamlet_cfninit/kms_decrypt.sh" : {
                    "content" : {
                        "Fn::Join" : [
                            "\n",
                             [
                                r'#!/bin/bash',
                                r'set -euo pipefail',
                                r'# Decrypt Base64 encoded string encrypted using AWS KMS CMK keys',
                                r'KMS_PREFIX="base64:"',
                                r'source /opt/hamlet_cfninit/set_env.sh',
                                r'for ENV_VAR in $( printenv ); do',
                                r'    KEY="$( echo "${ENV_VAR}" | cut -d"=" -f1)"',
                                r'    VALUE="$( echo "${ENV_VAR}" | cut -d"=" -f2-)"',

                                r'    if [[ $VALUE == "${KMS_PREFIX}"* ]]; then',
                                r'       CIPHER_BLOB_PATH="/tmp/ENV-${KEY}-cipher.blob"',
                                r'       echo ${VALUE#"${KMS_PREFIX}"} | base64 -d > "${CIPHER_BLOB_PATH}"',
                                {
                                    "Fn::Sub" : [
                                        r'       VALUE="$(aws --region "${Region}" kms decrypt --ciphertext-blob "fileb://${!CIPHER_BLOB_PATH}" --output text --query Plaintext | base64 -d || exit $?)"',
                                        {
                                            "Region" : { "Ref" : "AWS::Region" }
                                        }
                                    ]
                                },
                                r'       echo "export ${KEY}=' + r"'${VALUE}'" + r'" >> /opt/hamlet_cfninit/set_env.sh',
                                r'    fi',
                                r'done'
                            ]
                        ]
                    },
                    "mode" : "000755"
                }
            },
            "commands" : {
                "1_decrypt_secrets" : {
                    "command" : "/opt/hamlet_cfninit/kms_decrypt.sh",
                    "ignoreErrors" : false
                }
            }
        }
    /]

[/#macro]
