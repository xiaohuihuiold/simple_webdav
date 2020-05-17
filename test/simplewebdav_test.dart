import 'package:flutter_test/flutter_test.dart';

import 'package:simple_webdav/simple_webdav.dart';

void main() {
  test(
    '',
    () async {
      WebDAVClient client = WebDAVClient(
        'https://dav.jianguoyun.com/dav/',
        authenticate: WebDAVClient.encodeAuth(
          name: '@qq.com',
          password: '',
        ),
      );
      WebDAVFile root = WebDAVFile(client: client, path: '/dav/timeNote');
      print(await root.listFiles());
    },
    timeout: Timeout(Duration(days: 1)),
  );
}
