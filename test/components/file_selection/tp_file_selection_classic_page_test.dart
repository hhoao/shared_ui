import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/components/file_selection/ui/classic/tp_file_selection_classic_page.dart';

import 'fake_file_selection_ports.dart';

const _phoneRoot = TpFilesystemRoot(
  id: 'phone_storage',
  label: 'phone_storage',
  path: '/storage',
);

const _appFoldersRoot = TpFilesystemRoot(
  id: 'app_folders',
  label: 'app_folders',
  path: '/storage/Download',
);

const _dcimDir = TpFsEntry(
  path: '/storage/DCIM',
  name: 'DCIM',
  kind: TpFsEntryKind.directory,
);

const _downloadDir = TpFsEntry(
  path: '/storage/Download',
  name: 'Download',
  kind: TpFsEntryKind.directory,
);

const _rootFile = TpFsEntry(
  path: '/storage/notes.txt',
  name: 'notes.txt',
  kind: TpFsEntryKind.file,
);

const _dcimVideo = TpFsEntry(
  path: '/storage/DCIM/VID_2024.mp4',
  name: 'VID_2024.mp4',
  kind: TpFsEntryKind.file,
);

const _dcimImage = TpFsEntry(
  path: '/storage/DCIM/IMG_0001.jpg',
  name: 'IMG_0001.jpg',
  kind: TpFsEntryKind.file,
);

const _downloadedFile = TpFsEntry(
  path: '/storage/Download/report.pdf',
  name: 'report.pdf',
  kind: TpFsEntryKind.file,
);

Widget _themeWrap(Widget child) {
  return TpTheme(
    data: TpThemeData.fromColorScheme(
      ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A)),
      scale: 1.0,
    ),
    child: child,
  );
}

FakeFilesystemPort _filesystem() => FakeFilesystemPort(
      roots: [_phoneRoot, _appFoldersRoot],
      entriesByPath: {
        '/storage': [_dcimDir, _downloadDir, _rootFile],
        '/storage/DCIM': [_dcimVideo, _dcimImage],
        '/storage/Download': [_downloadedFile],
      },
    );

TpFileSelectionDeps _deps({
  FakeFilesystemPort? filesystem,
  FakeGalleryPort? gallery,
  FakePermissionPort? permission,
}) {
  return TpFileSelectionDeps(
    filesystem: filesystem ?? _filesystem(),
    permission: permission ?? FakePermissionPort(),
    gallery:
        gallery ??
        FakeGalleryPort(
          albums: const [
            TpGalleryAlbum(
              id: 'album_all',
              name: 'Recent',
              assetCount: 2,
              isAll: true,
            ),
            TpGalleryAlbum(id: 'album_shots', name: 'Screenshots', assetCount: 1),
          ],
          assetsByAlbum: const {
            'album_all': [
              TpGalleryAsset(id: 'v1', displayName: 'VID.mp4', isVideo: true),
              TpGalleryAsset(id: 'i1', displayName: 'IMG.jpg', isVideo: false),
            ],
            'album_shots': [
              TpGalleryAsset(id: 's1', displayName: 'shot.png', isVideo: false),
            ],
          },
          pathsByAssetId: const {
            'v1': '/storage/DCIM/VID_2024.mp4',
            'i1': '/storage/DCIM/IMG_0001.jpg',
            's1': '/storage/Pictures/shot.png',
          },
        ),
    strings: TpFileSelectionStrings.english(),
    isDesktop: () => false,
  );
}

