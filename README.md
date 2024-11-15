#### ⚠️ DISCLAIMER

These artifacts are build as a reference implementation only developed for research and learning purposes and should not be used in production

---

# Changelog

This section defines the deviations in this version from original [Dockerfile implementaion](https://github.com/wso2/docker-is/blob/master/dockerfiles/alpine/is/Dockerfile) of wso2 identity server Alpine base image.

### 1. Migration from adoptium temurin jdk 11 to liberica jre 11

This change is done to mainly achieve the smaller docker image size. Compared to the the way that is done in the original implementation which is to download binary release of jdk from adoptium github release, This version utilizes the already available [liberica-runtime-containe](https://hub.docker.com/r/bellsoft/liberica-runtime-container). I found a open issue [#332](https://github.com/wso2/docker-is/issues/333) and a PR [#332](https://github.com/wso2/docker-is/pull/332) that maybe addressing some regressions due to doing this but coudn't find any evidences or reasons why this change was done.

### 2. Fix for a error warning massage that appears due to not using Location to store java preferences

This also has an open issue [355]("https://github.com/wso2/docker-is/issues/355") and a following [PR]("https://github.com/wso2/docker-is/pull/357") which seems to fix the issue but not yet merged. I implemented the same fix here to avoid warning log massages.

### 3. Some other smaller fixes such as,
- Avoiding legacy backward compatible Alternative syntax of ENV instruction used in the Dockerfile. https://docs.docker.com/reference/dockerfile/#env
- Avoiding setting JAVA_HOME & PATH Environment variables since base image already correctly setting those variables.
- Removing k8 membership scheme as mentioned in the [#403]("https://github.com/wso2/docker-is/pull/403)
- Removing preinstalled packages such as wget, unzip , netcat-openbsd. Couldnt find any usecase of these packages other than for downloading and extracting the IS server ZIP file.

# Todo

- [ ] Test whether use of liberica runtime image cause any regressions.
- [ ] Provide a seperate image with JDK and other OS base images provided by liberica

# Dockerfile for WSO2 Identity Server

This section defines the step-by-step instructions to build an [liberica-runtime-container](https://hub.docker.com/r/bellsoft/liberica-runtime-container) based Docker image for WSO2 Identity Server `7.0.0`.

## Prerequisites

- [Docker](https://www.docker.com/get-docker) `v17.09.0` or above
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) client

## How to build an image and run

##### 1. Checkout this repository into your local machine using the following Git client command.

```
git clone https://github.com/iamtrazy/wso2is-docker.git
```

##### 2. Build the Docker image.

- Navigate to cloned repository directory. <br>
  Execute `docker build` command as shown below.
  - `docker build -t wso2is:7.0.0 .`

> Tip - If you require the container to run with a different UID and GID, pass the preferred values of the UID and GID
> as values for build arguments `USER_ID` and `USER_GROUP_ID` when building the image, as shown below. Note
> that setting lower values for the UID and GID is not recommended.

- `docker build -t wso2is:7.0.0 --build-arg USER_ID=<UID> --build-arg USER_GROUP_ID=<GID> .`

##### 3. Running the Docker image.

- `docker run -it -p 9443:9443 wso2is:7.0.0`

> Here, only port 9443 (HTTPS servlet transport) has been mapped to a Docker host port.
> You may map other container service ports, which have been exposed to Docker host ports, as desired.

##### 4. Accessing management consoles.

- To access the user interfaces, use the docker host IP and port 9443.
  - Management Console: `https://<DOCKER_HOST>:9443/console`
  - User Portal: `https://<DOCKER_HOST>:9443/myaccount`

> In here, <DOCKER_HOST> refers to hostname or IP of the host machine on top of which containers are spawned.

## How to update configurations

Configurations would lie on the Docker host machine and they can be volume mounted to the container. <br>
As an example, steps required to change the port offset using `deployment.toml` is as follows:

##### 1. Stop the Identity Server container if it's already running.

In WSO2 Identity Server version `7.0.0` product distribution, `deployment.toml` configuration file <br>
can be found at `<DISTRIBUTION_HOME>/repository/conf`. Copy the file to some suitable location of the host machine, <br>
referred to as `<SOURCE_CONFIGS>/deployment.toml` and change the `[server] -> offset` value to 1.

##### 2. Grant read permission to `other` users for `<SOURCE_CONFIGS>/deployment.toml`.

```
chmod o+r <SOURCE_CONFIGS>/deployment.toml
```

##### 3. Run the image by mounting the file to container as follows:

```
docker run \
-p 9444:9444 \
--volume <SOURCE_CONFIGS>/deployment.toml:<TARGET_CONFIGS>/deployment.toml \
wso2is:7.0.0-alpine
```

> In here, <TARGET_CONFIGS> refers to /home/wso2carbon/wso2is-7.0.0/repository/conf folder of the container.

## Docker command usage references

- [Docker build command reference](https://docs.docker.com/engine/reference/commandline/build/)
- [Docker run command reference](https://docs.docker.com/engine/reference/run/)
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
