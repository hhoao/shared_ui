/// Injected labels for [TpFileSelection] UI (not product ARB inside shared_ui).
class TpFileSelectionStrings {
  const TpFileSelectionStrings({
    required this.actionClear,
    required this.actionConfirm,
    required this.actionConfirmWithCount,
    required this.actionCreate,
    required this.actionReload,
    required this.actionSearch,
    required this.addSelectedFiles,
    required this.albumAllMediaSubtitle,
    required this.albumCount,
    required this.appFoldersTab,
    required this.authorize,
    required this.calculating,
    required this.calculatingFileSize,
    required this.cannotAccessDirectory,
    required this.checkAlbumPermissionOrEmpty,
    required this.clearSearch,
    required this.clearSelection,
    required this.copyPath,
    required this.createFolderFailedWithError,
    required this.createFolderHere,
    required this.createdAtWithValue,
    required this.currentDirectoryLabel,
    required this.deselectAll,
    required this.enterKeywordToStartSearch,
    required this.enterSearchKeyword,
    required this.entityInfoDateAndItemCount,
    required this.featureNotSupportedOnDesktop,
    required this.fileSizeLabel,
    required this.filterAll,
    required this.folderAlreadyExists,
    required this.folderCreatedSuccess,
    required this.folderEmpty,
    required this.folderInfo,
    required this.folderNameHint,
    required this.foundFileCount,
    required this.fullDiskSearchTab,
    required this.galleryPermissionMessage,
    required this.galleryPermissionRequired,
    required this.getFolderInfoFailed,
    required this.goToSettings,
    required this.imageFileLabel,
    required this.imageLabel,
    required this.infoCreatedAt,
    required this.infoFileCount,
    required this.infoFolderCount,
    required this.infoModifiedAt,
    required this.infoPath,
    required this.infoTotalItems,
    required this.inputFileNameHint,
    required this.inputFileNameKeywordHint,
    required this.inputKeywordHint,
    required this.itemCountUnit,
    required this.itemTypeDirectory,
    required this.itemTypeFile,
    required this.itemTypeItem,
    required this.loadAlbumFailed,
    required this.loadAlbumFailedWithError,
    required this.loadMore,
    required this.loadMoreFailedWithError,
    required this.loading,
    required this.maxSelectionCountReached,
    required this.maxSelectionCountReachedFor,
    required this.mediaItemCount,
    required this.mediaTypeAll,
    required this.mediaTypeImage,
    required this.mediaTypeVideo,
    required this.newFolder,
    required this.noAlbumsFound,
    required this.noItemsSelected,
    required this.noMatchingFiles,
    required this.noMatchingMediaFiles,
    required this.noMediaFiles,
    required this.openThisFolder,
    required this.pathCopiedToClipboard,
    required this.pathNotFound,
    required this.phoneStorageTab,
    required this.previewTitle,
    required this.quickAccessCamera,
    required this.quickAccessDocuments,
    required this.quickAccessDownload,
    required this.quickAccessPictures,
    required this.quickAccessVideos,
    required this.searchFailedWithError,
    required this.searchFilesTitle,
    required this.searchMediaTitle,
    required this.searchPathDcim,
    required this.searchPathDocuments,
    required this.searchPathDownload,
    required this.searchPathEntireStorage,
    required this.searchPathMovies,
    required this.searchPathMusic,
    required this.searchPathPictures,
    required this.searchResultsAdded,
    required this.searchScope,
    required this.searching,
    required this.searchingFiles,
    required this.selectAlbum,
    required this.selectAll,
    required this.selectDirectoryPrompt,
    required this.selectDirectoryTitle,
    required this.selectFilesAndDirectoriesTitle,
    required this.selectFilesOrDirectoriesPrompt,
    required this.selectFilesPrompt,
    required this.selectFilesTitle,
    required this.selectImagesTitle,
    required this.selectMediaTitle,
    required this.selectThisDirectory,
    required this.selectVideosTitle,
    required this.selectedCountShort,
    required this.selectedFirstNItems,
    required this.selectionSummaryDirsOnly,
    required this.selectionSummaryFilesAndDirs,
    required this.selectionSummaryFilesOnly,
    required this.selectionSummaryItems,
    required this.sortByFileSize,
    required this.sortByFileType,
    required this.sortByModifiedTime,
    required this.sortByName,
    required this.sortOptionsTitle,
    required this.storagePermissionRequired,
    required this.switchTabClearSelectionMessage,
    required this.switchTabTitle,
    required this.switchToGridMode,
    required this.switchToListMode,
    required this.tabFiles,
    required this.tabPhotoGallery,
    required this.taskStatusCancelledShort,
    required this.tryModifySearchConditions,
    required this.videoFileLabel,
    required this.videoLabel,
    required this.videoPlayerFileMovedOrDeleted,
    required this.videoPlayerFileNotFound,
  });

