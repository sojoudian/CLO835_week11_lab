# CLO835 — Week 11 lab: Kubernetes cluster on AWS for the ConfigMaps & Secrets lab

Infrastructure-as-code for **`week11/Week11_lab.pptx`** (ConfigMaps & Secrets — inject a
ConfigMap and a Secret into Pods as environment variables).

Same self-forming **3-node kubeadm cluster** as the Week 10 lab
([CLO835_week11_lab](https://github.com/sojoudian/CLO835_week11_lab)) — 1 control plane + 2 workers on
AWS Academy Learner Lab EC2 instances, formed automatically at boot. The only change from Week 10 is the
**lab payload**: the staged manifests and `commands.sh` are the Week 11 ConfigMaps/Secrets workshop.

This workshop is light: it needs only a running cluster, `kubectl`, and the `luksa/fortune:env` image.
It does **not** use persistent storage. (The AWS EBS CSI driver and the `gp2` StorageClass are inherited
from the Week 10 cluster and installed at boot, but this lab never touches them — kept so the cluster is
byte-for-byte the same proven environment.)

## What `terraform apply` sets up (≈3–5 minutes)

| Requirement | How this Terraform provides it |
|---|---|
| A Kubernetes cluster | 3× m5.large, Ubuntu 24.04, kubeadm **v1.31**, Flannel CNI, self-forming |
| The lab YAMLs (`fortune-env-cm.yaml`, `fortune-secret-env.yaml`) | Staged automatically in **`/home/ubuntu/week11/`** on the master (source: [`manifests/`](manifests/)) |
| `luksa/fortune:env` image | Pulled from Docker Hub by the nodes at run time |
| (inherited, unused here) EBS CSI driver + `gp2` StorageClass | Installed at boot as in Week 10; not used by this lab |

## Prerequisites

- AWS Academy Learner Lab access — sign in at <https://www.awsacademy.com/vforcesite/LMS_Login>
- An EC2 **key pair** in the Learner Lab (AWS Console → EC2 → Key Pairs), `.pem` downloaded
- On your laptop: AWS CLI v2, Terraform, Git

## 1. Get your AWS credentials

Learner Lab page: **Start Lab** → wait for the green dot → **AWS Details → AWS CLI → Show**. Paste the
whole `[default]` block into `~/.aws/credentials`, set `region = us-east-1` in `~/.aws/config`.
Credentials rotate every session (~4 h) — re-paste each session. Verify: `aws sts get-caller-identity`.

## 2. Configure and apply

```bash
cd CLO835_week11_lab
cp terraform.tfvars.example terraform.tfvars   # set key_name to YOUR key pair
chmod 400 your-key.pem

terraform init
terraform apply        # type yes; wait ~3–5 min while the nodes self-configure
```

## 3. Verify, then run the lab

```bash
ssh -i your-key.pem ubuntu@<master public IP from terraform output>

kubectl get nodes -o wide          # masternode + workernode1 + workernode2, all Ready
ls ~/week11                        # fortune-env-cm.yaml  fortune-secret-env.yaml
```

Then follow **`commands.sh`** section by section next to the slides (`week11/Week11_lab.pptx`):
create the `fortune-config` ConfigMap and `fortune-secret` Secret from literals, inject each into a
`luksa/fortune:env` pod as an environment variable, and `printenv` to prove it. Everything lives in one
namespace (`week11`, the name the deck uses) so cleanup is a single command.

## 4. Cleanup

```bash
# on the master:
kubectl delete namespace week11        # removes the pods, ConfigMap and Secret

# then on your laptop:
terraform destroy                      # stops the $50 Learner Lab meter
```

> This lab creates **no** PVCs / EBS volumes, so `terraform destroy` alone is enough — unlike the Week 10
> lab, there is nothing to delete first.

## Files

| File | Purpose |
|---|---|
| `main.tf` / `variables.tf` / `terraform.tfvars.example` | The infrastructure (identical to Week 10, renamed `week11-*`) |
| `bootstrap.sh` | Every node: swap off, containerd, kubeadm/kubelet/kubectl v1.31 |
| `master-init.sh.tftpl` | Master: `kubeadm init`, Flannel, (inherited) EBS CSI + gp2, manifest staging |
| `worker-join.sh.tftpl` | Workers: retry `kubeadm join` until the API answers |
| `manifests/*.yaml` | The two workshop pods — staged to `~/week11/` on the master at boot |
| `commands.sh` | The Week 11 workshop commands, section by section |
