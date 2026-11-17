# All-tech-stack SonarQube monorepo

This repository demonstrates four independent features, each implemented and
tested in its own technology stack:

| Feature | Stack | Source and tests |
| --- | --- | --- |
| Greeting formatter | Java / Maven | `java-maven/` |
| Tax calculator | Java / Gradle | `java-gradle/` |
| URL slug generator | Node.js | `node/` |
| Palindrome checker | Python | `python/` |

The root `Jenkinsfile` builds and tests the projects sequentially, then submits
their sources and coverage reports together as one SonarQube project.

## Run locally

Install JDK 17 or later, Maven, Node.js 20+, npm, and Python 3.10+. The
Jenkins pipeline downloads and checksum-verifies Gradle 8.10.2.

Start the browser demo from the repository root:

```sh
cd demo
npm start
```

Open [http://127.0.0.1:3000](http://127.0.0.1:3000). The demo compiles the Java
feature classes when it starts and calls the Java, Node.js, and Python feature
implementations. It listens only on localhost.

```sh
mvn -B -f java-maven/pom.xml clean verify
gradle -p java-gradle clean check jacocoTestReport
cd node && npm install && npm test
cd ../python && python -m venv .venv
# Activate .venv, then:
python -m pip install -r requirements.txt
python -m coverage run --source=src.palindrome -m unittest discover -s tests
python -m coverage xml -o coverage.xml
python -m coverage report --fail-under=80
```

The Node and Python test commands enforce an 80% line-coverage minimum. Maven
and Gradle enforce the same minimum through JaCoCo. The browser demo's server
and page scripts are analyzed but excluded from coverage because they are
integration/presentation code rather than the independently tested features.

## Jenkins and SonarQube setup

Run the pipeline on a Linux Jenkins agent with JDK 17 or later, Maven, `curl`,
`unzip`, `sha256sum`, Node.js 20+, npm, Python 3, and pip available on `PATH`.
The pipeline downloads and verifies Gradle 8.10.2, so no Jenkins Gradle tool
installation is required. Configure the Jenkins SonarQube Scanner plugin with
a server installation named `SonarQube`, a
scanner tool named `SonarScanner`, and the SonarQube webhook to Jenkins at
`<jenkins-url>/sonarqube-webhook/`.

The pipeline uses `sonar-project.properties`'s project key (`monorepo-alltechstack`)
for the single SonarQube project. Create that project on the server (or enable
project auto-provisioning) and apply a quality gate that requires coverage and
the other checks your team expects. Jenkins waits for the server-side gate and
fails the pipeline if it does not pass.

Run `Jenkinsfile` as a Pipeline script from SCM. Coverage reports are generated
before the single root-level SonarQube analysis.
