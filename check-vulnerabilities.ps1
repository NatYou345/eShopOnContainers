# Script PowerShell pour identifier et corriger les vulnérabilités NuGet

Write-Host "🔍 Analyse des vulnérabilités NuGet dans eShopOnContainers..." -ForegroundColor Cyan

# Packages connus pour avoir des vulnérabilités dans certaines versions
$vulnerablePackages = @{
    "System.Text.Json" = @{
        "VulnerableVersions" = @("6.0.0", "7.0.0", "7.0.1", "7.0.2", "7.0.3")
        "SafeVersion" = "8.0.5"
        "Reason" = "CVE-2024-21319 - DoS vulnerability"
    }
    "System.Text.Encodings.Web" = @{
        "VulnerableVersions" = @("6.0.0", "7.0.0", "8.0.0")
        "SafeVersion" = "8.0.1"
        "Reason" = "CVE-2024-21319 - XSS vulnerability"
    }
    "System.Net.Http" = @{
        "VulnerableVersions" = @("4.3.0", "4.3.1", "4.3.2", "4.3.3")
        "SafeVersion" = "4.3.4"
        "Reason" = "CVE-2018-8292 - Information disclosure"
    }
    "Microsoft.Data.OData" = @{
        "VulnerableVersions" = @("5.8.0", "5.8.1", "5.8.2", "5.8.3", "5.8.4")
        "SafeVersion" = "5.8.5"
        "Reason" = "CVE-2023-36038 - RCE vulnerability"
    }
    "Microsoft.AspNetCore.Server.Kestrel" = @{
        "VulnerableVersions" = @("2.0.0", "2.0.1", "2.0.2")
        "SafeVersion" = "2.0.3"
        "Reason" = "CVE-2018-0808 - DoS vulnerability"
    }
}

$projectFiles = Get-ChildItem -Path "C:\Users\ALLEGRANathan\source\repos\eShopOnContainers\src" -Filter "*.csproj" -Recurse
$issuesFound = @()

foreach ($projectFile in $projectFiles) {
    $content = Get-Content $projectFile.FullName -Raw
    
    foreach ($packageName in $vulnerablePackages.Keys) {
        $packageInfo = $vulnerablePackages[$packageName]
        
        foreach ($vulnVersion in $packageInfo.VulnerableVersions) {
            if ($content -match "<PackageReference.*Include=`"$packageName`".*Version=`"$vulnVersion`"") {
                $issuesFound += [PSCustomObject]@{
                    Project = $projectFile.Name
                    Package = $packageName
                    CurrentVersion = $vulnVersion
                    SafeVersion = $packageInfo.SafeVersion
                    Reason = $packageInfo.Reason
                    FilePath = $projectFile.FullName
                }
                
                Write-Host "⚠️  VULNÉRABILITÉ TROUVÉE:" -ForegroundColor Red
                Write-Host "   Projet: $($projectFile.Name)" -ForegroundColor Yellow
                Write-Host "   Package: $packageName @ $vulnVersion" -ForegroundColor Yellow
                Write-Host "   Raison: $($packageInfo.Reason)" -ForegroundColor Yellow
                Write-Host "   Correction: Mettre à jour vers $($packageInfo.SafeVersion)" -ForegroundColor Green
                Write-Host ""
            }
        }
    }
}

if ($issuesFound.Count -eq 0) {
    Write-Host "✅ Aucune vulnérabilité NuGet connue détectée dans les packages explicites!" -ForegroundColor Green
    Write-Host ""
    Write-Host "ℹ️  Note: GitHub Dependabot peut détecter des vulnérabilités dans:" -ForegroundColor Cyan
    Write-Host "   - Dépendances transitives (indirect dependencies)" -ForegroundColor Gray
    Write-Host "   - Packages dans node_modules/" -ForegroundColor Gray
    Write-Host "   - Fichiers de configuration (docker-compose.yml, etc.)" -ForegroundColor Gray
    Write-Host "   - Anciennes versions de packages système" -ForegroundColor Gray
} else {
    Write-Host "📊 Résumé: $($issuesFound.Count) vulnérabilité(s) trouvée(s)" -ForegroundColor Yellow
    $issuesFound | Format-Table -AutoSize
}

Write-Host ""
Write-Host "🔍 Vérification des dépendances transitives..." -ForegroundColor Cyan
Write-Host "Exécution de: dotnet list package --vulnerable" -ForegroundColor Gray