Future<void> _openPage(
  WidgetTester tester, {
  required TpFileSelectionDeps deps,
  TpFileSelectionOptions options = const TpFileSelectionOptions(
    allowMultiple: true,
    layout: TpFileSelectionLayout.classic,
  ),
}) async {
  // Phone-tall viewport so the legacy browser renders all its rows.
  tester.view.physicalSize = const Size(1264, 2780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _themeWrap(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TpFileSelectionClassicPage(
                      deps: deps,
                      options: options,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  final strings = TpFileSelectionStrings.english();

  group('TpFileSelectionClassicPage tabs', () {
    testWidgets('renders 文件/相册 top tabs and storage pills', (tester) async {
      await _openPage(tester, deps: _deps());

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text(strings.tabFiles), findsOneWidget);
      expect(find.text(strings.tabPhotoGallery), findsOneWidget);
      expect(
        find.byKey(const Key('tp_classic_storage_subtabs')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('tp_classic_subtab_${strings.phoneStorageTab}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('tp_classic_subtab_${strings.appFoldersTab}')),
        findsOneWidget,
      );
    });

    testWidgets('文件 tab shows breadcrumb, quick access and folder list',
        (tester) async {
      await _openPage(tester, deps: _deps());

      // Breadcrumb root segment.
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text(strings.phoneStorageTab), findsNWidgets(2));
      // Quick access circles.
      expect(
        find.byKey(Key('tp_classic_quick_${strings.quickAccessDownload}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('tp_classic_quick_${strings.quickAccessCamera}')),
        findsOneWidget,
      );
      // Folder list rows for the phone root.
      expect(find.byKey(const Key('tp_classic_folder_list')), findsOneWidget);
      expect(find.text('DCIM'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('notes.txt'), findsOneWidget);
    });

    testWidgets('switching to app folders pill browses its root',
        (tester) async {
      await _openPage(tester, deps: _deps());

      await tester.tap(
        find.byKey(Key('tp_classic_subtab_${strings.appFoldersTab}')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tp_classic_folder_list')), findsOneWidget);
      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.text('notes.txt'), findsNothing);
    });

    testWidgets('quick access circle navigates into the folder',
        (tester) async {
      await _openPage(tester, deps: _deps());

      await tester.tap(
        find.byKey(Key('tp_classic_quick_${strings.quickAccessCamera}')),
      );
      await tester.pumpAndSettle();

      // Breadcrumb now shows the DCIM segment and the folder contents.
      expect(find.text('VID_2024.mp4'), findsOneWidget);
      expect(find.text('IMG_0001.jpg'), findsOneWidget);
    });

    testWidgets('gallery tab shows album pill and asset grid', (tester) async {
      await _openPage(
        tester,
        deps: _deps(),
        options: const TpFileSelectionOptions(
          allowMultiple: true,
          layout: TpFileSelectionLayout.classic,
          initialTab: TpFileSelectionTab.gallery,
        ),
      );

      expect(
        find.byKey(const Key('tp_classic_gallery_album_pill')),
        findsOneWidget,
      );
      expect(find.text('Recent'), findsOneWidget);
      expect(find.byKey(const Key('tp_gallery_asset_tile_v1')), findsOneWidget);
      expect(find.byKey(const Key('tp_gallery_asset_tile_i1')), findsOneWidget);
    });

    testWidgets('gallery album sheet switches albums', (tester) async {
      await _openPage(
        tester,
        deps: _deps(),
        options: const TpFileSelectionOptions(
          allowMultiple: true,
          layout: TpFileSelectionLayout.classic,
          initialTab: TpFileSelectionTab.gallery,
        ),
      );

      await tester.tap(
        find.byKey(const Key('tp_classic_gallery_album_pill')),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.selectAlbum), findsOneWidget);
      await tester.tap(find.text('Screenshots'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tp_gallery_asset_tile_s1')), findsOneWidget);
      expect(find.byKey(const Key('tp_gallery_asset_tile_v1')), findsNothing);
    });

    testWidgets('switching tabs with a selection asks for confirmation',
        (tester) async {
      await _openPage(tester, deps: _deps());

      await tester.tap(
        find.byKey(Key('tp_classic_quick_${strings.quickAccessCamera}')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('VID_2024.mp4').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text(strings.tabPhotoGallery));
      await tester.pumpAndSettle();

      expect(find.text(strings.switchTabTitle), findsOneWidget);

      await tester.tap(find.text(strings.actionConfirm));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('tp_classic_gallery_album_pill')),
        findsOneWidget,
      );
    });

    testWidgets('directory mode hides the tab bar entirely', (tester) async {
      await _openPage(
        tester,
        deps: _deps(),
        options: const TpFileSelectionOptions(
          layout: TpFileSelectionLayout.classic,
          selectionMode: TpSelectionMode.directories,
        ),
      );

      // The legacy picker shows no tab bar in directory mode.
      expect(find.byType(TabBar), findsNothing);
      expect(find.text(strings.tabFiles), findsNothing);
      expect(find.text(strings.tabPhotoGallery), findsNothing);
    });
  });

  group('TpFileSelectionClassicPage legacy bottom bar', () {
    testWidgets('empty state shows prompt and disabled select button',
        (tester) async {
      await _openPage(
        tester,
        deps: _deps(),
        options: const TpFileSelectionOptions(
          allowMultiple: true,
          layout: TpFileSelectionLayout.classic,
          allowedExtensions: ['mp4'],
        ),
      );

      expect(find.text(strings.clearSelection), findsOneWidget);
      expect(find.text(strings.selectAll), findsOneWidget);
      expect(
        find.text(strings.selectionPromptForType(strings.mediaTypeVideo)),
        findsOneWidget,
      );
      expect(find.text(strings.selectAction), findsOneWidget);
    });

    testWidgets('selection shows summary and count on confirm button',
        (tester) async {
      await _openPage(tester, deps: _deps());

      await tester.tap(
        find.byKey(Key('tp_classic_quick_${strings.quickAccessCamera}')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('VID_2024.mp4').last);
      await tester.pumpAndSettle();

      expect(find.text(strings.selectionSummaryItems(1)), findsOneWidget);
      expect(
        find.text(strings.actionConfirmWithCount(1)),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('tp_file_selection_confirm')));
      await tester.pumpAndSettle();

      // Page popped; back on the launcher screen.
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('TpFileSelectionClassicPage directory mode', () {
    testWidgets('shows the select-this-directory bar', (tester) async {
      await _openPage(
        tester,
        deps: _deps(),
        options: const TpFileSelectionOptions(
          layout: TpFileSelectionLayout.classic,
          selectionMode: TpSelectionMode.directories,
        ),
      );

      expect(
        find.byKey(const Key('tp_file_selection_select_directory')),
        findsOneWidget,
      );
    });
  });
}
