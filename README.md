# kubectl-csm-diag

This repository hosts the [kubectl plugin](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/) to capture all the information to debug [Dell CSI/CSM](https://dell.github.io/csm-docs/docs/).


It is inspired by Log3.sh created by [@OA72280](https://github.com/OA72280).

To obtain the script and make it working you can run:
```shell
curl -LO https://raw.githubusercontent.com/coulof/kubectl-csm-diag/main/kubectl-csm-diag && chmod +x kubectl-csm-diag
sudo mv kubectl-csm-diag /usr/local/bin
```

To run the script just execute:
```
kubectl-csm-diag
```

Or with all the options

```
kubectl-csm-diag --namespace dell-csm-operator,powerflex -s -v
```

## Archive content
The script create an archive (zip or tar) containing:
* The list of pods : pods-list.log
* Pods and container logs for the matching namespaces
* `storage.dell.com` CRs
* Helm `values.yaml`
* `StorageClass`, `Node` & `CSINodes` details
* `Secrets` containing the configuration to the storage backend ; only if the option `-s` is explicitly called

## TODO
* [x] Add command options parsing
* [ ] Replace selection by namespace with a selector. Need to find a selector to identify CSI Drivers...
