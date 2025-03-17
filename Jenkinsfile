pipeline {
    agent any

    environment {
        AWS_REGION    = 'eu-west-2'
        S3_BUCKET     = "seunadio-tfstate"
        STATE_FILE_KEY = "sftp-infra/terraform.tfstate"
    }

    stages {
        stage('User Selection: Environment') {
            steps {
                script {
                    env.SELECTED_ENV = input(
                        id: 'environmentSelection',
                        message: 'Select the deployment environment:',
                        parameters: [
                            choice(name: 'Environment', choices: ['dev', 'prod'], description: 'Select the environment')
                        ]
                    )
                    env.TFVARS_FILE = "${env.SELECTED_ENV}.tfvars"
                    echo "User selected environment: ${env.SELECTED_ENV}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                script {
                    echo 'Checking out source code...'
                    checkout([$class: 'GitSCM',
                        branches: [[name: '*/master']],
                        extensions: [[$class: 'WipeWorkspace']],
                        userRemoteConfigs: [[
                            credentialsId: 'github-credentials',
                            url: 'https://github.com/jibolaolu/sftp_aml_proj.git'
                        ]]
                    ])
                }
            }
        }

        stage('Inject SSH Keys for SFTP Users') {
            steps {
                script {
                    def sftpUsers = ["sftp_user1", "sftp_user2", "sftp_user3", "sftp_admin"]  // List all SFTP users
                    def sshKeys = [:]

                    for (user in sftpUsers) {
                        withCredentials([string(credentialsId: "${user}", variable: "SSH_PUB_KEY")]) {
                            sshKeys[user] = env.SSH_PUB_KEY
                        }
                    }

                    // Convert SSH keys to JSON format and store in environment variable
                    env.SSH_PUBLIC_KEYS_JSON = groovy.json.JsonOutput.toJson(sshKeys)
                    echo "✅ Retrieved SSH Public Keys for Users"
                }
            }
        }

        stage('Terraform Init & State Check') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "Initializing Terraform..."
                        sh """
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                            terraform init
                        """

                        echo "Checking Terraform state..."
                        def stateExists = sh(
                            script: "aws s3 ls s3://${S3_BUCKET}/${STATE_FILE_KEY} | wc -l",
                            returnStdout: true
                        ).trim()

                        env.STATEFILE_EXISTS = (stateExists == "1") ? "true" : "false"

                        if (env.STATEFILE_EXISTS == "true") {
                            echo "Refreshing Terraform state..."
                            sh "terraform refresh -var-file=${env.TFVARS_FILE}"
                        }
                    }
                }
            }
        }

        stage('User Selection: Action (Plan, Plan and Apply, Destroy)') {
            steps {
                script {
                    env.SELECTED_ACTION = input(
                        id: 'actionSelection',
                        message: 'What action would you like to perform?',
                        parameters: [
                            choice(name: 'Action', choices: ['Plan', 'Plan and Apply', 'Destroy'], description: 'Select an action')
                        ]
                    )
                    echo "User selected action: ${env.SELECTED_ACTION}"
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { env.SELECTED_ACTION == 'Plan' || env.SELECTED_ACTION == 'Plan and Apply' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "Running Terraform Plan..."
                        sh "terraform plan -var-file=${env.TFVARS_FILE} -var 'ssh_public_keys=${env.SSH_PUBLIC_KEYS_JSON}' -out=tfplan"

                        if (env.SELECTED_ACTION == 'Plan and Apply') {
                            env.APPLY_AFTER_PLAN = input(
                                id: 'applyAfterPlan',
                                message: 'Terraform Plan completed. Do you want to apply the changes?',
                                parameters: [choice(name: 'Proceed', choices: ['Yes', 'No'], description: 'Select Yes to apply or No to cancel')]
                            )
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { env.SELECTED_ACTION == 'Plan and Apply' && env.APPLY_AFTER_PLAN == 'Yes' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "Applying Terraform..."
                        sh "terraform apply -auto-approve -var-file=${env.TFVARS_FILE} -var 'ssh_public_keys=${env.SSH_PUBLIC_KEYS_JSON}'"
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { env.SELECTED_ACTION == 'Destroy' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        if (env.STATEFILE_EXISTS == "true") {
                            echo "Destroying Terraform..."
                            sh """
                                terraform refresh -var-file=${env.TFVARS_FILE}
                                terraform destroy -auto-approve -var-file=${env.TFVARS_FILE} -var 'ssh_public_keys=${env.SSH_PUBLIC_KEYS_JSON}'
                            """
                        } else {
                            echo "⚠️ No Terraform statefile found. Nothing to destroy."
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Terraform execution completed successfully!'
        }
        failure {
            echo '❌ Terraform execution failed!'
        }
    }
}
