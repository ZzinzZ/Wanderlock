import 'dart:io';

/// The repository root, found by walking up from the running script.
///
/// Every tool needs this and every tool used to work it out for itself, by
/// counting how many directories up from `Platform.script` the root was. The
/// scripts at `tool/` counted one and the ones in `tool/coord_verify/` and
/// `tool/photo_picker/` counted two — so moving a script one directory
/// silently produced a wrong root, and the failure was a "file not found" for
/// a path that plainly exists.
///
/// This looks for the root instead of counting to it: the directory holding
/// both `content/` and `tool/`. A script can then live anywhere under the
/// repository.
Directory repoRoot() {
  var directory = Directory(
    Platform.script.toFilePath().replaceAll(r'\', '/'),
  ).parent;

  while (true) {
    final path = directory.path.replaceAll(r'\', '/');
    if (Directory('$path/content').existsSync() &&
        Directory('$path/tool').existsSync()) {
      return Directory(path);
    }

    final parent = directory.parent;
    if (parent.path == directory.path) {
      stderr.writeln(
        'repoRoot: không tìm thấy gốc kho mã phía trên ${Platform.script}. '
        'Gốc là thư mục chứa cả content/ lẫn tool/.',
      );
      exit(1);
    }
    directory = parent;
  }
}

/// [repoRoot] as a forward-slash path, which is what every caller wants:
/// paths are built by string interpolation and Windows backslashes make a
/// mess of that.
String repoRootPath() => repoRoot().path.replaceAll(r'\', '/');
