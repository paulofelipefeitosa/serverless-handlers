# Java functions for OpenFaaS experiments

## Deploying OpenFaaS

### FaaS

```
git clone https://github.com/paulofelipefeitosa/faas.git
cd faas
docker stack deploy func -c docker-compose.yml
```

### FaaS-Idler

```
git clone https://github.com/openfaas-incubator/faas-idler.git
cd faas-idler
```

In the docker-compose.yml file replace the lines:
```
-            inactivity_duration: "5m"
-            reconcile_interval: "30s"
+            inactivity_duration: "1m"
+            reconcile_interval: "5s"
```

Then run:
```
docker stack deploy func -c docker-compose.yml
```

## How to run the experiment

```
python execute-requests.py <gateway-address> <deployed-function-name> <requests-number>
```

The output file will be named like `<deployed-function-name>-<requests-number>-<timestamp>.csv`
