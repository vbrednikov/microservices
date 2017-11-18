# Importing Google Stackdriver Data to Local Prometheus

We use [frodenas/stackdriver_exporter](https://github.com/frodenas/stackdriver_exporter) docker image for this purpose. In order to work, it requires special service account to be created in IAM, with "Monitoring Viewer" role enabled. Place generated json credentials file to stackdriver.json and build the image with docker-compose: `docker-compose up --build stackdriver_exporter`. Read [Google Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials) for more info on authorization process.

Metrics for observation can be specified in `STACKDRIVER_EXPORTER_MONITORING_METRICS_TYPE_PREFIXES` in .env file. See the full list of available metrics on [Google cloud documentation](https://cloud.google.com/monitoring/api/metrics).

# :exclamation:	**WARNING**

> Do not upload the image to docker hub since it contains credentials to access valuable runtime statistics of your project!
