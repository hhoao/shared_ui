import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/components/file_selection/ui/tp_file_selection_page.dart';

import 'fake_file_selection_ports.dart';

const _phoneRoot = TpFilesystemRoot(
  id: 'phone_storage',
  label: 'Phone storage',
  path: '/storage',
);

const _albumCamera = TpGalleryAlbum(
  id: 'album_camera',
  name: 'Camera Roll',
  assetCount: 1,
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

Future<void> _openPage(
  WidgetTester tester, {
  required TpFileSelectionDeps deps,
  TpFileSelectionOptions options = const TpFileSelectionOptions(
    allowMultiple: true,
  ),
}) async {
  await tester.pumpWidget(
    _themeWrap(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TpFileSelectionPage(
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
  await tester.pump(const Duration(milliseconds: 100));
}

TpFileSelectionDeps _depsWithFilesystem({
  FakeFilesystemPort? filesystem,
  FakeGalleryPort? gallery,
  FakePermissionPort? permission,
}) {
  final fs = filesystem ??
      FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot],
      );
  fs.setEntries('/storage', const [
    TpFsEntry(
      path: '/storage/readme.txt',
      name: 'readme.txt',
      kind: TpFsEntryKind.file,
    ),
  ]);
  return TpFileSelectionDeps(
    filesystem: fs,
    gallery: gallery,
    permission: permission ?? FakePermissionPort(),
    strings: TpFileSelectionStrings.english(),
    isDesktop: () => false,
  );
}

FakeGalleryPort _galleryWithSampleAssets() {
  final gallery = FakeGalleryPort(
    albums: const [_albumCamera],
    pathsByAssetId: const {'img1': '/media/vacation.jpg'},
  );
  gallery.setAssets('album_camera', const [
    TpGalleryAsset(id: 'img1', displayName: 'vacation.jpg', isVideo: false),
  ]);
  return gallery;
}

void main() {
  final strings = TpFileSelectionStrings.english();

  group('TpFileSelectionPage tabs', () {
    testWidgets('omits gallery tab when gallery port is null', (tester) async {
      await _openPage(tester, deps: _depsWithFilesystem());

      await tester.pumpAndSettle();

      expect(find.text(strings.tabFiles), findsNothing);
      expect(find.text(strings.tabPhotoGallery), findsNothing);
      expect(find.byType(TpFilesystemTab), findsOneWidget);
      expect(find.byType(TpGalleryTab), findsNothing);
    });

    testWidgets('omits gallery tab in directories mode', (tester) async {
      await _openPage(
        tester,
        deps: _depsWithFilesystem(gallery: _galleryWithSampleAssets()),
        options: const TpFileSelectionOptions(
          selectionMode: TpSelectionMode.directories,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(strings.tabPhotoGallery), findsNothing);
      expect(find.byType(TpGalleryTab), findsNothing);
    });

    testWidgets('shows filesystem and gallery tabs when gallery is available',
        (tester) async {
      await _openPage(
        tester,
        deps: _depsWithFilesystem(gallery: _galleryWithSampleAssets()),
      );

      await tester.pumpAndSettle();

      expect(find.text(strings.tabFiles), findsOneWidget);
      expect(find.text(strings.tabPhotoGallery), findsOneWidget);
    });
  });

  group('TpFileSelectionPage app bar', () {
    testWidgets('has close and sort actions but no confirm in app bar',
        (tester) async {
      await _openPage(tester, deps: _depsWithFilesystem());

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tp_file_selection_close')), findsOneWidget);
      expect(find.byKey(const Key('tp_file_selection_sort')), findsOneWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNull);
    });
  });

  group('TpFileSelectionPage bottom bar', () {
    testWidgets('files mode shows multi-select bottom bar', (tester) async {
      await _openPage(
        tester,
        deps: _depsWithFilesystem(),
        options: const TpFileSelectionOptions(
          selectionMode: TpSelectionMode.files,
          allowMultiple: true,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tp_file_selection_clear')), findsOneWidget);
      expect(find.byKey(const Key('tp_file_selection_select_all')), findsOneWidget);
      expect(find.byKey(const Key('tp_file_selection_confirm')), findsOneWidget);
      expect(
        find.byKey(const Key('tp_file_selection_select_directory')),
        findsNothing,
      );
    });

    testWidgets('directory mode shows select-this-directory bar', (tester) async {
      await _openPage(
        tester,
        deps: _depsWithFilesystem(),
        options: const TpFileSelectionOptions(
          selectionMode: TpSelectionMode.directories,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('tp_file_selection_select_directory')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tp_file_selection_clear')), findsNothing);
      expect(find.byKey(const Key('tp_file_selection_select_all')), findsNothing);
      expect(find.text(strings.currentDirectoryLabel), findsOneWidget);
    });
  });

  group('TpFileSelectionPage tab switching', () {
    testWidgets('shows confirm dialog when switching with selection; cancel keeps tab',
        (tester) async {
      await _openPage(
        tester,
        deps: _depsWithFilesystem(gallery: _galleryWithSampleAssets()),
        options: const TpFileSelectionOptions(allowMultiple: true),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('readme.txt'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(strings.tabPhotoGallery));
      await tester.pumpAndSettle();

      expect(find.text(strings.switchTabTitle), findsOneWidget);
      expect(find.text(strings.switchTabClearSelectionMessage), findsOneWidget);

      await tester.tap(find.text(strings.taskStatusCancelledShort));
      await tester.pumpAndSettle();

      expect(find.text(strings.switchTabTitle), findsNothing);
      expect(find.byType(TpFilesystemTab), findsOneWidget);
      expect(find.byType(TpGalleryTab), findsNothing);
    });

    testWidgets('confirming tab switch clears selection and switches tab',
        (tester) async {
      await _openPage(
        tester,
        deps: _depsWithFilesystem(gallery: _galleryWithSampleAssets()),
        options: const TpFileSelectionOptions(allowMultiple: true),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('readme.txt'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(strings.tabPhotoGallery));
      await tester.pumpAndSettle();

      await tester.tap(find.text(strings.actionConfirm));
      await tester.pumpAndSettle();

      expect(find.text(strings.switchTabTitle), findsNothing);
      expect(find.byType(TpGalleryTab), findsOneWidget);
      expect(find.text(strings.noItemsSelected), findsOneWidget);
    });
  });

  group('TpFileSelectionPage confirm', () {
    testWidgets('confirm pops selected entries', (tester) async {
      final deps = _depsWithFilesystem();
      List<TpPickedEntry>? result;

      await tester.pumpWidget(
        _themeWrap(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<List<TpPickedEntry>>(
                      MaterialPageRoute(
                        builder: (_) => TpFileSelectionPage(
                          deps: deps,
                          options: const TpFileSelectionOptions(
                            allowMultiple: true,
                          ),
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('readme.txt'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tp_file_selection_confirm')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, hasLength(1));
      expect(result!.single.path, '/storage/readme.txt');
      expect(find.byKey(const Key('tp_file_selection_page')), findsNothing);
    });
  });

  group('TpFileSelectionPage path not found', () {
    testWidgets('shows dialog then pops entire page', (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot],
        existingPaths: {'/storage'},
      );
      final deps = _depsWithFilesystem(filesystem: filesystem);
      var pageOpen = true;

      await tester.pumpWidget(
        _themeWrap(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => TpFileSelectionPage(
                          deps: deps,
                          options: const TpFileSelectionOptions(
                            initialPath: '/missing/path',
                          ),
                        ),
                      ),
                    );
                    pageOpen = false;
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text(strings.pathNotFound('/missing/path')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('tp_file_selection_path_not_found_confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tp_file_selection_page')), findsNothing);
      expect(pageOpen, isFalse);
    });
  });
}
