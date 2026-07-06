Cluster & Node Basics
bashkubectl cluster-info                        # API server / DNS endpoints
kubectl get nodes -o wide                   # node status, IP, OS, kernel, runtime
kubectl describe node <node>                # full node detail incl. Conditions, taints, capacity
kubectl get nodes --show-labels             # labels on each node
kubectl top nodes                           # CPU/mem usage (needs metrics-server)
Taints & tolerations (bit you with the registry pod):
bashkubectl describe node k8master | grep Taints
kubectl taint nodes k8master node-role.kubernetes.io/control-plane-   # REMOVE a taint (trailing -)
kubectl taint nodes k8master node-role.kubernetes.io/control-plane=:NoSchedule  # ADD it back
A pod needs a matching tolerations: entry to be schedulable on a tainted node — nodeName: alone does not bypass this.

Pods
bashkubectl get pods                            # current namespace
kubectl get pods -A                         # all namespaces
kubectl get pods -o wide                    # + node, IP
kubectl get pods -l app=hello-api           # filter by label
kubectl get pods -w                         # watch live changes
kubectl describe pod <pod>                  # Events section = root cause of most failures
kubectl logs <pod>                          # current container logs
kubectl logs <pod> -c <container>           # specific container (multi-container / init pods)
kubectl logs <pod> --previous               # logs from a crashed instance
kubectl logs -f <pod>                       # follow/stream
kubectl logs -l app=hello-api               # logs by label (all matching pods)
kubectl exec -it <pod> -- bash              # shell into a pod
kubectl delete pod <pod>                    # force recreation (if managed by a Deployment)
kubectl delete pod <pod> --force --grace-period=0   # kill stuck pod immediately
Diagnosing Pending: check describe pod Events — usually taints, insufficient resources, or no matching node.
Diagnosing ImagePullBackOff: check describe pod Events for the exact pull error (TLS, DNS, auth, not-found) — crictl pull <image> on the node reproduces the same error without the Kubernetes wrapper.
Diagnosing CrashLoopBackOff: kubectl logs <pod> --previous almost always has the real reason.

Deployments & ReplicaSets
bashkubectl get deployments
kubectl describe deployment <name>
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment <name>
kubectl rollout history deployment <name>
kubectl rollout undo deployment <name>              # roll back to previous version
kubectl rollout restart deployment <name>           # force pods to recreate (e.g. after ConfigMap change)
kubectl set image deployment/<name> <container>=<image>:<tag>   # update image in place
kubectl delete deployment <name>

Services & Networking
bashkubectl get svc
kubectl describe svc <name>
kubectl get endpoints <svc-name>            # empty = selector doesn't match any pod labels (common bug)
Service types quick reference:
TypeReachable fromUse caseClusterIP (default)inside cluster onlypod-to-pod, pod-to-serviceNodePortany node's IP, on a high port (30000-32767)quick external testing (what you used)LoadBalancerexternal LB (needs cloud/metallb)production external access
bashkubectl get svc <name> -o jsonpath='{.spec.ports[0].nodePort}'   # get the actual NodePort
kubectl get svc <name> -o jsonpath='{.spec.clusterIP}'           # get the ClusterIP
Test connectivity, in order of isolation (cheapest to diagnose first):
bashPOD_IP=$(kubectl get pod -l app=<label> -o jsonpath='{.items[0].status.podIP}')
curl http://$POD_IP:<containerPort>          # 1. pod directly — proves app + CNI work
curl http://<clusterIP>:<port>               # 2. via Service internally — proves kube-proxy/iptables
curl http://<node-ip>:<nodePort>             # 3. via NodePort externally — proves node-level routing

ConfigMaps & Secrets
bashkubectl create configmap <name> --from-file=<key>=<path>
kubectl create configmap <name> --from-literal=key=value
kubectl get configmap <name> -o yaml
kubectl get configmap <name> -o jsonpath='{.data.<key>}'    # read one key's raw content
kubectl delete configmap <name>
kubectl edit configmap <name>                               # live-edit (e.g. kube-proxy conntrack fix)

ConfigMaps have a 1MiB size limit — fat jars/binaries need a hostPath volume or an actual registry, not a ConfigMap mount.

bashkubectl create secret generic <name> --from-literal=key=value
kubectl get secrets
kubectl describe secret <name>

Namespaces
bashkubectl get namespaces
kubectl get pods -n kube-system
kubectl config set-context --current --namespace=<ns>       # switch default namespace for kubectl

Jobs (Kaniko-style one-shot builds)
bashkubectl apply -f job.yaml
kubectl get pods -l job-name=<job-name> -w
kubectl logs -f job/<job-name>
kubectl delete job <job-name>                # ALWAYS delete before reapplying — Jobs don't self-clean

Applying / Editing Resources
bashkubectl apply -f file.yaml                   # create or update
kubectl delete -f file.yaml
kubectl get <resource> <name> -o yaml        # dump full current definition
kubectl edit <resource> <name>               # live edit in $EDITOR
kubectl diff -f file.yaml                    # preview what apply would change
kubectl explain <resource>.<field>           # inline docs, e.g. kubectl explain pod.spec.tolerations

Debugging & Events
bashkubectl get events -A --sort-by='.lastTimestamp'      # cluster-wide event timeline, newest last
kubectl describe <resource> <name>                     # Events section = #1 debugging tool
kubectl get all -A                                      # everything, everywhere
kubectl api-resources                                   # list all resource types kubectl knows about

Node-level tools (via lxc exec, bypasses Kubernetes entirely)
bashlxc exec <node> -- crictl ps                 # running containers on that node (containerd view)
lxc exec <node> -- crictl images             # images cached on that node
lxc exec <node> -- crictl pull <image>       # reproduce a pull error directly
lxc exec <node> -- crictl logs <container>   # container logs at containerd level
lxc exec <node> -- systemctl status kubelet
lxc exec <node> -- systemctl status containerd
lxc exec <node> -- journalctl -u kubelet -f  # live kubelet logs

kubeadm-specific
bashkubeadm token create --print-join-command    # generate a fresh join command
kubeadm token list                           # active tokens
kubectl get nodes                            # confirm join succeeded
kubeadm reset                                # tear down this node's kubeadm state (careful!)
