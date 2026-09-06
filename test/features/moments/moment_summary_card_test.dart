import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/media/domain/media_models.dart';
import 'package:orbit_app/features/moments/domain/moment_models.dart';
import 'package:orbit_app/features/moments/presentation/widgets/moment_summary_card.dart';

void main() {
  testWidgets('Moment summary renders privacy-safe metadata', (tester) async {
    final moment = OrbitMoment(
      id: 'moment-id',
      circleId: 'circle-id',
      author: const OrbitMomentAuthor(userId: 7, name: 'Avery'),
      media: OrbitMediaAsset(
        assetId: 'asset-id',
        circleId: 'circle-id',
        kind: OrbitMediaKind.image,
        sizeBytes: 1200,
        sha256Ciphertext: ''.padLeft(64, 'a'),
      ),
      viewCount: 2,
      isMine: false,
      expiresAt: DateTime.utc(2026, 9, 7),
      createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 240,
            child: MomentSummaryCard(
              item: RecentMomentItem(moment: moment, circleName: 'Family'),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Avery'), findsOneWidget);
    expect(find.textContaining('Family'), findsOneWidget);
    expect(find.byIcon(Icons.photo_rounded), findsOneWidget);
  });
}
