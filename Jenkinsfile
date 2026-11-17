pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Set up Java 25') {
            steps {
                sh '''
                    set -eu
                    jdk_home="$WORKSPACE/.jdk/jdk-25.0.5+8"
                    archive="$WORKSPACE/.jdk/OpenJDK25U-jdk_x64_linux_hotspot_25.0.5_8.tar.gz"
                    if [ ! -x "$jdk_home/bin/java" ]; then
                        mkdir -p "$WORKSPACE/.jdk"
                        curl -fsSL "https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.5%2B8/OpenJDK25U-jdk_x64_linux_hotspot_25.0.5_8.tar.gz" -o "$archive"
                        echo "68982529869257d0ee6b824ec5aa270ff8b118bb438670da0b97ebdab178d7fb  $archive" | sha256sum --check -
                        tar -xzf "$archive" -C "$WORKSPACE/.jdk"
                        rm "$archive"
                    fi
                    "$jdk_home/bin/java" -version
                '''
                script {
                    env.JAVA_HOME = "${env.WORKSPACE}/.jdk/jdk-25.0.5+8"
                    env.PATH = "${env.JAVA_HOME}/bin:${env.PATH}"
                }
            }
        }

        stage('Verify Java runtime') {
            steps {
                sh '''
                    set -eu
                    java_spec=$(java -XshowSettings:properties -version 2>&1 | sed -n 's/^[[:space:]]*java.specification.version = //p' | head -n 1)
                    case "$java_spec" in
                        ''|*[!0-9]*)
                            echo "Unable to determine the Java specification version: ${java_spec:-unknown}" >&2
                            exit 1
                            ;;
                    esac
                    if [ "$java_spec" -lt 25 ]; then
                        echo "JDK 25 or later is required; found Java $java_spec." >&2
                        exit 1
                    fi
                    java -version
                    mvn -version
                '''
            }
        }

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
                    gradle_version=9.9.1
                    gradle_dir="$WORKSPACE/.gradle-dist/gradle-$gradle_version"
                    if [ ! -x "$gradle_dir/bin/gradle" ]; then
                        mkdir -p "$WORKSPACE/.gradle-dist"
                        archive="gradle-$gradle_version-bin.zip"
                        curl -fsSL "https://services.gradle.org/distributions/$archive" -o "$WORKSPACE/.gradle-dist/$archive"
                        (cd "$WORKSPACE/.gradle-dist" && echo "d8a18a7a841dd5df825d35a685fad6f2d7f12ac0c280e57b67c27b4a520ba228  $archive" | sha256sum --check -)
                        unzip -q "$WORKSPACE/.gradle-dist/$archive" -d "$WORKSPACE/.gradle-dist"
                        rm "$WORKSPACE/.gradle-dist/$archive"
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
                sh 'COVERAGE_FILE=python/.coverage PYTHONPATH=python python/.venv/bin/python -m coverage run --source=src.palindrome -m unittest discover -s python/tests'
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
