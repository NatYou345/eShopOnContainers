# ⚠️ État des Corrections - Mise à Jour Packages et Compilation

**Date**: Janvier 2026  
**Status**: 🟡 PARTIELLEMENT COMPLÉTÉ - Nécessite Actions Additionnelles

---

## 📊 Résumé de la Situation

### ✅ Ce qui a Été Fait

1. **Packages NuGet Mis à Jour** (via dotnet-outdated --upgrade):
   - Catalog.API: 19 packages mis à jour
   - EventBusRabbitMQ: 1 package (RabbitMQ.Client)
   - Swashbuckle: 6.9.0 → 10.1.5 ✅
   - Entity Framework Core: 9.0.0 → 10.0.3 ✅
   - ASP.NET Core: 9.0.0 → 10.0.3 ✅
   - Serilog: 9.0.0 → 10.0.0 ✅

2. **Vulnerabilités Corrigées**:
   - Azure.Messaging.ServiceBus: 7.17.4 → 7.18.1 ✅
   - Microsoft.Data.SqlClient ajouté (remplace System.Data.SqlClient)
   - Directory.Build.targets créé avec security overrides

3. **Fichiers Restaurés**:
   - Catalog.API.csproj recréé après corruption ✅
   - CatalogContextSeed.cs usings ajoutés ✅
   - WebHostExtensions.cs usings ajoutés ✅

### ❌ Problèmes Restants (20+ erreurs de compilation)

#### Catégorie 1: Microsoft.OpenApi.Models (12 erreurs)

**Symptôme**: `CS0234: The type or namespace name 'Models' does not exist`

**Projets Affectés** (6):
- Basket.API
- Ordering.API
- Webhooks.API
- Web.Shopping.HttpAggregator
- Mobile.Shopping.HttpAggregator

**Cause**: Microsoft.OpenApi 2.4.1 est référencé via Directory.Build.targets mais:
- Pas de `<PackageReference Include="Microsoft.OpenApi" />` explicite dans les projets
- Les GlobalUsings.cs essaient d'utiliser Microsoft.OpenApi.Models
- Swashbuckle 10.1.5 utilise Microsoft.OpenApi 2.4.1 internalement

**Solution Nécessaire**:
```bash
# Pour chaque projet affecté:
dotnet add Services/Basket/Basket.API package Microsoft.OpenApi --version 2.4.1
dotnet add Services/Ordering/Ordering.API package Microsoft.OpenApi --version 2.4.1
dotnet add Services/Webhooks/Webhooks.API package Microsoft.OpenApi --version 2.4.1
dotnet add ApiGateways/Web.Bff.Shopping/aggregator package Microsoft.OpenApi --version 2.4.1
dotnet add ApiGateways/Mobile.Bff.Shopping/aggregator package Microsoft.OpenApi --version 2.4.1
```

**OU**: Enlever Directory.Build.targets qui bloque l'ajout

#### Catégorie 2: RabbitMQ Health Check API Change (3 erreurs)

**Symptôme**: `CS1503: cannot convert from 'string' to 'Func<IServiceProvider, IConnection>?'`

**Projets Affectés** (3):
- Payment.API
- Ordering.SignalrHub
- Ordering.BackgroundTasks

**Cause**: AspNetCore.HealthChecks.Rabbitmq 9.0.0 a changé son API:
```csharp
// Ancien (ne marche plus):
.AddRabbitMQ($"amqp://{host}", name: "...", tags: ...)

// Nouveau:
.AddRabbitMQ(sp => connectionFactory, name: "...", tags: ...)
```

**Solution Nécessaire**: Adapter chaque call pour fournir une Func:
```csharp
hcBuilder.AddRabbitMQ(
    sp =>
    {
        var factory = new ConnectionFactory() 
        { 
            HostName = configuration["EventBusConnection"],
            UserName = configuration["EventBusUserName"] ?? "guest",
            Password = configuration["EventBusPassword"] ?? "guest"
        };
        return factory.CreateConnectionAsync().GetAwaiter().GetResult();
    },
    name: "payment-rabbitmqbus-check",
    tags: new string[] { "rabbitmqbus" }
);
```

---

## 🎯 Actions Requises pour Compilation Complète

### Action 1: Choisir Stratégie pour Microsoft.OpenApi

**Option A**: Supprimer Directory.Build.targets (recommandé pour simplifier):
```bash
rm src/Directory.Build.targets
```
Puis ajouter Microsoft.OpenApi 2.4.1 dans chaque projet manuellement.

**Option B**: Garder Directory.Build.targets mais ajouter `<PackageReference Include="Microsoft.OpenApi" />` explicitement dans les 5 projets affectés (sans version, elle sera prise du .targets)

**Je recommande Option A** car plus simple et moins de confusion.

### Action 2: Corriger les 3 Appels RabbitMQ Health Check

Fichiers à modifier:
1. `src/Services/Payment/Payment.API/Startup.cs` (ligne 170)
2. `src/Services/Ordering/Ordering.SignalrHub/Startup.cs` (ligne 248)
3. `src/Services/Ordering/Ordering.BackgroundTasks/Extensions/CustomExtensionMethods.cs` (ligne 40)

