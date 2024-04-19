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

## TODO
* [] Add command options parsing
* [] Find a selector to identify CSI Drivers
