import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:navgo_mobile/views/explore/explore_view.dart';
import 'package:navgo_mobile/views/onboarding/onboarding_view.dart';
import 'package:navgo_mobile/views/plan/plan_view.dart';
import 'package:navgo_mobile/views/profile/profile_view.dart';
import 'package:navgo_mobile/views/splash/splash_view.dart';
import 'package:navgo_mobile/views/trips/trips_view.dart';
import 'package:navgo_mobile/widgets/navgo_shell.dart';

class NavGoRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const plan = '/plan';
  static const trips = '/trips';
  static const explore = '/explore';
  static const profile = '/profile';

  static GoRouter createRouter(SessionRepository session) {
    return GoRouter(
      initialLocation: splash,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (loc == splash) return null;

        final done = session.onboardingComplete;
        if (!done && loc != onboarding) return onboarding;
        if (done && loc == onboarding) return plan;
        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => SplashView(session: session),
        ),
        GoRoute(
          path: onboarding,
          builder: (context, state) => OnboardingView(session: session),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return NavGoShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: plan,
                  builder: (context, state) => PlanView(session: session),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: trips,
                  builder: (context, state) => const TripsView(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: explore,
                  builder: (context, state) => const ExploreView(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: profile,
                  builder: (context, state) => ProfileView(session: session),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
