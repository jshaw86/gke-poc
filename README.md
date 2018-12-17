Overview
This is a simple POC of GKE automation, demonstrates end-to-end of a terraform and kubectl gke hello world. I would like to extend this to include helm, istio and expand to multi region with a GLB.

Setup gcloud cli
https://cloud.google.com/sdk/docs/

Set up google project
https://cloud.google.com/resource-manager/docs/creating-managing-projects
```
export GOOGLE_PROJECT=$(gcloud config get-value project)
gcloud services enable container.googleapis.com
gcloud config set compute/zone us-west1
```

Bring up GCP networking and K8's clusters
```
terraform init
terraform plan
terraform apply
```

Get K8's credentials
```
gcloud container clusters get-credentials tf-region1
```

Provision Hello World K8's application
```
kubectl run web --image=gcr.io/google-samples/hello-app:1.0 --port=8080
kubectl expose deployment web --target-port=8080 --type=NodePort
```

Setup a load balancer
```
kubectl apply -f basic-ingress.yaml
kubectl get ingress basic-ingress
```

Navigate to the address that gke provisions to the ingress, can take a few minutes(took 7 minutes for me)

Clean it up
```
terraform destroy
```

Sources/Additional Reading
https://github.com/GoogleCloudPlatform/terraform-google-examples/tree/master/example-gke-k8s-multi-region
https://github.com/nagypeterjob/terraform-gke-helm
https://cloud.google.com/kubernetes-engine/docs/tutorials/http-balancer
https://cloud.google.com/kubernetes-engine/docs/tutorials/installing-istio
