# Access

## lab-01

```powershell
ssh student@<HOST_IP> -p 32001
```

Inside the SSH session:

```bash
cat ~/task.md
kubectl get pods -A
```

Expected files:

```text
/home/student/.kube/config
/home/student/task.md
```

The kubeconfig points only to the `lab-01` vCluster.

## lab-02

```powershell
ssh student@<HOST_IP> -p 32002
```

Inside the SSH session:

```bash
cat ~/task.md
kubectl get pods -A
```

## lab-03

```powershell
ssh student@<HOST_IP> -p 32003
```

Inside the SSH session:

```bash
cat ~/task.md
kubectl get pods -A
```
