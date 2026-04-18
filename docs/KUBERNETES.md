# PQC Platform - Kubernetes Deployment

Ce guide couvre le déploiement de la plateforme sur Kubernetes (optionnel).

## Prérequis

- Kubernetes 1.24+
- kubectl configuré
- Helm 3.10+ (optionnel)
- Docker registry accessible

## Architecture Kubernetes

```
Namespace: pqc-platform
  ├── Deployment: pqc-backend (3 replicas)
  ├── Deployment: pqc-frontend (2 replicas)
  ├── StatefulSet: postgres
  ├── StatefulSet: neo4j
  ├── StatefulSet: elasticsearch
  ├── Deployment: redis
  ├── Service: backend (ClusterIP)
  ├── Service: frontend (ClusterIP)
  ├── Service: postgres (ClusterIP)
  ├── Service: neo4j (ClusterIP)
  ├── Service: elasticsearch (ClusterIP)
  ├── Ingress: main-ingress
  ├── ConfigMap: app-config
  ├── Secret: app-secrets
  └── PersistentVolumeClaim: db-storage, cache-storage
```

## Déploiement Kubernetes

### 1. Créer le namespace

```bash
kubectl create namespace pqc-platform
```

### 2. Créer les secrets

```bash
# Générer les certificats
openssl genrsa -out server.key 2048
openssl req -new -x509 -key server.key -out server.crt -days 365 \
  -subj "/CN=pqc-platform.local"

# Créer le secret
kubectl create secret tls tls-secret \
  --cert=server.crt --key=server.key \
  -n pqc-platform

# Créer le secret pour les variables sensibles
kubectl create secret generic app-secrets \
  --from-literal=db-password=your-secure-password \
  --from-literal=vault-token=your-vault-token \
  --from-literal=jwt-secret=your-jwt-secret \
  -n pqc-platform
```

### 3. Créer le ConfigMap

```bash
kubectl create configmap app-config \
  --from-literal=env=production \
  --from-literal=log-level=info \
  -n pqc-platform
```

### 4. Déployer avec kubectl

```bash
# PersistentVolumes
kubectl apply -f k8s/01-volumes.yaml -n pqc-platform

# PostgreSQL
kubectl apply -f k8s/02-postgres.yaml -n pqc-platform
kubectl wait --for=condition=ready pod \
  -l app=postgres -n pqc-platform --timeout=300s

# Redis
kubectl apply -f k8s/03-redis.yaml -n pqc-platform

# Neo4j
kubectl apply -f k8s/04-neo4j.yaml -n pqc-platform
kubectl wait --for=condition=ready pod \
  -l app=neo4j -n pqc-platform --timeout=300s

# Elasticsearch
kubectl apply -f k8s/05-elasticsearch.yaml -n pqc-platform
kubectl wait --for=condition=ready pod \
  -l app=elasticsearch -n pqc-platform --timeout=300s

# Backend
kubectl apply -f k8s/06-backend.yaml -n pqc-platform
kubectl wait --for=condition=ready pod \
  -l app=pqc-backend -n pqc-platform --timeout=300s

# Frontend
kubectl apply -f k8s/07-frontend.yaml -n pqc-platform
kubectl wait --for=condition=ready pod \
  -l app=pqc-frontend -n pqc-platform --timeout=300s

# Ingress
kubectl apply -f k8s/08-ingress.yaml -n pqc-platform
```

### 5. Vérifier le déploiement

```bash
# Vérifier les pods
kubectl get pods -n pqc-platform

# Vérifier les services
kubectl get svc -n pqc-platform

# Vérifier l'ingress
kubectl get ingress -n pqc-platform

# Logs du backend
kubectl logs -f deployment/pqc-backend -n pqc-platform

# Accès au pod
kubectl exec -it deployment/pqc-backend -n pqc-platform -- /bin/sh
```

## Déploiement avec Helm (optionnel)

```bash
# Ajouter le repository (si disponible)
helm repo add pqc-platform https://charts.pqc-platform.io
helm repo update

# Installer la release
helm install pqc-platform pqc-platform/pqc-platform \
  --namespace pqc-platform \
  --create-namespace \
  --values values.yaml

# Mettre à jour
helm upgrade pqc-platform pqc-platform/pqc-platform \
  --namespace pqc-platform \
  --values values.yaml

# Supprimer
helm uninstall pqc-platform -n pqc-platform
```

## Fichiers Kubernetes

### Exemple: Backend Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pqc-backend
  namespace: pqc-platform
  labels:
    app: pqc-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pqc-backend
  template:
    metadata:
      labels:
        app: pqc-backend
    spec:
      containers:
      - name: backend
        image: pqc-platform/pqc-backend:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          value: "postgresql://pqc_user:$(DB_PASSWORD)@postgres:5432/pqc_inventory"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db-password
        - name: ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: env
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTPS
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTPS
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: tls
          mountPath: /etc/pqc/tls
          readOnly: true
      volumes:
      - name: tls
        secret:
          secretName: tls-secret
---
apiVersion: v1
kind: Service
metadata:
  name: pqc-backend
  namespace: pqc-platform
spec:
  selector:
    app: pqc-backend
  type: ClusterIP
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
```

## Scaling & High Availability

### Autoscaling

```bash
kubectl autoscale deployment pqc-backend \
  --min=3 --max=10 \
  --cpu-percent=80 \
  -n pqc-platform
```

### Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: pqc-backend-pdb
  namespace: pqc-platform
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: pqc-backend
```

## Monitoring

### Prometheus Integration

```bash
# Ajouter la scrape config
kubectl create configmap prometheus-config \
  --from-literal=pqc-platform.yaml='
- job_name: "pqc-platform"
  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names:
      - pqc-platform
  relabel_configs:
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    action: keep
    regex: true
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
    action: replace
    target_label: __metrics_path__
    regex: (.+)
' -n monitoring
```

## Troubleshooting

### Pods ne démarrent pas

```bash
# Vérifier l'état
kubectl describe pod <pod-name> -n pqc-platform

# Vérifier les logs
kubectl logs <pod-name> -n pqc-platform

# Vérifier les events
kubectl get events -n pqc-platform --sort-by='.lastTimestamp'
```

### Problèmes de connexion à la base de données

```bash
# Vérifier le DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup postgres.pqc-platform.svc.cluster.local

# Tester la connexion PostgreSQL
kubectl run -it --rm debug --image=postgres:15-alpine --restart=Never -- \
  psql -h postgres.pqc-platform -U pqc_user -d pqc_inventory
```

## Backup & Recovery

### Backup PostgreSQL

```bash
kubectl exec -it statefulset/postgres -n pqc-platform -- \
  pg_dump -U pqc_user pqc_inventory > backup.sql
```

### Restore PostgreSQL

```bash
kubectl exec -it statefulset/postgres -n pqc-platform -- \
  psql -U pqc_user pqc_inventory < backup.sql
```

## Production Checklist

- [ ] Certificats TLS valides configurés
- [ ] Secrets Kubernetes créés et sécurisés
- [ ] Network Policies configurées
- [ ] RBAC configuré
- [ ] Resource requests/limits définis
- [ ] Health checks configurés
- [ ] Monitoring et alerting en place
- [ ] Backup et recovery testés
- [ ] Autoscaling configuré
- [ ] Pod Disruption Budgets définis
- [ ] Logging centralisé
- [ ] Audit logging activé