  final String actionClear;
  final String actionConfirm;
  final String Function(int count) actionConfirmWithCount;
  final String actionCreate;
  final String actionReload;
  final String actionSearch;
  final String Function(int count) addSelectedFiles;
  final String Function(String mediaType) albumAllMediaSubtitle;
  final String Function(int count) albumCount;
  final String appFoldersTab;
  final String authorize;
  final String calculating;
  final String calculatingFileSize;
  final String Function(String error) cannotAccessDirectory;
  final String checkAlbumPermissionOrEmpty;
  final String clearSearch;
  final String clearSelection;
  final String copyPath;
  final String Function(String error) createFolderFailedWithError;
  final String createFolderHere;
  final String Function(String time) createdAtWithValue;
  final String currentDirectoryLabel;
  final String deselectAll;
  final String enterKeywordToStartSearch;
  final String enterSearchKeyword;
  final String Function(String date, int count) entityInfoDateAndItemCount;
  final String featureNotSupportedOnDesktop;
  final String Function(String size) fileSizeLabel;
  final String filterAll;
  final String folderAlreadyExists;
  final String folderCreatedSuccess;
  final String folderEmpty;
  final String folderInfo;
  final String folderNameHint;
  final String Function(int count) foundFileCount;
  final String fullDiskSearchTab;
  final String galleryPermissionMessage;
  final String galleryPermissionRequired;
  final String Function(String error) getFolderInfoFailed;
  final String goToSettings;
  final String imageFileLabel;
  final String imageLabel;
  final String infoCreatedAt;
  final String infoFileCount;
  final String infoFolderCount;
  final String infoModifiedAt;
  final String infoPath;
  final String infoTotalItems;
  final String inputFileNameHint;
  final String inputFileNameKeywordHint;
  final String inputKeywordHint;
  final String Function(int count) itemCountUnit;
  final String itemTypeDirectory;
  final String itemTypeFile;
  final String itemTypeItem;
  final String loadAlbumFailed;
  final String Function(String error) loadAlbumFailedWithError;
  final String loadMore;
  final String Function(String error) loadMoreFailedWithError;
  final String loading;
  final String Function(int count) maxSelectionCountReached;
  final String Function(int count, String itemType) maxSelectionCountReachedFor;
  final String Function(int count, String mediaType) mediaItemCount;
  final String mediaTypeAll;
  final String mediaTypeImage;
  final String mediaTypeVideo;
  final String newFolder;
  final String noAlbumsFound;
  final String noItemsSelected;
  final String noMatchingFiles;
  final String Function(String mediaType) noMatchingMediaFiles;
  final String Function(String mediaType) noMediaFiles;
  final String openThisFolder;
  final String pathCopiedToClipboard;
  final String Function(String path) pathNotFound;
  final String phoneStorageTab;
  final String previewTitle;
  final String quickAccessCamera;
  final String quickAccessDocuments;
  final String quickAccessDownload;
  final String quickAccessPictures;
  final String quickAccessVideos;
  final String Function(String error) searchFailedWithError;
  final String searchFilesTitle;
  final String searchMediaTitle;
  final String searchPathDcim;
  final String searchPathDocuments;
  final String searchPathDownload;
  final String searchPathEntireStorage;
  final String searchPathMovies;
  final String searchPathMusic;
  final String searchPathPictures;
  final String Function(int count) searchResultsAdded;
  final String searchScope;
  final String searching;
  final String searchingFiles;
  final String selectAlbum;
  final String selectAll;
  final String selectDirectoryPrompt;
  final String selectDirectoryTitle;
  final String selectFilesAndDirectoriesTitle;
  final String selectFilesOrDirectoriesPrompt;
  final String selectFilesPrompt;
  final String selectFilesTitle;
  final String selectImagesTitle;
  final String selectMediaTitle;
  final String selectThisDirectory;
  final String selectVideosTitle;
  final String Function(int count) selectedCountShort;
  final String Function(int count) selectedFirstNItems;
  final String Function(String dirCount) selectionSummaryDirsOnly;
  final String Function(String fileCount, String dirCount)
      selectionSummaryFilesAndDirs;
  final String Function(String fileCount) selectionSummaryFilesOnly;
  final String Function(int count) selectionSummaryItems;
  final String sortByFileSize;
  final String sortByFileType;
  final String sortByModifiedTime;
  final String sortByName;
  final String sortOptionsTitle;
  final String storagePermissionRequired;
  final String switchTabClearSelectionMessage;
  final String switchTabTitle;
  final String switchToGridMode;
  final String switchToListMode;
  final String tabFiles;
  final String tabPhotoGallery;
  final String taskStatusCancelledShort;
  final String tryModifySearchConditions;
  final String videoFileLabel;
  final String videoLabel;
  final String Function(String path) videoPlayerFileMovedOrDeleted;
  final String videoPlayerFileNotFound;

