# 🎯 Prochaines Étapes - Déploiement .NET 10

## ✅ Étapes Complétées

### 1. ✅ Merge vers `dev` - COMPLÉTÉ
La branche `upgrade-to-NET10` a été mergée avec succès dans `dev`.

**Commit merge**: Merge branch 'upgrade-to-NET10' - Complete .NET 10 validation and upgrade

### 2. ✅ Push du tag - COMPLÉTÉ
Le tag `v1.0.0-net10` a été poussé vers le remote GitHub.

**Tag**: `v1.0.0-net10`  
**URL**: https://github.com/NatYou345/eShopOnContainers/releases/tag/v1.0.0-net10

---

## 📋 Étapes Restantes (Nécessitent Action Manuelle)

### 3. ⏳ Mettre à Jour CI/CD

**Actions requises**:

#### GitHub Actions
```yaml
# Dans .github/workflows/*.yml
# Mettre à jour toutes les actions pour utiliser .NET 10 SDK

- name: Setup .NET
  uses: actions/setup-dotnet@v3
  with:
    dotnet-version: '10.0.x'  # ← Mettre à jour de 7.0.x à 10.0.x
```

#### Azure DevOps Pipelines (si utilisé)
```yaml
# Dans azure-pipelines.yml
pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'
  dotnetSdkVersion: '10.0.x'  # ← Mettre à jour

steps:
- task: UseDotNet@2
  inputs:
    version: '$(dotnetSdkVersion)'
```

#### Docker Build Agents
- Installer .NET 10 SDK sur tous les agents de build
- Mettre à jour les images Docker des agents si applicable
- Vérifier que Docker supporte les images .NET 10.0

**Vérification**:
```bash
# Sur chaque agent de build
dotnet --list-sdks
# Doit afficher: 10.0.xxx

# Tester un build
dotnet build src/eShopOnContainers-ServicesAndWebApps.sln
```

---

### 4. ⏳ Tests en Staging

**Prérequis**:
- SQL Server 2019+ accessible
- RabbitMQ 3.12+ ou Azure Service Bus
- Redis 7.0+ 
- Docker Engine avec support .NET 10

#### A. Docker Compose Local

```bash
cd src
docker-compose build
docker-compose up -d
```

**Vérifications**:
1. Tous les services démarrent sans erreur
2. Health checks passent: http://localhost:5107/
3. Tester les endpoints:
   - Web MVC: http://localhost:5100/
   - Web SPA: http://localhost:5104/
   - API Status: http://localhost:5107/

#### B. Tests Fonctionnels

```bash
# Exécuter tous les tests
dotnet test src/eShopOnContainers-ServicesAndWebApps.sln --configuration Release

# Tests spécifiques
dotnet test src/Services/Basket/Basket.FunctionalTests/
dotnet test src/Services/Catalog/Catalog.FunctionalTests/
dotnet test src/Services/Ordering/Ordering.FunctionalTests/
```

**Scénarios à valider**:
- [ ] Authentification utilisateur (Identity.API)
- [ ] Ajout au panier (Basket.API)
- [ ] Catalogue produits (Catalog.API)
- [ ] Passage de commande (Ordering.API)
- [ ] Paiement (Payment.API)
- [ ] Webhooks (Webhooks.API)
- [ ] Notifications temps réel (Ordering.SignalrHub)

#### C. Kubernetes Local (Optionnel)

```bash
# Si vous utilisez Kubernetes
kubectl apply -f k8s/
kubectl get pods
kubectl get services
```

---

### 5. ⏳ Performance Baseline

**Objectif**: S'assurer qu'il n'y a pas de régression de performance

#### Outils Recommandés

**Option A: k6 (Load Testing)**
```bash
# Installer k6
choco install k6  # Windows
brew install k6   # macOS

# Script de test simple
cat > load-test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 0 },   // Ramp down
  ],
};

export default function () {
  let response = http.get('http://localhost:5100');
  check(response, { 'status was 200': (r) => r.status == 200 });
  sleep(1);
}
EOF

# Exécuter le test
k6 run load-test.js
```

