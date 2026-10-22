# AKS Scripts

This guide covers every runnable Bash and PowerShell script in `scripts/` and
the legacy deployment entry points in `k8s/`.

## Runtime and shared conventions

- Bash scripts target Ubuntu and Red Hat family Linux distributions.
- PowerShell scripts run with PowerShell 7 on Windows or Linux. Install the
  native tools needed for each operation (`az`, `docker`, `kubectl`, `curl`,
  and, for the VM bootstrap, Linux package and service tools).
- AKS scripts use the active `kubectl` context. `K8S_NAMESPACE` defaults to
  `default`; rollout operations use `ROLLOUT_TIMEOUT=300s` by default.
- Every executable supports `-h` and `--help`. It validates its arguments and
  relevant environment inputs before making changes.
- Bash output and PowerShell log messages are timestamped. Logs default to
  `~/.local/state/ai-k8s-demo/logs/`; set `SCRIPT_LOG_DIR` to select another
  directory. The Bash VM bootstrap defaults to
  `/var/log/aks-vm-bootstrap.log`; set `BOOTSTRAP_LOG_FILE` to override it.
- Bash scripts share [`lib/common.sh`](lib/common.sh). PowerShell scripts share
  [`common.ps1`](common.ps1).

Run the commands from the repository root. PowerShell commands are in the
PowerShell column; for example, run `./scripts/aks-deploy-api.ps1 --help` in a
PowerShell 7 session.

## AKS operations

| Purpose | Bash usage | PowerShell usage | Inputs and defaults |
| --- | --- | --- | --- |
| Check cluster access, namespace, and server-side manifest validation | `./scripts/aks-preflight-check.sh` | `./scripts/aks-preflight-check.ps1` | `K8S_NAMESPACE=default` |
| Fetch AKS credentials and show cluster status | `./scripts/aks-connect.sh` | `./scripts/aks-connect.ps1` | `AZURE_RESOURCE_GROUP=challenge2-rg`; `AKS_CLUSTER_NAME=challenge-aks` |
| Build and push the Dolly API container image | `./scripts/aks-build-push-image.sh` | `./scripts/aks-build-push-image.ps1` | `IMAGE=andyxuan2010/dolly-api:v1.0` |
| Apply the API deployment, service, and ingress manifests, then wait for rollout | `./scripts/aks-deploy-api.sh` | `./scripts/aks-deploy-api.ps1` | `K8S_NAMESPACE=default`; `ROLLOUT_TIMEOUT=300s` |
| Check the API endpoint with an HTTP request | `./scripts/aks-smoke-test.sh` | `./scripts/aks-smoke-test.ps1` | `API_URL=https://basf.argentiacapital.com/`; `CURL_TIMEOUT=20` |
| Show or follow deployment logs | `./scripts/aks-api-logs.sh [deployment]` | `./scripts/aks-api-logs.ps1 [deployment]` | Deployment defaults to `dolly-api`; `FOLLOW=true`, `SINCE=30m`, `TAIL=200`, `K8S_NAMESPACE=default` |
| Watch pods, optionally filtered by label selector | `./scripts/aks-watch-pods.sh` | `./scripts/aks-watch-pods.ps1` | `K8S_NAMESPACE=default`; optional `POD_SELECTOR` |
| List recent Kubernetes events | `./scripts/aks-events.sh` | `./scripts/aks-events.ps1` | `K8S_NAMESPACE=default`; `EVENT_LIMIT=50` |
| Collect cluster and namespace status, events, and optional pod details/logs | `./scripts/aks-diagnostics.sh [pod]` | `./scripts/aks-diagnostics.ps1 [pod]` | `K8S_NAMESPACE=default`; `APP_LABEL=app=dolly-api` |
| Show node/pod resource usage and HPA information | `./scripts/aks-resource-usage.sh` | `./scripts/aks-resource-usage.ps1` | `K8S_NAMESPACE=default`; metrics-server is required for `kubectl top` |
| Wait for a deployment rollout and list deployments and pods | `./scripts/aks-rollout-status.sh [deployment]` | `./scripts/aks-rollout-status.ps1 [deployment]` | Deployment defaults to `dolly-api`; `K8S_NAMESPACE=default`; `ROLLOUT_TIMEOUT=300s` |
| Show a deployment's rollout history or a revision | `./scripts/aks-rollout-history.sh [deployment [revision]]` | `./scripts/aks-rollout-history.ps1 [deployment [revision]]` | Deployment defaults to `dolly-api`; optional positive revision; `K8S_NAMESPACE=default` |
| Restart the Dolly API deployment and wait for rollout | `./scripts/aks-restart-api.sh` | `./scripts/aks-restart-api.ps1` | `K8S_NAMESPACE=default`; `ROLLOUT_TIMEOUT=300s` |
| Roll back the Dolly API deployment | `./scripts/aks-rollback-api.sh [revision]` | `./scripts/aks-rollback-api.ps1 [revision]` | Optional positive revision; `K8S_NAMESPACE=default`; `ROLLOUT_TIMEOUT=300s` |
| Update the API image and wait for rollout | `./scripts/aks-update-api-image.sh <registry/image:tag>` | `./scripts/aks-update-api-image.ps1 <registry/image:tag>` | Required image; `DEPLOYMENT=dolly-api`; `CONTAINER=dolly-api`; `K8S_NAMESPACE=default`; `ROLLOUT_TIMEOUT=300s` |
| Scale the Dolly API deployment | `./scripts/aks-scale-api.sh <replica-count>` | `./scripts/aks-scale-api.ps1 <replica-count>` | Required non-negative count; `K8S_NAMESPACE=default`; `ROLLOUT_TIMEOUT=300s` |
| Forward a local port to the API service | `./scripts/aks-port-forward-api.sh [local-port]` | `./scripts/aks-port-forward-api.ps1 [local-port]` | Local port defaults to `8000`; `SERVICE_NAME=dolly-api-service`; `SERVICE_PORT=8000`; `K8S_NAMESPACE=default` |
| Install ingress-nginx and wait for its controller | `./scripts/aks-install-ingress.sh` | `./scripts/aks-install-ingress.ps1` | Default manifest is ingress-nginx controller `v1.8.1`; `INGRESS_NGINX_MANIFEST_URL` overrides it; `ROLLOUT_TIMEOUT=300s` |
| Show or follow ingress controller logs | `./scripts/aks-ingress-logs.sh` | `./scripts/aks-ingress-logs.ps1` | `INGRESS_NAMESPACE=ingress-nginx`; `INGRESS_DEPLOYMENT=ingress-nginx-controller`; `FOLLOW=true`; `SINCE=30m`; `TAIL=200` |
| Delete the Dolly API and demo NGINX resources | `./scripts/aks-cleanup-demo.sh` | `./scripts/aks-cleanup-demo.ps1` | `K8S_NAMESPACE=default` |

