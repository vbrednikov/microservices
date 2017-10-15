# microservices
Docker demo

## Prerequisites

* installed docker and docker-machine
* authorized gcloud
* microservices project is selected as default in gcloud settings. Run `gcloud init` to switch from/to other projects.

All docker commands are run through docker-machine on google cloud instance. That's how it can be initialized:

```
project_id=$(gcloud info --format=flattened|grep config.project:|awk '{print $2}') ; \
docker-machine create \
    --driver google \
    --google-project $project_id \
    --google-zone europe-west1-b \
    --google-machine-type g1-small \
    --google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
    docker-host

```
Import env variables:
```
eval $(docker-machine env docker-host)
```

After all, delete the instance and reset environment variables:
```
docker-machine rm -f docker-host && eval $(docker-machine env -u)
```


## Monolith approach

1. Enable TCP port 9292 to gain access to puma server:
```
gcloud compute firewall-rules create puma-server --allow=tcp:9292 --description="Allow access to web-service" --direction=IN --network=default --target-tags=docker-machine
```

2. Build docker image from monolith folder:
```
docker build -t reddit:latest monolith
```

3. Start the container:
```
docker run --name reddit -d --network=host reddit:latest
```

6. Check http://IP:9292. IP is the IP reported by `docker-machine ls`



### Microservice approach

The app consists of `ui`,  `post-py` and `comments` microservices having each a separate Dockerfile to build from. Also, default mongo:latest machine is required.

1. Prepare docker images:
```
docker pull mongo:latest
docker build -t vbrednikov/post:1.0 ./post-py
docker build -t vbrednikov/comment:1.0 ./comment
docker build -t vbrednikov/ui:2.1 ./ui
```

2. Create network:
```
docker network create reddit
```

3. Run containers

```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db \
	-v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post vbrednikov/post:1.0
docker run -d --network=reddit --network-alias=comment vbrednikov/comment:1.0
docker run -d --network=reddit -p 9292:9292 vbrednikov/ui:2.1
```

4. Check web application at IP:9292, where IP is reported by `docker-machine ls`

### Additional ui versions

- **ui/Dockerfile.alpine** - Dockerfile that utilizes [Alpine Linux](https://hub.docker.com/_/alpine/), produses image of size 202M. Just replacement of original dockerfile.
- **ui/Dockerfile.alpine-minimal** - Alpine-based image of size 55M with deleted building and compiling tools.

Run the  following from the repo root folder to build this specific image:
```
docker build --no-cache -t vbrednikov/ui:3.0 -f ui/Dockerfile.alpine-minimal ./ui/
```

## Minimal image approaches

- Use [alpine linux](https://hub.docker.com/_/alpine/)
- build own distro from  scratch:
  - https://docs.docker.com/engine/userguide/eng-image/baseimages/
  - build minimal distributions from scratch (e.g. compile ruby without some features)
  - remove unnecessary basic packages not required to run ruby
