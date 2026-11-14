import '../contexts/iam/application/auth_facade.dart';
import '../contexts/iam/domain/user_segment.dart';
import 'etapa3_routes.dart';
import 'operator_routes.dart';

/// Pantalla de inicio según el segmento de la cuenta.
String homeRouteFor(UserSegment segment) => switch (segment) {
      UserSegment.home => Etapa3Routes.dashboardOverview,
      UserSegment.operator => OperatorRoutes.exposure,
    };

Future<String> homeRoute() async => homeRouteFor(await AuthFacade.segment());

/// Para el arranque: usa el segmento guardado y no espera a la red.
Future<String> storedHomeRoute() async =>
    homeRouteFor(await AuthFacade.storedSegment());
