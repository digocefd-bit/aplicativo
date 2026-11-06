import '../models/models.dart';

class RotationService {
  static String? suggestNextSite({
    required RouteType route,
    required List<InjectionSite> sites,
    required List<ApplicationRecord> applications,
    required Protocol protocol,
  }) {
    // Filtrar locais ativos da rota correta
    final routeSites = sites
        .where((s) => s.active && s.route == route)
        .toList();

    if (routeSites.isEmpty) return null;

    // Ordenar por nome
    routeSites.sort((a, b) => a.name.compareTo(b.name));

    // Encontrar último local usado para este protocolo
    final appliedApps = applications
        .where((a) =>
            a.protocolId == protocol.id &&
            a.status == ApplicationStatus.applied &&
            a.siteId != null &&
            a.siteId!.trim().isNotEmpty)
        .toList();

    if (appliedApps.isEmpty) {
      return routeSites.first.id;
    }

    // Ordenar por data de aplicação (mais recente primeiro)
    appliedApps.sort((a, b) => b.appliedAt!.compareTo(a.appliedAt!));
    final lastUsedSiteId = appliedApps.first.siteId;

    // Encontrar o próximo local na rotação (round-robin)
    final lastIndex = routeSites.indexWhere((s) => s.id == lastUsedSiteId);
    if (lastIndex == -1) {
      return routeSites.first.id;
    }

    final nextIndex = (lastIndex + 1) % routeSites.length;
    return routeSites[nextIndex].id;
  }

  static List<InjectionSite> getAvailableSites({
    required RouteType route,
    required List<InjectionSite> sites,
  }) {
    return sites
        .where((s) => s.active && s.route == route)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<InjectionSite> getDefaultSites() {
    return [
      // SC - Subcutânea
      const InjectionSite(id: 'sc_abdomen', name: 'Abdome', shortName: 'ABD', route: RouteType.sc, cooldownDays: 7),
      const InjectionSite(id: 'sc_thigh_l', name: 'Coxa Esquerda', shortName: 'CX-E', route: RouteType.sc, cooldownDays: 7),
      const InjectionSite(id: 'sc_thigh_r', name: 'Coxa Direita', shortName: 'CX-D', route: RouteType.sc, cooldownDays: 7),
      const InjectionSite(id: 'sc_arm_l', name: 'Braco Esquerdo', shortName: 'BR-E', route: RouteType.sc, cooldownDays: 7),
      const InjectionSite(id: 'sc_arm_r', name: 'Braco Direito', shortName: 'BR-D', route: RouteType.sc, cooldownDays: 7),

      // IM - Intramuscular
      const InjectionSite(id: 'im_glute_l', name: 'Gluteo Esquerdo', shortName: 'GL-E', route: RouteType.im, cooldownDays: 14),
      const InjectionSite(id: 'im_glute_r', name: 'Gluteo Direito', shortName: 'GL-D', route: RouteType.im, cooldownDays: 14),
      const InjectionSite(id: 'im_deltoid_l', name: 'Deltoide Esquerdo', shortName: 'DL-E', route: RouteType.im, cooldownDays: 14),
      const InjectionSite(id: 'im_deltoid_r', name: 'Deltoide Direito', shortName: 'DL-D', route: RouteType.im, cooldownDays: 14),
      const InjectionSite(id: 'im_vastus_l', name: 'Vasto Lateral Esquerdo', shortName: 'VL-E', route: RouteType.im, cooldownDays: 14),
      const InjectionSite(id: 'im_vastus_r', name: 'Vasto Lateral Direito', shortName: 'VL-D', route: RouteType.im, cooldownDays: 14),
    ];
  }

  static Future<void> initializeDefaultSites() async {
    // Chamado no primeiro uso para criar locais padrão
    final sites = getDefaultSites();
    // Storage é feito pelo caller
    return;
  }
}