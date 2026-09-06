# Orbit Flutter M6 Screen Manifest

| Screen | Route | Source |
|---|---|---|
| Camera | `/camera` | `lib/features/camera/presentation/camera_page.dart` |
| Moment Review | `/camera/review` | `lib/features/camera/presentation/moment_review_page.dart` |
| Circle Moments | `/circles/{circleId}/moments` | `lib/features/moments/presentation/pages/circle_moments_page.dart` |
| Moment Viewer | `/moments/{momentId}` | `lib/features/moments/presentation/pages/moment_viewer_page.dart` |
| Moment Viewers | `/moments/{momentId}/viewers` | `lib/features/moments/presentation/pages/moment_viewers_page.dart` |

## Existing screens extended

- Home — adds the real Recent Moments rail: `lib/features/home/presentation/home_page.dart`
- Circle Detail — adds the real Moments action: `lib/features/circles/presentation/pages/circle_detail_page.dart`
- Central router — registers all M6 routes: `lib/app/routing/app_router.dart`