Set environment values before running a script. For example:

```bash
FOLLOW=false TAIL=100 ./scripts/aks-api-logs.sh
```

```powershell
$env:FOLLOW = 'false'
$env:TAIL = '100'
./scripts/aks-api-logs.ps1
```

`FOLLOW` accepts `true` or `false`. Integer, port, and duration inputs are
validated before the scripts call the cluster.

## VM bootstrap

| Script | Usage | Notes |
| --- | --- | --- |
| [`userdata-linux.sh`](userdata-linux.sh) | `sudo ./scripts/userdata-linux.sh` | Self-contained Bash bootstrap for Ubuntu or Red Hat family Linux. Expects root and an existing `azuser` account. Optional `KUBECTL_VERSION`, `HELM_VERSION`, and `BOOTSTRAP_LOG_FILE`. |
| [`userdata-linux.ps1`](userdata-linux.ps1) | `sudo pwsh -File ./scripts/userdata-linux.ps1` | PowerShell Core bootstrap for Ubuntu or Red Hat family Linux. Expects root and an existing `azuser` account. Optional `KUBECTL_VERSION`, `HELM_VERSION`, and `BOOTSTRAP_LOG_FILE`. |

## Legacy deployment entry point

| Bash usage | PowerShell usage | Purpose and inputs |
| --- | --- | --- |
| `./k8s/run.sh` | `./k8s/run.ps1` | Builds and pushes the API image, applies the manifests from `k8s/`, and waits for rollout. Optional `IMAGE`, `PUBLISHED_IMAGE`, and `ROLLOUT_TIMEOUT`. |

`common.sh` and `common.ps1` are shared libraries, not standalone commands.
