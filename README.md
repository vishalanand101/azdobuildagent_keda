# Run Azure Pipelines inside Docker Containers

Pipelines in Azure DevOps can run inside:  
1) Microsoft hosted agent (in the Azure cloud)  
2) Azure VMSS  
3) Self hosted agent  
4) Windows Server Core or Ubuntu containers  

This demo will deal with the last option. Here are the steps:  
1) Create the build agent container from a Dockerfile. 
2) Run the build agent container inside a host machine. 
3) Run the build agent container using Azure Kubernetes Service (AKS). 
4) Scaling the agents based on the number of jobs in 'waiting' status.  

Follow the instructions here to cover the the steps 1, 2 and 3: https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops  

```bash
# create the container build agent
docker build -t acrforakscluster.azurecr.io/dockeragent:ubuntu-18.04 .
# run the container build agent in host machine
docker run -e AZP_URL=https://dev.azure.com/houssemdellai `
  -e AZP_TOKEN=<YOUR_PAT_TOKEN> `
  -e AZP_POOL=linux-containers-aks `
  acrforakscluster.azurecr.io/dockeragent:ubuntu-18.04
# deploy a Deployment to run the container build agent in Kubernetes
kubectl apply -f dployment-agent.yaml
```
The step number 4 is covered here: Resources:
https://keda.sh/blog/2021-05-27-azure-pipelines-scaler/  
```bash
# deploy KEDA's scaledObject to scale out/in the build agents based on number of waiting jobs:
kubectl apply -f scaledObject-keda.yaml
```
Important notes from https://docs.microsoft.com/en-us/learn/modules/aks-app-scale-keda/6-concept-scaling-options  
## KEDA's relationship with HPA  
KEDA acts as a “Custom Metrics API” for exposing metrics to the HPA. KEDA can't do its job without the HPA. The complexity of developing a metrics server is abstracted away by using KEDA.  
Scalers are the glue that provides the metrics from various sources to the HPA. Here's a list of some of the most widely used scalers:  
Apache Kafka  
AWS CloudWatch  
AWS Kinesis Stream  
AWS SQS Queue  
Azure Blob Storage  
Azure Event Hubs  
Azure Log Analytics  
Azure Monitor  
Azure Service Bus  
Azure Storage Queue  
Google Cloud Platform Pub/Sub  
IBM MQ  
InfluxDB  
NATS Streaming  
OpenStack Swift  
PostgreSQL  
Prometheus  
RabbitMQ Queue  
Redis Lists  
For a complete list view the scalers section on the KEDA site.  
A common question is when should one use a HPA and when to enlist KEDA. If the workload is memory or cpu intensive, and has a well defined metric that can be measured then using a HPA is sufficient. When dealing with a workload that is event driven or relies upon a custom metric, then using KEDA should be the first choice.  
