How to use it:
1. Create a cluster:
`kind create cluster --name skill-importance --config ./controllers/config.yaml`
2. Install Traefik (you may need to install helm first):
`helm install traefik traefik/traefik --namespace traefik --set "service.type=NodePort" --create-namespace`
3. Apply controllers:
`kubectl apply -f ./controllers/`
4. Apply CNI plugin:
`kubectl apply -f https://docs.tigera.io/calico/latest/manifests/calico.yaml`
5. After frontend and backend pods are ready, activate port forwarding:
`kubectl port-forward svc/frontend-service 3000:80`
`kubectl port-forward svc/backend-service 8080:8080`
6. Open localhost:3000. You are awesome!

To delete the cluster and all information stored in it, just run this command:
`kind delete cluster --name skill-importance`
