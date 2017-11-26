# Microservices
Docker demo

## Prerequisites

* installed docker and docker-machine
* authorized gcloud
* microservices project is selected as default in gcloud settings. Run
`gcloud init` to switch from/to other projects.

All docker commands are run through docker-machine on google cloud instance.
That's how it can be initialized:

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



## Building microservice images

The app consists of `ui`,  `post-py` and `comments` microservices having each
a separate Dockerfile to build from. Also, default mongo:latest machine is
required.

1. Prepare docker images:
```
docker pull mongo:latest
docker build -t vbrednikov/post:latest ./post-py
docker build -t vbrednikov/comment:latest ./comment
docker build -t vbrednikov/ui:latest ./ui
```

## Run containers for microservices manually in single network
```
docker network create reddit
```

```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db \
	-v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post vbrednikov/post:latest
docker run -d --network=reddit --network-alias=comment vbrednikov/comment:latest
docker run -d --network=reddit -p 9292:9292 vbrednikov/ui:latest
```

## Run containers manually in frontend and backend networks
```
docker network create back_net subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24
```

```
docker run -d --network=back_net --network-alias=post_db --network-alias=comment_db \
	-v reddit_db:/data/db mongo:latest
docker run -d --network=back_net --network-alias=post vbrednikov/post:latest
docker run -d --network=back_net --network-alias=comment vbrednikov/comment:latest
docker run -d --network=front_net -p 9292:9292 vbrednikov/ui:latest

docker network connect front_net post
docker network connect front_net comment
```

## Bring up the environment with docker-compose

1. Copy .env.example to .env, fill it with your data (at least replace USERNAME).
This file will be sourced automatically.

2. Run `docker-compose run -d` to build and start the containers

3. To start containers with prefix different from directory name, use
`-p any_string` option


## Bring up the environment in docker swarm

1. Prepare several hosts to run docker, e.g. four:

```
#!/bin/bash
machine_type="g1-small"
machine_image=$(gcloud compute images list --filter ubuntu-1604-lts --uri)
project_id=$(gcloud info --format=flattened|grep config.project:|awk '{print $2}')
for machine_name in master-1 worker-1; do
    docker-machine create --driver google --google-project ${project_id} \
    --google-zone europe-west1-b  --google-machine-type ${machine_type}  \
    --google-machine-image  ${machine_image}  \
    $machine_name
done
```

2. Init swarm, join nodes, e.g.:

```
#!/bin/bash
docker-machine ssh master-1 sudo docker-swarm init
token=$(docker-machine ssh master-1 sudo docker-swarm join-token worker -q)
addr=$(docker-machine ssh master-1 sudo docker system info -f \"{{ .Swarm.NodeAddr }}\)
docker-machine ssh worker-1 sudo docker swarm join --token $token $addr
docker-machine ssh worker-2 sudo docker swarm join --token $token $addr
# ...
```

3. Label one node (e.g., master) as high-reliable to run mongo on it:
`docker node update --label-add reliability=high master-1`

4. Copy .env-example to .env, edit according to development needs.
Please note that it is not necessary to uncomment "latest" versions since it is
used by default.

5. On production deployment host, copy .env-example to .env-prod (or any other
suitable name). Specify network configuration and exact component versions there.

6. Another option is to put components versions to `.versions` file (e.g., from
 gitlab-ci when new tag is added)

Configuration is ready.

To deploy dev environment, run the script: `./deploy_stack.sh DEV`. It will use
settings from `.env` file, and latest versions of all the components, including
monitoring (if they are not freezed in `.env` or `.versions`).

To deploy prod environment, run the script with path to  environment file in
the second argument:`./deploy_stack.sh PROD .env-prod`. It will deploy PROD
stack with versions specified in `.env-prod` or `.versions`.

Caveats:
- this is just proof of concept, don't treat it as production ready :)
- do not deploy prod and dev stacks on the same cluster
- in good production, mongo should be deployed on baremetal, currently it is in
  todo list
- do not deploy dev and prod from the same folder since .versions will be freezed
- business logic monitoring probably does not work
- need to parametrize count of nodes for production and dev

## Verification

1. Check web application at IP:9292, where IP is reported by `docker-machine ls`
2. Post any post with and without link
3. Add a comment to this post
4. Stop and start the environment with
`docker-compose -p project stop`/`docker-compose -p project up -d`, make sure
that post and comment are in place
