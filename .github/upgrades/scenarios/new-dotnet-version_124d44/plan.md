# .NET 10 Upgrade Plan for eShopOnContainers

## Executive Summary

### Overview
This plan documents the upgrade validation for **eShopOnContainers** on **.NET 10** (Long Term Support). The solution contains **31 projects** across a microservices architecture.

### Current State
- **Target Framework**: net10.0 (already targeting .NET 10)
- **Total Projects**: 31 (10 APIs, 3 Web apps, 9 libraries, 9 test projects)
- **NuGet Packages**: 118 packages
- **Architecture**: Microservices with RabbitMQ/Azure Service Bus

### Assessment Results
- **? Zero compatibility issues detected**
- **? All 118 NuGet packages are compatible with .NET 10**
- **? No breaking changes identified**

### Risk Level
**?? LOW** - Solution already targets .NET 10, all dependencies compatible.

### Timeline Estimate
Total: 6-9 hours (validation and testing)

---

## Migration Strategy

### Selected Approach: Bottom-Up Dependency-Ordered Validation

#### Phase 1: Environment Preparation
- Validate .NET 10 SDK installation
- Check global.json for SDK constraints
- Verify Docker base images

#### Phase 2: Dependency Layer Validation
**Level 0**: Foundation projects (EventBus, Ordering.Domain, etc.)  
**Level 1**: Intermediate libraries (EventBusRabbitMQ, etc.)  
**Level 2**: Service layer (APIs)  
**Level 3**: Test projects

#### Phase 3: Integration & System Testing
- Run all test projects
- Validate Docker Compose
- Execute health checks

#### Phase 4: Documentation
- Update README and deployment guides
- Tag release

---

## Detailed Dependency Analysis

### Package Compatibility: 118/118 ?

**Key Dependencies**:
- ASP.NET Core 8.0.3, 9.0.0 ?
- Entity Framework Core 9.0.0 ?
- RabbitMQ.Client 6.8.1 ?
- Duende.IdentityServer 7.0.10 ?
- xUnit 2.7.0, 2.9.3 ?
- MediatR 12.2.0 - 14.0.0 ?

### Project Dependency Graph

```
Level 0: EventBus, Ordering.Domain, Identity.API, etc. (9 projects)
Level 1: EventBusRabbitMQ, Ordering.Infrastructure, etc. (7 projects)
Level 2: Basket.API, Catalog.API, Ordering.API, etc. (8 projects)
Level 3: All test projects (7 projects)
```

---

## Project-by-Project Plans

All 31 projects already target net10.0 with zero issues.

### Validation Actions Per Level

**Level 0-3**: Build, test, validate dependencies

**Risk**: ?? None to Low

---

## Risk Management

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Build Failures | ?? Very Low | Low | Projects already on .NET 10 |
| Test Failures | ?? Very Low | Medium | Comprehensive test suite |
| Docker Issues | ?? Low | Medium | Validate base images |

---

## Testing & Validation Strategy

### Test Phases

1. **Unit Tests**: All xUnit projects, 100% pass rate
2. **Functional Tests**: API endpoints, database integration
3. **System Integration**: Docker Compose, health checks
4. **Performance Baseline**: Monitor metrics

---

## Complexity & Effort Assessment

### Overall: ?? LOW

| Phase | Time | Complexity |
|-------|------|-----------|
| Environment | 1-2h | ?? Simple |
| Build & Test | 4-6h | ?? Moderate |
| Integration | 2-3h | ?? Moderate |
| Docs | 1h | ?? Simple |

**Total**: 10-15 hours (parallelizable to 4-6 hours)

---

## Source Control Strategy

- **Source**: `dev`
- **Upgrade**: `upgrade-to-NET10`
- **Workflow**: Validate ? PR ? Tag release

### PR Checklist
- [ ] All projects build
- [ ] All tests pass
- [ ] Docker validated
- [ ] Docs updated

---

## Success Criteria

### Must Pass
- [ ] All 31 projects compile
- [ ] 100% test pass rate
- [ ] Docker Compose works
- [ ] Health checks pass
- [ ] Documentation updated

---

## Key Commands

```bash
# Build
dotnet build src/eShopOnContainers-ServicesAndWebApps.sln

# Test
dotnet test src/eShopOnContainers-ServicesAndWebApps.sln

# Docker
docker-compose up -d

# SDK Check
dotnet --list-sdks
```

---

## Conclusion

Low-risk validation effort. Projects already on .NET 10 with full package compatibility.

**Next Steps**: Proceed to Execution Phase

---

*Plan Generated*: January 2025  
*Target*: .NET 10 (LTS)  
*Projects*: 31
