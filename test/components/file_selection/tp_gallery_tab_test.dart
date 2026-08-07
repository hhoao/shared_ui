import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

import 'fake_file_selection_ports.dart';

const _albumCamera = TpGalleryAlbum(
  id: 'album_camera',
  name: 'Camera Roll',
  assetCount: 2,
);

const _albumScreenshots = TpGalleryAlbum(
  id: 'album_screenshots',
  name: 'Screenshots',
  assetCount: 1,
);

Widget _wrap(Widget child) {
  return TpTheme(
    data: TpThemeData.fromColorScheme(
      ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A)),
      scale: 1.0,
    ),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

TpFileSelectionDeps _deps({
  required FakeGalleryPort gallery,
  FakePermissionPort? permission,
  FakeMediaPreviewPort? preview,
}) {
  return TpFileSelectionDeps(
    filesystem: FakeFilesystemPort(),
    gallery: gallery,
    permission: permission ?? FakePermissionPort(),
    preview: preview,
    strings: TpFileSelectionStrings.english(),
    isDesktop: () => false,
  );
}

TpFileSelectionController _controller({
  TpFileSelectionOptions options = const TpFileSelectionOptions(
    allowMultiple: true,
  ),
  void Function(int maxCount)? onSelectAllCapped,
}) {
  return TpFileSelectionController(
    options: options,
    onSelectAllCapped: onSelectAllCapped,
  );
}

FakeGalleryPort _galleryWithSampleAssets() {
  final gallery = FakeGalleryPort(
    albums: const [_albumCamera, _albumScreenshots],
    pathsByAssetId: {
      'img1': '/media/vacation.jpg',
      'img2': '/media/notes.jpg',
      'vid1': '/media/clip.mp4',
    },
  );
  gallery.setAssets('album_camera', const [
    TpGalleryAsset(id: 'img1', displayName: 'vacation.jpg', isVideo: false),
    TpGalleryAsset(id: 'img2', displayName: 'notes.jpg', isVideo: false),
    TpGalleryAsset(id: 'vid1', displayName: 'clip.mp4', isVideo: true),
  ]);
  gallery.setAssets('album_screenshots', const [
    TpGalleryAsset(id: 'shot1', displayName: 'screenshot.png', isVideo: false),
  ]);
  return gallery;
}

void main() {
  group('TpGalleryTab', () {
    testWidgets('shows albums then assets after gallery permission grant',
        (tester) async {
      final gallery = _galleryWithSampleAssets();
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpGalleryTab(
            deps: _deps(gallery: gallery),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Camera Roll'), findsOneWidget);
      expect(
        find.byKey(const Key('tp_gallery_asset_tile_img1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('tp_gallery_album_selector')));
      await tester.pumpAndSettle();

      expect(find.text('Screenshots'), findsOneWidget);
    });

    testWidgets('pagination loads page 2', (tester) async {
      final gallery = FakeGalleryPort(
        albums: const [_albumCamera],
        pathsByAssetId: {
          for (var i = 0; i < 55; i++) 'asset_$i': '/media/asset_$i.jpg',
        },
      );
      gallery.setAssets(
        'album_camera',
        List.generate(
          55,
          (i) => TpGalleryAsset(
            id: 'asset_$i',
            displayName: 'asset_$i.jpg',
            isVideo: false,
          ),
        ),
      );
      final controller = _controller();
      final strings = TpFileSelectionStrings.english();

      await tester.pumpWidget(
        _wrap(
          TpGalleryTab(
            deps: _deps(gallery: gallery),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabState =
          tester.state<TpGalleryTabState>(find.byType(TpGalleryTab));

      expect(tabState.loadedAssetCount, 50);
      expect(
        find.byKey(const Key('tp_gallery_asset_tile_asset_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tp_gallery_asset_tile_asset_50')),
        findsNothing,
      );

      await tabState.debugLoadMore();
      await tester.pumpAndSettle();

      expect(tabState.loadedAssetCount, 55);
    });

    testWidgets('in-list search filters assets', (tester) async {
      final gallery = _galleryWithSampleAssets();
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpGalleryTab(
            deps: _deps(gallery: gallery),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('tp_gallery_search_field')),
        'vacation',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('tp_gallery_asset_tile_img1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tp_gallery_asset_tile_img2')),
        findsNothing,
      );
    });

    testWidgets('preview button absent when deps.preview is null', (tester) async {
      final gallery = _galleryWithSampleAssets();
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpGalleryTab(
            deps: _deps(gallery: gallery),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tp_gallery_preview_img1')), findsNothing);
    });

    testWidgets('preview button present and calls preview when set',
        (tester) async {
      final gallery = _galleryWithSampleAssets();
      final preview = FakeMediaPreviewPort();
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpGalleryTab(
            deps: _deps(gallery: gallery, preview: preview),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tp_gallery_preview_vid1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tp_gallery_preview_vid1')));
      await tester.pumpAndSettle();

      expect(preview.previewedVideoPaths, ['/media/clip.mp4']);
    });

    testWidgets('selecting asset resolves path and updates controller',
        (tester) async {
      final gallery = _galleryWithSampleAssets();
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpGalleryTab(
            deps: _deps(gallery: gallery),
            options: const TpFileSelectionOptions(allowMultiple: true),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tp_gallery_asset_tile_img1')));
      await tester.pumpAndSettle();

      expect(controller.selection, hasLength(1));
      expect(controller.selection.single.path, '/media/vacation.jpg');
      expect(controller.selection.single.displayName, 'vacation.jpg');
    });

    testWidgets('TabApi clearSelection and selectAll respect maxCount',
        (tester) async {
      final gallery = _galleryWithSampleAssets();
      int? cappedAt;
      final controller = _controller(
        options: const TpFileSelectionOptions(
          allowMultiple: true,
          maxSelectionCount: 2,
        ),
        onSelectAllCapped: (max) => cappedAt = max,
      );

      await tester.pumpWidget(
        _wrap(
          TpGalleryTab(
            deps: _deps(gallery: gallery),
            options: const TpFileSelectionOptions(
              allowMultiple: true,
              maxSelectionCount: 2,
            ),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabApi =
          tester.state<TpGalleryTabState>(find.byType(TpGalleryTab));

      await tabApi.selectAll();
      await tester.pumpAndSettle();

      expect(controller.selection, hasLength(2));
      expect(cappedAt, 2);

      tabApi.clearSelection();
      await tester.pumpAndSettle();
      expect(controller.selection, isEmpty);
    });

    testWidgets('permission denied shows empty state and open settings',
        (tester) async {
      final gallery = _galleryWithSampleAssets();
      final permission = FakePermissionPort(grantGallery: false);
      final controller = _controller();
      final strings = TpFileSelectionStrings.english();

      await tester.pumpWidget(
        _wrap(
          TpGalleryTab(
            deps: _deps(gallery: gallery, permission: permission),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.galleryPermissionRequired), findsOneWidget);
      expect(find.text(strings.goToSettings), findsOneWidget);

      await tester.tap(find.text(strings.goToSettings));
      await tester.pumpAndSettle();

      expect(permission.openAppSettingsCallCount, 1);
    });
  });
}