Remplacement:
```csharp
// Remplacer:
.AddRabbitMQ(
    $"amqp://{configuration["EventBusConnection"]}",
    name: "xxx",
    tags: ...)

// Par:
.AddRabbitMQ(
    sp =>
    {
        var cfg = sp.GetRequiredService<IConfiguration>();
        var factory = new ConnectionFactory()
        {
            HostName = cfg["EventBusConnection"],
            UserName = cfg["EventBusUserName"] ?? "guest",
            Password = cfg["EventBusPassword"] ?? "guest"
        };
        return factory.CreateConnectionAsync().GetAwaiter().GetResult();
    },
    name: "xxx",
    tags: ...)
```

---

## 📈 Statistiques Actuelles

| Métrique | Avant | Maintenant | Target |
|----------|-------|------------|--------|
| Packages Upgradés | ~50 | ~120 | ALL |
| Erreurs Compilation | 0 | 20 | 0 |
| Vulnérabilités (détectées) | 45 | ?  (non re-scanné) | 0 |
| RabbitMQ.Client | 7.2.1 puis 6.8.1 | 6.8.1 | 6.8.1 (stable) |
| Swashbuckle | 6.9.0 | 10.1.5 | 10.1.5 ✅ |
| EF Core | 9.0.0 | 10.0.3 | 10.0.3 ✅ |
| ASP.NET Core | 9.0.0 | 10.0.3 | 10.0.3 ✅ |

---

## 🚧 Pourquoi C'est Compliqué

### Problème: Breaking Changes Multiples

1. **Swashbuckle 6.x → 10.x**: 
   - Requiert Microsoft.OpenApi 2.x (was 1.x)
   - Interface IOperationFilter peut avoir changé

2. **RabbitMQ.Client 6.x → 7.x**:
   - IModel → IChannel
   - CreateModel() → CreateChannel()
   - Event API complètement changée
   - Mais AspNetCore.HealthChecks.Rabbitmq 9.0 suppose 7.x

3. **EF Core 9.x → 10.x**:
   - Versions doivent matcher entre projets
   - IntegrationEventLogEF force 10.0.3

### Conflit: Directory.Build.targets

Le fichier Directory.Build.targets que j'ai créé pour les sécurités empêche l'ajout manuel de packages via `dotnet add`. Cela complique l'ajout de Microsoft.OpenApi.

---

## 💡 Recommandations

### Scénario 1: Simplification (RECOMMANDÉ)

**Objectif**: Revenir à des versions stables, corriger vulnérabilités critiques uniquement

**Actions**:
1. Supprimer Directory.Build.targets
2. Downgrade Swashbuckle: 10.1.5 → 6.9.0 (version stable)
3. Garder RabbitMQ.Client 6.8.1
4. Garder EF Core 10.0.3
5. Garder ASP.NET Core 10.0.3
6. Ajouter seulement les overrides de sécurité critiques dans projets individuels

**Avantages**:
- ✅ Moins de breaking changes
- ✅ Compile rapidement
- ✅ Vulnérabilités critiques corrigées

**Inconvénients**:
- ❌ Swashbuckle pas à la dernière version (6.9.0 vs 10.1.5)

### Scénario 2: Modernisation Complète (COMPLEXE)

**Objectif**: Utiliser les dernières versions, corriger tous les breaking changes

**Actions**:
1. Supprimer Directory.Build.targets
2. Ajouter Microsoft.OpenApi 2.4.1 à tous les projets
3. Mettre à jour RabbitMQ.Client vers 7.2.1
4. Migrer tout le code RabbitMQ (IModel→IChannel, events, etc)
5. Corriger les 3 appels RabbitMQ health checks
6. Tester exhaustivement

**Avantages**:
- ✅ Packages les plus récents
- ✅ Toutes les dernières features

**Inconvénients**:
- ❌ 50+ lignes de code à modifier
- ❌ Risque de régression
- ❌ Tests approfondis nécessaires

---

## 🎯 Ma Recommandation: Scénario 1

**Je recommande le Scénario 1** car:
- Plus rapide à implémenter
- Moins de risque
- Swashbuckle 6.9.0 est parfaitement fonctionnel
- RabbitMQ 6.8.1 est stable
- Les packages critiques (EF Core, ASP.NET Core) sont à jour

**Temps estimé**:
- Scénario 1: 15-30 minutes
- Scénario 2: 2-3 heures + tests approfondis

---

## 📝 Prochaines Actions (Scénario 1)

### Étape 1: Cleanup
```bash
rm src/Directory.Build.targets
```

### Étape 2: Downgrade Swashbuckle
```bash
dotnet tool install --global dotnet-outdated-tool
cd src
dotnet-outdated --downgrade --to-version 6.9.0 Swashbuckle.AspNetCore
```

### Étape 3: Build & Test
```bash
dotnet build src/eShopOnContainers-ServicesAndWebApps.sln --configuration Release
dotnet test src/eShopOnContainers-ServicesAndWebApps.sln --configuration Release
```

### Étape 4: Re-scan Vulnerabilities
```bash
dotnet list package --vulnerable --include-transitive
```

---

**Question pour l'utilisateur**: Quel scénario préfères-tu?

**Scénario 1** (Simplification - 30 min) ou **Scénario 2** (Modernisation complète - 3h)?
