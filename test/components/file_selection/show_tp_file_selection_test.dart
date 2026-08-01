import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

import 'fake_file_selection_ports.dart';

TpFileSelectionDeps _deps({
  required bool Function() isDesktop,
  FakeDesktopPickerPort? desktop,
}) {
  return TpFileSelectionDeps(
    filesystem: FakeFilesystemPort(),
    permission: FakePermissionPort(),
    desktop: desktop,
    strings: TpFileSelectionStrings.english(),
    isDesktop: isDesktop,
  );
}

void main() {
  group('showTpFileSelection desktop routing', () {
    testWidgets('directories mode calls pickDirectory only', (tester) async {
      final desktop = FakeDesktopPickerPort(
        pickDirectoryResult: [
          const TpPickedEntry(path: '/picked', kind: TpPickedKind.directory),
        ],
      );
      final deps = _deps(isDesktop: () => true, desktop: desktop);
      late List<TpPickedEntry>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showTpFileSelection(
                    context: context,
                    deps: deps,
                    options: const TpFileSelectionOptions(
                      selectionMode: TpSelectionMode.directories,
                      title: 'Pick folder',
                      initialPath: '/start',
                    ),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(desktop.pickDirectoryCallCount, 1);
      expect(desktop.pickFilesCallCount, 0);
      expect(result, isNotNull);
      expect(result!.single.path, '/picked');
    });

    testWidgets('files mode calls pickFiles', (tester) async {
      final desktop = FakeDesktopPickerPort(
        pickFilesResult: [
          const TpPickedEntry(path: '/file.txt', kind: TpPickedKind.file),
        ],
      );
      final deps = _deps(isDesktop: () => true, desktop: desktop);
      late List<TpPickedEntry>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showTpFileSelection(
                    context: context,
                    deps: deps,
                    options: const TpFileSelectionOptions(
                      selectionMode: TpSelectionMode.files,
                      allowMultiple: true,
                      allowedExtensions: ['txt'],
                      title: 'Pick files',
                      initialPath: '/docs',
                      maxSelectionCount: 3,
                    ),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(desktop.pickFilesCallCount, 1);
      expect(desktop.pickDirectoryCallCount, 0);
      expect(result, isNotNull);
      expect(result!.single.path, '/file.txt');
    });

    testWidgets('both mode calls pickFiles', (tester) async {
      final desktop = FakeDesktopPickerPort(
        pickFilesResult: [
          const TpPickedEntry(path: '/any', kind: TpPickedKind.file),
        ],
      );
      final deps = _deps(isDesktop: () => true, desktop: desktop);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showTpFileSelection(
                    context: context,
                    deps: deps,
                    options: const TpFileSelectionOptions(
                      selectionMode: TpSelectionMode.both,
                    ),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(desktop.pickFilesCallCount, 1);
      expect(desktop.pickDirectoryCallCount, 0);
    });
  });

  testWidgets('non-desktop pushes TpFileSelectionPage', (tester) async {
    final deps = _deps(isDesktop: () => false);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showTpFileSelection(context: context, deps: deps);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tp_file_selection_page')), findsOneWidget);
  });
}