  /// English placeholders for tests.
  factory TpFileSelectionStrings.english() {
    return TpFileSelectionStrings(
      actionClear: 'Clear',
      actionConfirm: 'Confirm',
      actionConfirmWithCount: (count) => 'Confirm ($count)',
      actionCreate: 'Create',
      actionReload: 'Reload',
      actionSearch: 'Search',
      addSelectedFiles: (count) => 'Add $count file(s)',
      albumAllMediaSubtitle: (mediaType) => 'All $mediaType files',
      albumCount: (count) => '$count album(s)',
      appFoldersTab: 'App folders',
      authorize: 'Authorize',
      calculating: 'Calculating...',
      calculatingFileSize: 'Calculating size...',
      cannotAccessDirectory: (error) => 'Cannot access this directory: $error',
      checkAlbumPermissionOrEmpty:
          'Check album permissions or whether albums are empty',
      clearSearch: 'Clear search',
      clearSelection: 'Clear selection',
      copyPath: 'Copy path',
      createFolderFailedWithError: (error) => 'Failed to create folder: $error',
      createFolderHere: 'New folder here',
      createdAtWithValue: (time) => 'Created: $time',
      currentDirectoryLabel: 'Current directory',
      deselectAll: 'Deselect all',
      enterKeywordToStartSearch: 'Enter a keyword to start searching',
      enterSearchKeyword: 'Enter a search keyword',
      entityInfoDateAndItemCount: (date, count) => '$date $count items',
      featureNotSupportedOnDesktop:
          'This feature is not supported on desktop',
      fileSizeLabel: (size) => 'Size: $size',
      filterAll: 'All',
      folderAlreadyExists: 'Folder already exists',
      folderCreatedSuccess: 'Folder created',
      folderEmpty: 'This folder is empty',
      folderInfo: 'Folder info',
      folderNameHint: 'Enter folder name',
      foundFileCount: (count) => 'Found $count file(s)',
      fullDiskSearchTab: 'Search all',
      galleryPermissionMessage:
          'To select photos and videos, grant photo library access in Settings.',
      galleryPermissionRequired: 'Photo library access required',
      getFolderInfoFailed: (error) => 'Failed to get folder info: $error',
      goToSettings: 'Go to settings',
      imageFileLabel: 'Image file',
      imageLabel: 'Image',
      infoCreatedAt: 'Created',
      infoFileCount: 'Files',
      infoFolderCount: 'Folders',
      infoModifiedAt: 'Modified',
      infoPath: 'Path',
      infoTotalItems: 'Total items',
      inputFileNameHint: 'Enter file name...',
      inputFileNameKeywordHint: 'Enter file name keyword...',
      inputKeywordHint: 'Enter keyword...',
      itemCountUnit: (count) => '$count',
      itemTypeDirectory: 'directory',
      itemTypeFile: 'file',
      itemTypeItem: 'item',
      loadAlbumFailed: 'Failed to load albums',
      loadAlbumFailedWithError: (error) => 'Failed to load albums: $error',
      loadMore: 'Load more...',
      loadMoreFailedWithError: (error) => 'Failed to load more: $error',
      loading: 'Loading...',
      maxSelectionCountReached: (count) => 'You can select at most $count file(s)',
      maxSelectionCountReachedFor: (count, itemType) =>
          'You can select at most $count $itemType',
      mediaItemCount: (count, mediaType) => '$count $mediaType',
      mediaTypeAll: 'media',
      mediaTypeImage: 'images',
      mediaTypeVideo: 'videos',
      newFolder: 'New folder',
      noAlbumsFound: 'No albums found',
      noItemsSelected: 'No items selected',
      noMatchingFiles: 'No matching files found',
      noMatchingMediaFiles: (mediaType) =>
          'No matching $mediaType files found',
      noMediaFiles: (mediaType) => 'No $mediaType files found',
      openThisFolder: 'Open this folder',
      pathCopiedToClipboard: 'Path copied to clipboard',
      pathNotFound: (path) => 'Path not found: $path',
      phoneStorageTab: 'Phone storage',
      previewTitle: 'Preview',
      quickAccessCamera: 'Camera',
      quickAccessDocuments: 'Documents',
      quickAccessDownload: 'Downloads',
      quickAccessPictures: 'Pictures',
      quickAccessVideos: 'Videos',
      searchFailedWithError: (error) => 'Search failed: $error',
      searchFilesTitle: 'Search files',
      searchMediaTitle: 'Search media',
      searchPathDcim: 'DCIM / Camera',
      searchPathDocuments: 'Documents folder',
      searchPathDownload: 'Downloads folder',
      searchPathEntireStorage: 'Entire storage',
      searchPathMovies: 'Movies folder',
      searchPathMusic: 'Music folder',
      searchPathPictures: 'Pictures folder',
      searchResultsAdded: (count) => 'Added $count search result(s) to selection',
      searchScope: 'Search scope',
      searching: 'Searching...',
      searchingFiles: 'Searching files...',
      selectAlbum: 'Select album',
      selectAll: 'Select all',
      selectDirectoryPrompt: 'Please select a directory',
      selectDirectoryTitle: 'Select directory',
      selectFilesAndDirectoriesTitle: 'Select files and directories',
      selectFilesOrDirectoriesPrompt: 'Please select file(s) or directory',
      selectFilesPrompt: 'Please select file(s)',
      selectFilesTitle: 'Select files',
      selectImagesTitle: 'Select images',
      selectMediaTitle: 'Select media',
      selectThisDirectory: 'Select this directory',
      selectVideosTitle: 'Select videos',
      selectedCountShort: (count) => 'Selected: $count',
      selectedFirstNItems: (count) => 'Selected first $count item(s)',
      selectionSummaryDirsOnly: (dirCount) => ' ($dirCount dirs)',
      selectionSummaryFilesAndDirs: (fileCount, dirCount) =>
          ' ($fileCount files, $dirCount dirs)',
      selectionSummaryFilesOnly: (fileCount) => ' ($fileCount files)',
      selectionSummaryItems: (count) => '$count items',
      sortByFileSize: 'File size',
      sortByFileType: 'File type',
      sortByModifiedTime: 'Modified time',
      sortByName: 'Name',
      sortOptionsTitle: 'Sort by',
      storagePermissionRequired:
          'Storage permission is required to access files',
      switchTabClearSelectionMessage:
          'Switching tabs will clear your current selection. Continue?',
      switchTabTitle: 'Switch tab',
      switchToGridMode: 'Switch to grid view',
      switchToListMode: 'Switch to list view',
      tabFiles: 'Files',
      tabPhotoGallery: 'Gallery',
      taskStatusCancelledShort: 'Cancelled',
      tryModifySearchConditions: 'Try changing your search',
      videoFileLabel: 'Video file',
      videoLabel: 'Video',
      videoPlayerFileMovedOrDeleted: (path) =>
          'The file was moved or deleted:\n$path',
      videoPlayerFileNotFound: 'File not found',
    );
  }
}
