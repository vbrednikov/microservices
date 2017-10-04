# microservices
Docker demo

## Prerequisites

* installed docker and docker-machine
* authorized gcloud
* microservices project is selected as default in gcloud settings

## Workflow

1. Initialize docker host in Google cloud to run docker on it:

```
project_id=$(gcloud info --format=flattened|grep config.project:|awk '{print $2}') ; \
docker-machine create \
    --driver google \
    --google-project $project_id \
    --google-zone europe-west1-b \
    --google-machine-type f1-micro \
    --google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
    docker-host
```
2. Import env variables:
```
eval $(docker-machine env docker-host)
```

3. Enable TCP port 9292 to gain access to puma server:
```
gcloud compute firewall-rules create puma-server --allow=tcp:9292 --description="Allow access to web-service" --direction=IN --network=default --target-tags=docker-machine
```

4. Build docker image:
```
docker build -t reddit:latest .
```

5. Start container:

```
docker run --name reddit -d --network=host reddit:latest
```

6. Check http://IP:9292

7. After all, delete the instance:
```
docker-machine rm docker-host
```
