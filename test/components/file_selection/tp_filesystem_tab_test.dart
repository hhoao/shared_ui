import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

import 'fake_file_selection_ports.dart';

const _phoneRoot = TpFilesystemRoot(
  id: 'phone_storage',
  label: 'Phone storage',
  path: '/storage',
);

const _appRoot = TpFilesystemRoot(
  id: 'app_folders',
  label: 'App folders',
  path: '/downloads',
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
  required FakeFilesystemPort filesystem,
  FakePermissionPort? permission,
}) {
  return TpFileSelectionDeps(
    filesystem: filesystem,
    permission: permission ?? FakePermissionPort(),
    strings: TpFileSelectionStrings.english(),
    isDesktop: () => false,
  );
}

TpFileSelectionController _controller({
  TpFileSelectionOptions options = const TpFileSelectionOptions(
    allowMultiple: true,
  ),
}) {
  return TpFileSelectionController(options: options);
}

void main() {
  group('TpFilesystemTab', () {
    testWidgets('lists root entries after permission grant', (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot, _appRoot],
      );
      filesystem.setEntries('/storage', const [
        TpFsEntry(
          path: '/storage/docs',
          name: 'docs',
          kind: TpFsEntryKind.directory,
        ),
        TpFsEntry(
          path: '/storage/readme.txt',
          name: 'readme.txt',
          kind: TpFsEntryKind.file,
        ),
      ]);
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpFilesystemTab(
            deps: _deps(filesystem: filesystem),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('docs'), findsOneWidget);
      expect(find.text('readme.txt'), findsOneWidget);
    });

    testWidgets('tapping directory navigates and lists children', (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot, _appRoot],
      );
      filesystem.setEntries('/storage', const [
        TpFsEntry(
          path: '/storage/docs',
          name: 'docs',
          kind: TpFsEntryKind.directory,
        ),
      ]);
      filesystem.setEntries('/storage/docs', const [
        TpFsEntry(
          path: '/storage/docs/notes.txt',
          name: 'notes.txt',
          kind: TpFsEntryKind.file,
        ),
      ]);
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpFilesystemTab(
            deps: _deps(filesystem: filesystem),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('docs'));
      await tester.pumpAndSettle();

      expect(find.text('notes.txt'), findsOneWidget);
      expect(controller.currentPath, '/storage/docs');
    });

    testWidgets('in-list search filters visible names', (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot, _appRoot],
      );
      filesystem.setEntries('/storage', const [
        TpFsEntry(
          path: '/storage/alpha.txt',
          name: 'alpha.txt',
          kind: TpFsEntryKind.file,
        ),
        TpFsEntry(
          path: '/storage/beta.txt',
          name: 'beta.txt',
          kind: TpFsEntryKind.file,
        ),
      ]);
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpFilesystemTab(
            deps: _deps(filesystem: filesystem),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('tp_filesystem_search_field')),
        'alpha',
      );
      await tester.pumpAndSettle();

      expect(find.text('alpha.txt'), findsOneWidget);
      expect(find.text('beta.txt'), findsNothing);
    });

    testWidgets('hidden file omitted when showHiddenFiles is false', (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot, _appRoot],
      );
      filesystem.setEntries('/storage', const [
        TpFsEntry(
          path: '/storage/.hidden',
          name: '.hidden',
          kind: TpFsEntryKind.file,
        ),
        TpFsEntry(
          path: '/storage/visible.txt',
          name: 'visible.txt',
          kind: TpFsEntryKind.file,
        ),
      ]);
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpFilesystemTab(
            deps: _deps(filesystem: filesystem),
            options: const TpFileSelectionOptions(showHiddenFiles: false),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('.hidden'), findsNothing);
      expect(find.text('visible.txt'), findsOneWidget);
    });

    testWidgets('full-disk-search sub-tab hidden when searchFiles is null',
        (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot, _appRoot],
      );
      filesystem.setEntries('/storage', const []);
      final controller = _controller();
      final strings = TpFileSelectionStrings.english();

      await tester.pumpWidget(
        _wrap(
          TpFilesystemTab(
            deps: TpFileSelectionDeps(
              filesystem: filesystem,
              permission: FakePermissionPort(),
              strings: strings,
              isDesktop: () => false,
            ),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.phoneStorageTab), findsOneWidget);
      expect(find.text(strings.appFoldersTab), findsOneWidget);
      expect(find.text(strings.fullDiskSearchTab), findsNothing);
    });

    testWidgets('full-disk search dialog merges results into selection',
        (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot, _appRoot],
      );
      filesystem.setEntries('/storage', const []);
      filesystem.setSearchFiles((rootPath, query) async {
        expect(rootPath, '/storage');
        expect(query, 'report');
        return const [
          TpFsEntry(
            path: '/storage/report.pdf',
            name: 'report.pdf',
            kind: TpFsEntryKind.file,
          ),
        ];
      });
      final controller = _controller();
      final strings = TpFileSelectionStrings.english();

      await tester.pumpWidget(
        _wrap(
          TpFilesystemTab(
            deps: TpFileSelectionDeps(
              filesystem: filesystem,
              permission: FakePermissionPort(),
              strings: strings,
              isDesktop: () => false,
            ),
            options: const TpFileSelectionOptions(allowMultiple: true),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(strings.fullDiskSearchTab));
      await tester.pumpAndSettle();

      expect(find.byType(TpFullDiskSearchDialog), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('tp_full_disk_search_query')),
        'report',
      );
      await tester.tap(find.text(strings.actionSearch));
      await tester.pumpAndSettle();

      expect(find.text('report.pdf'), findsOneWidget);

      await tester.tap(find.text('report.pdf'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(strings.addSelectedFiles(1)));
      await tester.pumpAndSettle();

      expect(controller.selection, hasLength(1));
      expect(controller.selection.single.path, '/storage/report.pdf');
    });

    testWidgets('implements TabApi clearSelection selectAll applySorting',
        (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot, _appRoot],
      );
      filesystem.setEntries('/storage', const [
        TpFsEntry(
          path: '/storage/z.txt',
          name: 'z.txt',
          kind: TpFsEntryKind.file,
        ),
        TpFsEntry(
          path: '/storage/a.txt',
          name: 'a.txt',
          kind: TpFsEntryKind.file,
        ),
      ]);
      final controller = _controller();

      await tester.pumpWidget(
        _wrap(
          TpFilesystemTab(
            deps: _deps(filesystem: filesystem),
            options: const TpFileSelectionOptions(allowMultiple: true),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabApi =
          tester.state<TpFilesystemTabState>(find.byType(TpFilesystemTab));

      await tabApi.selectAll();
      await tester.pumpAndSettle();
      expect(controller.selection, hasLength(2));

      tabApi.clearSelection();
      await tester.pumpAndSettle();
      expect(controller.selection, isEmpty);

      tabApi.applySorting('name', ascending: true);
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<Text>(find.descendant(
            of: find.byKey(const Key('tp_filesystem_entry_list')),
            matching: find.byType(Text),
          ))
          .map((w) => w.data)
          .where((name) => name != null && name.endsWith('.txt'))
          .cast<String>()
          .toList();
      expect(names, ['a.txt', 'z.txt']);
    });

    testWidgets('permission denied shows empty state and open settings',
        (tester) async {
      final filesystem = FakeFilesystemPort(
        browsePath: '/storage',
        roots: const [_phoneRoot, _appRoot],
      );
      final permission = FakePermissionPort(grantStorage: false);
      final controller = _controller();
      final strings = TpFileSelectionStrings.english();

      await tester.pumpWidget(
        _wrap(
          TpFilesystemTab(
            deps: _deps(filesystem: filesystem, permission: permission),
            options: const TpFileSelectionOptions(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.storagePermissionRequired), findsOneWidget);
      expect(find.text(strings.goToSettings), findsOneWidget);

      await tester.tap(find.text(strings.goToSettings));
      await tester.pumpAndSettle();

      expect(permission.openAppSettingsCallCount, 1);
    });
  });
}
