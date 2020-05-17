import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;

class WebDAVClient {
  String host;
  String path;
  String authenticate;
  int port;
  Dio _dio;

  bool get isAvailable => host != null && authenticate != null;

  Map<String, dynamic> get headers => _dio.options.headers;

  WebDAVClient(
    this.host, {
    this.port,
    this.authenticate,
  }) {
    if (host != null && host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
      List<String> paths = host.split('/');
      if (paths.length > 3) {
        path = paths.last;
        host = host.replaceAll(RegExp('$path\$'), '');
        host = host.substring(0, host.length - 1);
      }
    }
    if (path != null) {
      if (path.startsWith('/')) {
        path = path.substring(1, path.length);
      }
      if (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: '$host${port != null ? ':$port' : ''}',
        headers: {
          'authorization': 'Basic $authenticate',
        },
      ),
    );
  }

  Future<void> _upload({
    @required WebDAVFile folder,
    @required String filePath,
    String fileName,
  }) async {
    fileName ??= filePath.split('/').last;
    await _dio.put(
      '${folder.path}$fileName',
      data: File(filePath).openRead(),
    );
  }

  Future<void> _download({
    @required WebDAVFile file,
    @required String savePath,
    ProgressCallback onReceiveProgress,
  }) async {
    await _dio.download(
      file.path,
      savePath,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<bool> _mkdir(WebDAVFile folder) async {
    _dio.options.method = 'MKCOL';
    Response response = await _dio.request(folder.path);
    if (response.statusCode == 301) {
      return false;
    } else if (response.statusCode == 207) {
      return false;
    }
    return true;
  }

  Future<bool> _exists(WebDAVFile folder) async {
    _dio.options.method = 'PROPFIND';
    try {
      Response response = await _dio.request(folder.path);
    } on DioError catch (e) {
      if (e?.response?.statusCode != 200) {
        return false;
      }
    } catch (e) {
      return null;
    }
    return true;
  }

  Future<List<WebDAVFile>> _listFiles(WebDAVFile folder) async {
    _dio.options.method = 'PROPFIND';
    Response response = await _dio.request(folder.path);
    if (response.statusCode == 301) {
      return null;
    } else if (response.statusCode != 207) {
      return null;
    }
    xml.XmlDocument document;
    try {
      document = xml.parse(response.data);
    } on xml.XmlParserException catch (e) {
      print(e);
      return null;
    }
    // print(document.toXmlString(pretty: true));
    Iterable<xml.XmlElement> responses = document.findAllElements('d:response');
    return responses.map((xml.XmlElement element) {
      WebDAVFile file = WebDAVFile(client: this);
      file._parent = folder;

      Iterable<xml.XmlElement> paths = element.findElements('d:href');
      if (paths.isNotEmpty) {
        String path = paths.first.text;
        file._path = path;
      }

      Iterable<xml.XmlElement> names = element.findAllElements('d:displayname');
      if (names.isNotEmpty) {
        String name = names.first.text;
        file._name = name;
      }

      Iterable<xml.XmlElement> lengths =
          element.findAllElements('d:getcontentlength');
      if (lengths.isNotEmpty) {
        String length = lengths.first.text;
        file._length = int.tryParse(length);
      }

      Iterable<xml.XmlElement> dates =
          element.findAllElements('d:getlastmodified');
      if (dates.isNotEmpty) {
        String date = dates.first.text;
        file._date = date;
      }

      Iterable<xml.XmlElement> types =
          element.findAllElements('d:getcontenttype');
      if (types.isNotEmpty) {
        String type = types.first.text;
        file._type = type;
        file._isFile = !(type == 'httpd/unix-directory');
      }

      return file;
    }).toList();
  }

  static String encodeAuth({
    @required String name,
    @required String password,
  }) {
    return base64.encode(utf8.encode('$name:$password'));
  }
}

class WebDAVFile {
  bool _isFile = false;

  bool get isFile => _isFile;

  bool get isDirectory => !isFile;

  String _path;

  String get path => _path;

  String get url => '${client._dio.options.baseUrl}$path';

  String _name;

  String get name => _name;

  int _length;

  int get length => _length;

  String _date;

  String get date => _date;

  String _type;

  String get type => _type;

  WebDAVFile _parent;

  WebDAVFile get parent => _parent;

  WebDAVClient _client;

  WebDAVClient get client => _client;

  WebDAVFile({
    @required WebDAVClient client,
    String path = '/',
  }) {
    _client = client;
    _path = path;
    if (!_path.startsWith('/')) {
      _path = '/$_path';
    }
  }

  Future<List<WebDAVFile>> listFiles() async {
    if (isFile) {
      return null;
    }
    return await client._listFiles(this);
  }

  Future<bool> mkdir() async {
    if (isFile) {
      return false;
    }
    return await client._mkdir(this);
  }

  Future<bool> exists() async {
    return await client._exists(this);
  }

  Future<void> save({
    @required String savePath,
    ProgressCallback onReceiveProgress,
  }) async {
    if (isDirectory) {
      return;
    }
    await client._download(
      file: this,
      savePath: savePath,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<void> upload({
    @required String filePath,
    String fileName,
  }) async {
    if (isFile) {
      return;
    }
    await client._upload(
      folder: this,
      filePath: filePath,
      fileName: fileName,
    );
  }

  @override
  String toString() {
    return 'WebDAVFile($name,$isFile,$length,$date,$path)';
  }
}
