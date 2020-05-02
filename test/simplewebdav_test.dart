import 'package:flutter_test/flutter_test.dart';

import 'package:simple_webdav/simple_webdav.dart';

void main() {
  test(
    '',
    () async {
      WebDAVClient client = WebDAVClient(
        'https://dav.jianguoyun.com/',
        authenticate: WebDAVClient.encodeAuth(
          name: '',
          password: '',
        ),
      );
      WebDAVFile root = WebDAVFile(client: client, path: 'dav/');
      List<WebDAVFile> files = await root.listFiles();
      print(files);
    },
    timeout: Timeout(Duration(days: 1)),
  );
}
