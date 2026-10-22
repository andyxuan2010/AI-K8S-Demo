# AKS Scripts

This folder contains versioned Bash scripts for AKS operations and Linux VM
bootstrap. The scripts target Ubuntu and Red Hat family Linux distributions.

## Usage and conventions

Run scripts from the repository root or call them by path. Each executable
script supports `--help` and `-h` and prints its usage line. For example:

```bash
./scripts/aks-deploy-api.sh --help
./scripts/aks-deploy-api.sh
```

AKS scripts use the current `kubectl` context and require `kubectl` plus the
cluster permissions needed for the requested operation. `K8S_NAMESPACE`
defaults to `default`. Common rollout operations use `ROLLOUT_TIMEOUT`, which
defaults to `300s`.

Scripts enable Bash strict mode, validate arguments and supported environment
values, and log timestamped output and failures through
[`lib/common.sh`](lib/common.sh). Logs default to
`~/.local/state/ai-k8s-demo/logs/`; set `SCRIPT_LOG_DIR` to change the location.
The standalone VM bootstrap writes to `/var/log/aks-vm-bootstrap.log` by default;
set `BOOTSTRAP_LOG_FILE` to override it.

## AKS operation scripts

| Script | Purpose | Arguments and notable environment inputs |
| --- | --- | --- |
| [`aks-preflight-check.sh`](aks-preflight-check.sh) | Checks cluster access, namespace availability, and server-side validation of API manifests. | `K8S_NAMESPACE` |
| [`aks-connect.sh`](aks-connect.sh) | Fetches AKS credentials and displays cluster information and nodes. | `AZURE_RESOURCE_GROUP`, `AKS_CLUSTER_NAME` |
| [`aks-build-push-image.sh`](aks-build-push-image.sh) | Builds and pushes the Dolly API image. | `IMAGE` |
| [`aks-deploy-api.sh`](aks-deploy-api.sh) | Applies deployment, service, and ingress manifests, then waits for rollout. | `K8S_NAMESPACE`, `ROLLOUT_TIMEOUT` |
| [`aks-smoke-test.sh`](aks-smoke-test.sh) | Sends an HTTP request to the API endpoint. | `API_URL`, `CURL_TIMEOUT` |
| [`aks-api-logs.sh`](aks-api-logs.sh) | Shows or follows deployment logs. | `[deployment]`; `K8S_NAMESPACE`, `FOLLOW`, `SINCE`, `TAIL` |
| [`aks-watch-pods.sh`](aks-watch-pods.sh) | Watches namespace pods, optionally filtered by label selector. | `K8S_NAMESPACE`, `POD_SELECTOR` |
| [`aks-events.sh`](aks-events.sh) | Lists the latest namespace events. | `K8S_NAMESPACE`, `EVENT_LIMIT` |
| [`aks-diagnostics.sh`](aks-diagnostics.sh) | Collects cluster and namespace status, events, and optionally a pod description and logs. | `[pod]`; `K8S_NAMESPACE`, `APP_LABEL` |
| [`aks-resource-usage.sh`](aks-resource-usage.sh) | Shows node and pod usage plus HPA information. | `K8S_NAMESPACE`; metrics-server is required for `kubectl top` |
| [`aks-rollout-status.sh`](aks-rollout-status.sh) | Waits for a deployment rollout and lists deployments and pods. | `[deployment]`; `K8S_NAMESPACE`, `ROLLOUT_TIMEOUT` |
| [`aks-rollout-history.sh`](aks-rollout-history.sh) | Displays deployment rollout history or a selected revision. | `[deployment [revision]]`; `K8S_NAMESPACE` |
| [`aks-restart-api.sh`](aks-restart-api.sh) | Restarts the Dolly API deployment and waits for rollout. | `K8S_NAMESPACE`, `ROLLOUT_TIMEOUT` |
| [`aks-rollback-api.sh`](aks-rollback-api.sh) | Rolls the Dolly API deployment back to its previous or selected revision. | `[revision]`; `K8S_NAMESPACE`, `ROLLOUT_TIMEOUT` |
| [`aks-update-api-image.sh`](aks-update-api-image.sh) | Updates a deployment container image and waits for rollout. | `<registry/image:tag>`; `K8S_NAMESPACE`, `DEPLOYMENT`, `CONTAINER`, `ROLLOUT_TIMEOUT` |
| [`aks-scale-api.sh`](aks-scale-api.sh) | Sets the Dolly API replica count and waits for rollout. | `<replica-count>`; `K8S_NAMESPACE`, `ROLLOUT_TIMEOUT` |
| [`aks-port-forward-api.sh`](aks-port-forward-api.sh) | Forwards a local TCP port to the API service. | `[local-port]`; `K8S_NAMESPACE`, `SERVICE_NAME`, `SERVICE_PORT` |
| [`aks-install-ingress.sh`](aks-install-ingress.sh) | Applies ingress-nginx and waits for its controller rollout. | `INGRESS_NGINX_MANIFEST_URL`, `ROLLOUT_TIMEOUT` |
| [`aks-ingress-logs.sh`](aks-ingress-logs.sh) | Shows or follows ingress controller logs. | `INGRESS_NAMESPACE`, `INGRESS_DEPLOYMENT`, `FOLLOW`, `SINCE`, `TAIL` |
| [`aks-cleanup-demo.sh`](aks-cleanup-demo.sh) | Deletes Dolly API and demo NGINX resources from the selected namespace. | `K8S_NAMESPACE` |

Boolean inputs use `true` or `false`; integer and duration inputs are validated
before commands run. `FOLLOW` defaults to `true` for both log scripts.

## VM bootstrap

[`userdata-linux.sh`](userdata-linux.sh) is a self-contained bootstrap for
Terraform custom data. It installs VM tools, Docker, AWS CLI, `kubectl`, and
Helm. It expects to run as root on a supported Ubuntu or Red Hat family VM with
the `azuser` account already created. `KUBECTL_VERSION` and `HELM_VERSION` can
override the installed versions.

The legacy [Kubernetes deploy entry point](../k8s/run.sh) builds and pushes an
image and applies the API manifests from the `k8s/` directory.
