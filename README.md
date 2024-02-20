# WSO2 Micro-Integrator 4.2.0 Developer Template

This repository contains a developer template for WSO2 Micro-Integrator 4.2.0, equipped with a Makefile that simplifies common development tasks.

## Prerequisites
Before you begin, ensure you have the following tools installed on your machine:

- **Java 11:** Make sure you have Java Development Kit (JDK) 11 installed.

- **Maven:** Maven is used for building and managing the project.

- **Podman:** Podman is used for building and running containerized applications. Make sure you have Podman installed on your machine. 

### srouce folder
The "src" folder contains both, synapse configs as well as mediator classes (java). Both sources are built using maven and alredy defined in the pom.xml. Also the build files are put into the corresponding folder "mi-home/lib" for jar's and "mi-home/carbonapps" for cabron apps.
Structure:
```bash
.
└── main
    ├── java
    │   └── ch
    │       └── integon
    │           └── example
    │               └── EXAMPLEMediator.java
    ├── registry-resources
    │   └── artifact.xml
    └── synapse-config
        ├── api
        ├── artifact.xml
        ├── dataservice
        ├── endpoints
        ├── local-entries
        ├── proxy-services
        ├── sequences
        └── tasks
```
The configs belong to the specific folder. For example, If I want to deploy a "API" I create a yml file in main/synapse-configs/api/hello-api.xml

### creating new configs
Adding a new config involves a couple of steps:
1. create a config file (e.g. api-foobar.xml in main/synapse-config/api)
2. add the artifact to the artifact file in main/synapse-configs/artifact.xml with the corresponding type and role
```xml
<?xml version="1.0" encoding="UTF-8"?>
<artifacts>
    <artifact name="hello-api" type="synapse/api" serverRole="EnterpriseServiceBus" groupId="ch.integon.example"
              version="1.0.0">
        <file>api/hello-api.xml</file>
    </artifact>
</artifacts>
```
INFO: type must be chanched according folder name: api, dataservice, etc.

3. build the project using the following command in the project root
```bash
mvn clean install
```

### custom mediators
in the template, there is already a example mediator available:

```bash
main/java/ch/integon/example/EXAMPLEMediator.java
```
Custome mediators are built and the .jar file is put in mi-hom/lib after:
```bash
mvn clean install
```

### including commons or other carbon apps
For every commons project (.car) the file must be put in the folder
```bash
mi-home/carbonapps/
```
Every image-build uses this location and includes all containg files.

### including java libs
To add additional java libs to the project, simply place them in 
```bash
mi-home/libs/
```
for example: database connectors or message broker libraries can be placed here

### local deployment
the pipeline replaces variables and (secure-) files automatically. for local development this is done by the Makefile. To locally define passwords, secure-files etc. the following options are available:
- .env (file)
```bash
MY_PASSWORD=abcd12345
```
- .file (folder): volumes in docker-compose.yaml can now reference files in there. For example: put a test_cert.key inside the .files and in the docker-compose.yaml the files is references. When running in the pipeline, make sure this file actually exists in the secure files.

**INFO**: .env and .files are ignored by git. these files are for local development only! It is not allowed to checkin passwords or sensitive files!


## filehub
the filehub micro-service is part of the docker-compose.yaml deployment. Every project contains a filehub.conf if VFS IN or OUT is needed. The filehub service is configured using the filehub.conf file:
```bash
[fh.example-in]
Type=IN
FileURI=file:///IN
MISendURI=http://mi:8080/hello
FileNamePattern=*.xml
ContentType=application/xml
PollInterval=2
ActionAfterProcess=move
ActionAfterFailure=move
MoveAfterProcess=archive
MoveAfterProcessDatedArchive=true
MoveAfterFailure=fail
Locking=true

[fh.example-out1]
Type=OUT
FileURI=file:///OUT
Locking=true

[fh.example-out-sftp]
Type=OUT
FileURI=file:sftp://some-server/foo/bar
Auth=$cert
Locking=true
SFTPIdentities=/path/to/privatekey
SFTPIdentityPassPhrase=my_key_password
```

The above config does the following:
- starts a listener for the config "example-in" on folder /IN and is looking for files with the pattern *.xml. If a file is found, it sends it to "http://mi:8080/hello" with the content-type "application.xml". Before reading it, the file is lock by renaming it to ".tmp". When the file is successfully transfered, the file is put in "./archive/<yyyy-MM-dd>/<file-name>. If it failes, it is put in "./fail/<timestamp>_<filename>

The Parameters are all according https://ei.docs.wso2.com/en/latest/micro-integrator/references/synapse-properties/transport-parameters/vfs-transport-parameters/

Full list of parameters:
```bash
Type --> IN or OUT
FileURI --> uri of file/folder: smb://, file:// or sftp://
MISendURI --> uri of the api or http proxy in the micro-integrator
FileNamePattern --> simple file pattern like "*.txt"
ContentType --> content type of the files defined in the FileURI
PollInterval --> poll interval in seconds
Auth --> either "username:password" like "foo:bar" or the value cert (then SFTPIdentities and SFTPIdentityPassPhrase is used)
ActionAfterProcess --> action after success: none, delete or move
ActionAfterFailure --> action after failure: none, delete or move
MoveAfterProcess --> location after success with FileURI as base
MoveAfterProcessDatedArchive --> inside "MoveAfterProcess" create a folder with timestamp "yyyy-MM-dd" and move the file in this folder
MoveAfterFailure --> location after failure with FileURI as base
Locking --> apply locking mechanism: renaming file to ".tmp" and after transaction remove the lock
SFTPIdentities --> path to the certficate
SFTPIdentityPassPhrase --> password of the certificate
```

**INFO** the microservice checks the config file during startup. Not all combination of values are relevant or possible. E.g. sending needs no poll interval

## Makefile Commands

### Build
To build the WSO2 Micro-Integrator project, run the following command:
```bash
make build
```
This command will clean the project, package it using Maven, and then build a Container image using Podman.

### Run Compose
To run the WSO2 Micro-Integrator in a container as compose with the filehub, use the following command:
```bash
make run-compose
```
This command starts a container named mi-test in detached mode, exposing the Micro-Integrator on port 8080. It also logs the container output, and you can stop the logging using Ctrl+C.

### Run
To run the WSO2 Micro-Integrator in a container, use the following command:
```bash
make run
```
This command starts a container named mi-test in detached mode, exposing the Micro-Integrator on port 8080. It also logs the container output, and you can stop the logging using Ctrl+C.

### Clean
To clean the project and remove any generated files, run:
```bash
make clean
```

### Stop
To stop the running Podman container, use:
```bash
make stop
```

### Delete
To forcefully remove the Podman container, run:
```bash
make delete
```

### Fresh
To perform a complete fresh build, including cleaning, building, and running the container, use:
```bash
make fresh
```

### Test
To test the Micro-Integrator health endpoint, run:
```bash
make test
```
This command sends a GET request to http://localhost:8080/health.
