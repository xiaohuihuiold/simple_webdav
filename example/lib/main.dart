import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:simple_webdav/simple_webdav.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  WebDAVClient client = WebDAVClient(
    'https://dav.jianguoyun.com/',
    authenticate: WebDAVClient.encodeAuth(
      name: '',
      password: '',
    ),
  );
  List<WebDAVFile> _files = List();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      WebDAVFile root = WebDAVFile(client: client, path: 'dav/');
      List<WebDAVFile> files = await root.listFiles();
      _files.clear();
      _files.addAll(files);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebDAV'),
      ),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (_, int index) {
          WebDAVFile file = _files[index];
          if (index == 0 && file.parent?.parent != null) {
            file = file.parent.parent;
          }
          return ListTile(
            leading: AspectRatio(
              aspectRatio: 1.0,
              child: file.isDirectory
                  ? Icon(Icons.folder_open)
                  : file.type.contains('image')
                      ? Image.network(
                          file.url,
                          headers: client.headers.map((key, value) =>
                              MapEntry<String, String>('$key', '$value')),
                          fit: BoxFit.cover,
                          errorBuilder: (_, a, b) {
                            return Icon(Icons.insert_drive_file);
                          },
                        )
                      : Icon(Icons.insert_drive_file),
            ),
            title: index == 0 ? Text('...') : Text(file.name ?? ''),
            subtitle: index == 0 ? null : Text(file.date ?? ''),
            trailing: file.isFile
                ? Text(
                    '${((file.length ?? 0) / 1024.0 / 1024.0).toStringAsFixed(2)}MiB')
                : null,
            onTap: () async {
              if (file.isDirectory) {
                List<WebDAVFile> files = await file.listFiles();
                _files.clear();
                _files.addAll(files);
                setState(() {});
              }
            },
          );
        },
      ),
    );
  }
}
