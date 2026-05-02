pipeline {
  agent any

  options {
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
    disableConcurrentBuilds()
    timeout(time: 60, unit: 'MINUTES')
    timestamps()
  }

  parameters {
    choice(
      name: 'TF_ACTION',
      choices: ['plan', 'apply', 'destroy'],
      description: 'Terraform action to run for the dev environment.'
    )
    string(
      name: 'AWS_REGION',
      defaultValue: 'us-east-1',
      description: 'AWS region used by Terraform and the AWS CLI.'
    )
    booleanParam(
      name: 'AUTO_APPROVE',
      defaultValue: false,
      description: 'Skip the manual approval gate for apply and destroy.'
    )
  }

  environment {
    TF_DIR             = 'environments/dev'
    TF_IN_AUTOMATION   = 'true'
    TF_INPUT           = '0'
    TERRAFORM_BIN      = '/opt/homebrew/bin/terraform'
    AWS_BIN            = '/usr/local/bin/aws'
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
    AWS_REGION         = "${params.AWS_REGION}"
    AWS_CREDS_ID       = 'aws-jenkins-creds'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          currentBuild.description = "${params.TF_ACTION} | ${env.TF_DIR} | ${params.AWS_REGION}"
        }
      }
    }

    stage('Preflight') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: env.AWS_CREDS_ID
        ]]) {
          sh '''
            set -euo pipefail

            test -x "${TERRAFORM_BIN}"
            test -x "${AWS_BIN}"
            "${TERRAFORM_BIN}" version
            python3 --version
            "${AWS_BIN}" --version
            "${AWS_BIN}" sts get-caller-identity
            test -f "${TF_DIR}/terraform.tfvars"

            if grep -q 'backend "local"' "${TF_DIR}/backend.tf"; then
              echo "WARNING: Local Terraform backend detected."
              echo "For reliable Jenkins runs, move state to a remote S3 backend before using this beyond quick tests."
            fi
          '''
        }
      }
    }

    stage('Package Lambda') {
      steps {
        sh '''
          set -euo pipefail
          chmod +x infra-scripts/package_lambda.sh
          ./infra-scripts/package_lambda.sh
        '''
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: env.AWS_CREDS_ID
        ]]) {
          sh '''
            set -euo pipefail
            "${TERRAFORM_BIN}" -chdir="${TF_DIR}" init
          '''
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: env.AWS_CREDS_ID
        ]]) {
          sh '''
            set -euo pipefail
            "${TERRAFORM_BIN}" fmt -check -recursive
            "${TERRAFORM_BIN}" -chdir="${TF_DIR}" validate
          '''
        }
      }
    }

    stage('Terraform Plan') {
      when {
        expression { params.TF_ACTION == 'plan' || params.TF_ACTION == 'apply' }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: env.AWS_CREDS_ID
        ]]) {
          sh '''
            set -euo pipefail
            "${TERRAFORM_BIN}" -chdir="${TF_DIR}" plan -out=tfplan
            "${TERRAFORM_BIN}" -chdir="${TF_DIR}" show -no-color tfplan > "${TF_DIR}/tfplan.txt"
          '''
        }
        archiveArtifacts artifacts: "${env.TF_DIR}/tfplan.txt", fingerprint: true
      }
    }

    stage('Terraform Destroy Plan') {
      when {
        expression { params.TF_ACTION == 'destroy' }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: env.AWS_CREDS_ID
        ]]) {
          sh '''
            set -euo pipefail
            "${TERRAFORM_BIN}" -chdir="${TF_DIR}" plan -destroy -out=tfdestroy
            "${TERRAFORM_BIN}" -chdir="${TF_DIR}" show -no-color tfdestroy > "${TF_DIR}/tfdestroy.txt"
          '''
        }
        archiveArtifacts artifacts: "${env.TF_DIR}/tfdestroy.txt", fingerprint: true
      }
    }

    stage('Approval') {
      when {
        allOf {
          expression { params.TF_ACTION == 'apply' || params.TF_ACTION == 'destroy' }
          expression { !params.AUTO_APPROVE }
        }
      }
      steps {
        input message: "Approve Terraform ${params.TF_ACTION} for ${env.TF_DIR} in ${params.AWS_REGION}?"
      }
    }

    stage('Terraform Apply') {
      when {
        expression { params.TF_ACTION == 'apply' }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: env.AWS_CREDS_ID
        ]]) {
          sh '''
            set -euo pipefail
            "${TERRAFORM_BIN}" -chdir="${TF_DIR}" apply -auto-approve tfplan
          '''
        }
      }
    }

    stage('Terraform Destroy') {
      when {
        expression { params.TF_ACTION == 'destroy' }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: env.AWS_CREDS_ID
        ]]) {
          sh '''
            set -euo pipefail
            "${TERRAFORM_BIN}" -chdir="${TF_DIR}" apply -auto-approve tfdestroy
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'dist/*.zip, environments/dev/tfplan.txt, environments/dev/tfdestroy.txt', allowEmptyArchive: true
    }
    success {
      echo "Pipeline completed successfully."
    }
    failure {
      echo "Pipeline failed. Check the Jenkins console log and archived Terraform plan output."
    }
  }
}
