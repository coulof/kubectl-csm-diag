# kubectl-csm-diag

This repository hosts the [kubectl plugin](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/) to capture all the information to debug [Dell CSI/CSM](https://dell.github.io/csm-docs/docs/).


It is inspired by Log3.sh created by [@OA72280](https://github.com/OA72280).

To run the script just execute:
```
kubectl-csm-diag
```

Or

```
kubectl-csm-diag --namespace dell-csm-operator,powerflex
```

## Archive content
The script create an archive (zip or tar) containing:
* The list of pods : pods-list.log
* Pods and container logs for the matching namespaces
* `storage.dell.com` CRs
* Helm `values.yaml`
* `StorageClass`, `Node` & `CSINodes` details

## TODO
* [x] Add command options parsing
* [ ] Replace selection by namespace with a selector. Need to find a selector to identify CSI Drivers...