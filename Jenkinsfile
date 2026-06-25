pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  triggers {
    githubPush()
  }

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'ap-south-1', description: 'AWS Region')
    string(name: 'EKS_CLUSTER', defaultValue: 'mern-eks', description: 'EKS cluster name')
    booleanParam(name: 'DEPLOY_TO_EKS', defaultValue: true, description: 'Deploy after pushing images')
    string(name: 'SNS_TOPIC_ARN', defaultValue: '', description: 'Optional deployment notification topic')
  }

  environment {
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
    AWS_REGION = "${params.AWS_REGION}"
    K8S_NAMESPACE = 'mern-app'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.IMAGE_TAG = sh(script: 'git rev-parse --short=8 HEAD', returnStdout: true).trim()
        }
      }
    }

    stage('Verify application') {
      parallel {
        stage('Frontend build') {
          steps {
            dir('frontend') {
              sh 'npm ci'
              sh 'CI=true npm test -- --watchAll=false'
              sh 'npm run build'
            }
          }
        }
        stage('Backend dependency checks') {
          steps {
            sh 'cd backend/helloService && npm ci --omit=dev'
            sh 'cd backend/profileService && npm ci --omit=dev'
          }
        }
      }
    }

    stage('Build images') {
      steps {
        sh 'docker build -t mern-frontend:${IMAGE_TAG} frontend'
        sh 'docker build -t mern-hello-service:${IMAGE_TAG} backend/helloService'
        sh 'docker build -t mern-profile-service:${IMAGE_TAG} backend/profileService'
      }
    }

    stage('Push images to ECR') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
          sh 'bash ./scripts/create-ecr-repositories.sh'
          script {
            env.AWS_ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
            env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com"
          }
          sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}'
          sh '''
            for image in frontend hello-service profile-service; do
              docker tag mern-${image}:${IMAGE_TAG} ${ECR_REGISTRY}/mern-${image}:${IMAGE_TAG}
              docker tag mern-${image}:${IMAGE_TAG} ${ECR_REGISTRY}/mern-${image}:latest
              docker push ${ECR_REGISTRY}/mern-${image}:${IMAGE_TAG}
              docker push ${ECR_REGISTRY}/mern-${image}:latest
            done
          '''
        }
      }
    }

    stage('Deploy to EKS') {
      when {
        expression { params.DEPLOY_TO_EKS }
      }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
          sh 'bash ./scripts/deploy.sh'
        }
      }
    }
  }

  post {
    success {
      script {
        if (params.SNS_TOPIC_ARN?.trim()) {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
            sh 'aws sns publish --topic-arn "$SNS_TOPIC_ARN" --subject "MERN deployment succeeded" --message "Build ${BUILD_NUMBER}, image ${IMAGE_TAG}, completed successfully."'
          }
        }
      }
    }
    failure {
      script {
        if (params.SNS_TOPIC_ARN?.trim()) {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
            sh 'aws sns publish --topic-arn "$SNS_TOPIC_ARN" --subject "MERN deployment failed" --message "Build ${BUILD_NUMBER} failed. Review ${BUILD_URL}"'
          }
        }
      }
    }
    always {
      cleanWs()
    }
  }
}
