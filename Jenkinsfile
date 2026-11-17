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
                sh '''
                    set -eu
                    gradle_version=8.10.2
                    gradle_dir="$WORKSPACE/.gradle-dist/gradle-$gradle_version"
                    if [ ! -x "$gradle_dir/bin/gradle" ]; then
                        mkdir -p "$WORKSPACE/.gradle-dist"
                        cd "$WORKSPACE/.gradle-dist"
                        archive="gradle-$gradle_version-bin.zip"
                        curl -fsSL "https://services.gradle.org/distributions/$archive" -o "$archive"
                        echo "31c55713e40233a8303827ceb42ca48a47267a0ad4bab9177123121e71524c26  $archive" | sha256sum --check -
                        unzip -q "$archive"
                        rm "$archive"
                    fi
                    "$gradle_dir/bin/gradle" -p java-gradle clean check jacocoTestReport
                '''
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
