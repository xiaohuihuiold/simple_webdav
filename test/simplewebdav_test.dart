import 'package:flutter_test/flutter_test.dart';

import 'package:simple_webdav/simple_webdav.dart';

void main() {
  test('',
        () async {
      /* WebDAVClient client = WebDAVClient(
        'https://dav.jianguoyun.com/',
        authenticate: WebDAVClient.encodeAuth(
          name: '',
          password: '',
        ),
      );
      WebDAVFile root = WebDAVFile(client: client, path: 'dav/');
      List<WebDAVFile> files = await root.listFiles();
      print(files);*/
      String path;
      String host = 'https://dav.jianguoyun.com/webdav/';
      if (host != null && host.endsWith('/')) {
        host = host.substring(0, host.length - 1);
        if (path == null) {
          List<String> paths = host.split('/');
          if (paths.length > 3) {
            path = paths.last;
            host=host.replaceAll(RegExp('$path\$'), '');
          }
        }
      }
      print(host);
      print(path);
    },
    timeout: Timeout(Duration(days: 1)),
  );
}