**Option B: dotnet-counters**
```bash
# Installer l'outil
dotnet tool install --global dotnet-counters

# Monitorer un processus
dotnet-counters monitor --process-id <PID> \
  --counters System.Runtime,Microsoft.AspNetCore.Hosting
```

**Métriques à surveiller**:
- Latence P50, P95, P99
- Throughput (req/sec)
- Utilisation mémoire
- Utilisation CPU
- Garbage Collection (Gen0, Gen1, Gen2)

---

### 6. ⏳ Déploiement Production

#### Stratégie Recommandée: Blue-Green Deployment

**Étape 1: Déployer en "Green" (nouvelle version)**
```bash
# Azure Kubernetes Service (AKS)
az aks get-credentials --resource-group <rg> --name <cluster>
kubectl apply -f k8s/ --namespace green

# Attendre que tous les pods soient ready
kubectl wait --for=condition=ready pod -l app=eshop --namespace green --timeout=300s
```

**Étape 2: Tests Smoke en Green**
```bash
# Tester les endpoints Green
curl https://green.eshop.example.com/health
curl https://green.eshop.example.com/api/catalog/items
```

**Étape 3: Basculer le Trafic (si tests OK)**
```bash
# Mettre à jour le LoadBalancer/Ingress
kubectl patch service eshop-ingress -p '{"spec":{"selector":{"version":"green"}}}'
```

**Étape 4: Monitorer**
- Application Insights
- Azure Monitor / Prometheus
- Health checks continus

**Étape 5: Rollback si Problème**
```bash
# Revenir sur Blue (ancienne version)
kubectl patch service eshop-ingress -p '{"spec":{"selector":{"version":"blue"}}}'
```

---

## 📊 Checklist de Validation

### Avant Production
- [ ] CI/CD pipelines mis à jour et validés
- [ ] Tests en staging 100% passés
- [ ] Performance baseline validée (pas de régression)
- [ ] Health checks configurés et fonctionnels
- [ ] Logs et monitoring en place (Application Insights)
- [ ] Plan de rollback testé
- [ ] Documentation mise à jour

### Monitoring Post-Déploiement (24-48h)
- [ ] Vérifier les métriques Application Insights
- [ ] Surveiller les logs d'erreurs
- [ ] Valider les temps de réponse
- [ ] Vérifier l'utilisation des ressources (CPU/RAM)
- [ ] Tester les flux critiques utilisateurs
- [ ] Surveiller les alertes

---

## 🆘 Support & Troubleshooting

### Problèmes Courants

**Problème**: Services ne démarrent pas dans Docker
```bash
# Vérifier les logs
docker-compose logs -f <service-name>

# Rebuild si nécessaire
docker-compose build --no-cache <service-name>
```

**Problème**: Tests fonctionnels échouent
```bash
# Vérifier que l'infrastructure est disponible
docker ps  # SQL Server, RabbitMQ, Redis doivent être running

# Vérifier les connection strings dans appsettings.json
```

**Problème**: Performance dégradée
```bash
# Profiler avec dotnet-trace
dotnet tool install --global dotnet-trace
dotnet-trace collect --process-id <PID>

# Analyser avec PerfView ou dotnet-trace
```

---

## 📞 Contacts

**Pour Questions Techniques**:
- GitHub Issues: https://github.com/NatYou345/eShopOnContainers/issues
- Documentation .NET 10: https://docs.microsoft.com/dotnet/core/whats-new/dotnet-10

**Pour Urgences Production**:
- (Ajouter contacts équipe DevOps/SRE)

---

## 📚 Ressources

- [.NET 10 Release Notes](https://github.com/dotnet/core/releases/tag/v10.0.0)
- [Breaking Changes .NET 10](https://docs.microsoft.com/dotnet/core/compatibility/10.0)
- [Azure AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Docker .NET 10 Images](https://hub.docker.com/_/microsoft-dotnet)

---

**Dernière mise à jour**: Janvier 2026  
**Version**: v1.0.0-net10  
**Status**: ✅ Prêt pour CI/CD et Staging
