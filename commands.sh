#!/bin/bash
# CLO835 — Week 11 lab commands (ConfigMaps & Secrets).
#
# Run these ON THE MASTER, section by section, alongside the slides.
# Do NOT run the whole file at once.
#
# Same self-forming cluster as the Week 10 lab. This workshop needs ONLY a
# running cluster + kubectl + the luksa/fortune:env image — no storage, no
# dashboard. (The EBS CSI driver and gp2 StorageClass are inherited from the
# Week 10 setup but this lab does not use them.)
#
# Everything lives in ONE namespace called "week11" so cleanup is a single
# command. The lab manifests are staged in ~/week11/ on the master.
#
# alias k=kubectl   # optional

########################################################
# 0) Verify the cluster
########################################################
kubectl get nodes -o wide            # masternode + workernode1 + workernode2, all Ready
ls ~/week11                          # fortune-env-cm.yaml  fortune-secret-env.yaml

########################################################
# Step 1 · Create a ConfigMap (non-sensitive config, plain-text key/value)
########################################################
kubectl create namespace week11

kubectl create configmap fortune-config \
    --from-literal=sleep-interval=25 \
    --from-literal=sky-color=blue \
    -n week11

# Inspect what was stored — values are plain text
kubectl get cm fortune-config -n week11 -o yaml

########################################################
# Step 2 · Inject the ConfigMap as an env var (configMapKeyRef)
########################################################
kubectl apply -f ~/week11/fortune-env-cm.yaml -n week11
kubectl get pod fortune-env-cm -n week11        # Running

# The ConfigMap value 'sleep-interval' is now the container env var INTERVAL
kubectl exec fortune-env-cm -n week11 -- printenv INTERVAL     # -> 25

########################################################
# Step 3 · Create a Secret (sensitive data, stored base64-encoded)
########################################################
kubectl create secret generic fortune-secret \
    --from-literal=api-key=s3cr3t-value \
    -n week11

# The value is base64-encoded, not plain text like a ConfigMap
kubectl get secret fortune-secret -n week11 -o yaml
#   data.api-key: czNjcjN0LXZhbHVl
#   echo czNjcjN0LXZhbHVl | base64 -d   ->  s3cr3t-value
#   (base64 is ENCODING, not encryption — anyone with API access can decode it)

########################################################
# Step 4 · Inject the Secret as an env var (secretKeyRef)
########################################################
kubectl apply -f ~/week11/fortune-secret-env.yaml -n week11
kubectl get pod fortune-secret-env -n week11    # Running

# Kubernetes decodes the Secret and exposes it as a plain env var
kubectl exec fortune-secret-env -n week11 -- printenv API_KEY  # -> s3cr3t-value

########################################################
# ConfigMap vs Secret — same consumption API
########################################################
# ConfigMap: non-sensitive (intervals, URLs, flags); plain text; configMapKeyRef.
# Secret:    sensitive (keys, passwords, TLS); base64 type: Opaque; secretKeyRef.
# A Pod reads either one the same way — swap configMapKeyRef for secretKeyRef.

########################################################
# Cleanup — one command removes the pods, the ConfigMap and the Secret
########################################################
kubectl delete namespace week11

# Then, on your LAPTOP, from the CLO835_week11_lab folder:
#   terraform destroy          # stops the $50 Learner Lab meter
# (No PVCs/EBS volumes were created in this lab, so terraform destroy alone
#  is enough — unlike the Week 10 lab.)
