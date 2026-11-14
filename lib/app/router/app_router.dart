import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/backend/backend_providers.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/new_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/clubs/presentation/club_detail_screen.dart';
import '../../features/clubs/presentation/club_form_screen.dart';
import '../../features/clubs/presentation/clubs_screen.dart';
import '../../features/clubs/presentation/verification_admin_screen.dart';
import '../../features/clubs/presentation/verification_request_screen.dart';
import '../../features/community/presentation/blocked_users_screen.dart';
import '../../features/community/presentation/moderation_screen.dart';
import '../../features/community/presentation/post_composer_screen.dart';
import '../../features/community/presentation/post_detail_screen.dart';
import '../../features/community/presentation/rider_profile_screen.dart';
import '../../features/convoy/presentation/convoy_screen.dart';
import '../../features/garage/presentation/garage_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/marketplace/presentation/listing_detail_screen.dart';
import '../../features/marketplace/presentation/listing_form_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/messages/presentation/chat_screen.dart';
import '../../features/messages/presentation/messages_screen.dart';
import '../../features/messages/presentation/new_conversation_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/delete_account_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/privacy_settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rides/presentation/ride_detail_screen.dart';
import '../../features/rides/presentation/ride_form_screen.dart';
import '../../features/rides/presentation/rides_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'auth_guard.dart';
import 'not_found_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Routeur de l'application.
///
/// La garde d'authentification ([resolveAuthRedirect]) est réévaluée à chaque
/// changement de session.
final routerProvider = Provider<GoRouter>((ref) {
  final backendReady = ref.watch(backendStatusProvider).isReady;
  final session = ref.watch(authSessionProvider);
  final recovery = ref.watch(passwordRecoveryProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: Listenable.merge([session, recovery]),
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) => resolveAuthRedirect(
      location: state.uri,
      backendReady: backendReady,
      signedIn: session.value != null,
      passwordRecovery: recovery.value,
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) =>
            SignInScreen(notice: state.uri.queryParameters['notice']),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.newPassword,
        builder: (context, state) => const NewPasswordScreen(),
      ),
      // Filet de sécurité si un lien d'authentification atteint le routeur :
      // supabase_flutter l'a déjà traité.
      GoRoute(path: AppRoutes.authCallback, redirect: (_, _) => AppRoutes.home),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rides,
                builder: (context, state) => const RidesScreen(),
                routes: [
                  // « nouvelle » doit précéder le paramètre « :rideId ».
                  GoRoute(
                    path: 'nouvelle',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => RideFormScreen(
                      clubId: state.uri.queryParameters['club'],
                    ),
                  ),
                  GoRoute(
                    path: ':rideId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => RideDetailScreen(
                      rideId: state.pathParameters['rideId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'modifier',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => RideFormScreen(
                          rideId: state.pathParameters['rideId'],
                        ),
                      ),
                      GoRoute(
                        path: 'convoi',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ConvoyScreen(
                          rideId: state.pathParameters['rideId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'sos',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            SosScreen(rideId: state.pathParameters['rideId']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.clubs,
                builder: (context, state) => const ClubsScreen(),
                routes: [
                  // « nouveau » doit précéder le paramètre « :clubId ».
                  GoRoute(
                    path: 'nouveau',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ClubFormScreen(),
                  ),
                  GoRoute(
                    path: ':clubId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ClubDetailScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'modifier',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ClubFormScreen(
                          clubId: state.pathParameters['clubId'],
                        ),
                      ),
                      GoRoute(
                        path: 'verification',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => VerificationRequestScreen(
                          clubId: state.pathParameters['clubId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                builder: (context, state) => const MessagesScreen(),
                routes: [
                  // « nouveau » doit précéder le paramètre « :conversationId ».
                  GoRoute(
                    path: 'nouveau',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const NewConversationScreen(),
                  ),
                  GoRoute(
                    path: ':conversationId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ChatScreen(
                      conversationId: state.pathParameters['conversationId']!,
                      initialText: state.uri.queryParameters['texte'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'modifier',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'confidentialite',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PrivacySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'supprimer-mon-compte',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const DeleteAccountScreen(),
                  ),
                  GoRoute(
                    path: 'bloques',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const BlockedUsersScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.garage,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GarageScreen(),
      ),
      GoRoute(
        path: AppRoutes.marketplace,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MarketplaceScreen(),
        routes: [
          GoRoute(
            path: 'vendre',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const ListingFormScreen(),
          ),
          GoRoute(
            path: 'annonces/:listingId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => ListingDetailScreen(
              listingId: state.pathParameters['listingId']!,
            ),
            routes: [
              GoRoute(
                path: 'modifier',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ListingFormScreen(
                  listingId: state.pathParameters['listingId'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/publier',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            PostComposerScreen(clubId: state.uri.queryParameters['club']),
      ),
      GoRoute(
        path: '/publications/:postId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            PostDetailScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: '/motards/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            RiderProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationAdmin,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VerificationAdminScreen(),
      ),
      GoRoute(
        path: AppRoutes.moderation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ModerationScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
