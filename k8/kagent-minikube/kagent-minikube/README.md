# kagent Minikube offline-image workflow (0.10.3)

This is a **manifest generation bundle**, not pre-rendered Kubernetes manifests. Helm pulls versioned upstream charts to create complete YAML (RBAC, CRDs, controller, UI, services, configurations, sample agents, tools, and dependencies). Docker images may be downloaded before loading them into Minikube; after that, the pods can use local images.

Prerequisites: Linux / WSL Ubuntu shell, `helm`, `kubectl`, `docker`, `minikube`, Python 3 with PyYAML (`python3 -m pip install pyyaml`), OpenAI API key, an existing Minikube cluster with adequate RAM/CPU. Internet is required for chart downloads and any Docker pulls not previously cached. Ensure Minikube can allocate at least 4 CPU / 8 GiB RAM to start (more if needed by dependencies).

```
minikube start --cpus=4 --memory=8192
minikube addons enable default-storageclass
minikube addons enable storage-provisioner
export OPENAI_API_KEY='YOUR_KEY'  # never commit the key
bash render.sh
cat generated/images.txt
bash load-images.sh
bash deploy.sh
bash verify.sh
```

Open `http://localhost:8080` while `verify.sh` is port-forwarding.

CAUTIONS:
- Inspect render outputs, especially helm hooks / dependencies and generated agents, before applying. Helm charts can contain hook-driven tasks that raw `kubectl apply` will not emulate.
- `helm template --include-crds` can include duplicate CRDs (verify before using). When kagent's CRDs are already present, do not inadvertently replace incompatible versions.
- Raw `kubectl apply` does not perform Helm hook semantics or install lifecycle. If the rendered platform relies on jobs/hooks or CRDs missing from raw YAML, switch to `helm upgrade --install` using the same values.
- `imagePullPolicy: Never` requires every image in Minikube under **the exact image name/tag**, including agent runtimes created later by the controller. Check pod events for `ErrImageNeverPull`.
- This bundle includes no API key in version-controlled manifests; the secret is generated at deploy time.
- Agents powered by Python/BYO runtime, agent full images, and KMCP-managed tool runtimes may require extra images not referenced directly in rendered Deployments. Check CRs and `kubectl describe pod` and add images to `generated/images.txt` accordingly.
- Set a stable storageclass and consider persistence and reduced privileges for non-lab deployment.
