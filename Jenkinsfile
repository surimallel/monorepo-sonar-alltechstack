pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Java Maven - greeting formatter') {
            steps {
                sh 'mvn -B -f java-maven/pom.xml clean verify'
            }
            post {
                always {
                    junit testResults: 'java-maven/target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Java Gradle - tax calculator') {
            steps {
                sh 'gradle -p java-gradle clean check jacocoTestReport'
            }
            post {
                always {
                    junit testResults: 'java-gradle/build/test-results/test/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Node.js - URL slug generator') {
            steps {
                dir('node') {
                    sh 'npm install'
                    sh 'npm test'
                }
            }
        }

        stage('Python - palindrome checker') {
            steps {
                sh 'python3 -m venv python/.venv'
                sh 'python/.venv/bin/python -m pip install -r python/requirements.txt'
                sh 'COVERAGE_FILE=python/.coverage PYTHONPATH=python python/.venv/bin/python -m coverage run --source=python/src -m unittest discover -s python/tests'
                sh 'COVERAGE_FILE=python/.coverage python/.venv/bin/python -m coverage xml -o python/coverage.xml'
                sh 'COVERAGE_FILE=python/.coverage python/.venv/bin/python -m coverage report --fail-under=80'
            }
        }

        stage('SonarQube analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "\"${scannerHome}/bin/sonar-scanner\""
                    }
                }
            }
        }

        stage('Quality gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
