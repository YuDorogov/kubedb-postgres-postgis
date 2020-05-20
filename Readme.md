# Postgis for KubeDB

The start of a collection of Postgis images and Kubernetes resources for running Postgis within [KubeDB](https://kubedb.com).

## Add the PostgresVersion

To add the PostgisVersion to Kubernetes, first clone or download the repository, then run `kubectl apply -f apiversion.yaml` or build your own image from Dockerfile.

## Versions
- Postgresql -  11.7-alpine
- PostGIS - 3.0.1
