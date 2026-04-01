import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

/// WebDAV 工具类
///
/// 提供 WebDAV 存储服务的基本操作，包括上传、下载和列出文件。
class WebDavUtils {
  /// 上传文件到 WebDAV 服务器
  ///
  /// [filePath] 本地文件路径
  /// [url] WebDAV 服务器 URL
  /// [username] 用户名
  /// [password] 密码
  ///
  /// 执行步骤：
  /// 1. 读取本地文件内容
  /// 2. 确保目标目录存在
  /// 3. 构建 HTTP PUT 请求
  /// 4. 设置请求头，包括内容类型、内容长度和认证信息
  /// 5. 发送请求并检查响应状态码
  /// 6. 如果上传失败，抛出异常
  static Future<void> uploadFile(
    String filePath,
    String url,
    String username,
    String password,
  ) async {
    final file = File(filePath);
    final fileBytes = await file.readAsBytes();

    final uri = Uri.parse(url);
    debugPrint('WebDAV 上传: url=$url, uri=$uri, fileSize=${fileBytes.length}');

    final authHeader = _buildBasicAuth(username, password);

    final response = await http
        .put(
          uri,
          headers: {
            'Content-Type': 'application/octet-stream',
            'Authorization': authHeader,
          },
          body: fileBytes,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw HttpException('WebDAV 上传超时', uri: uri);
          },
        );

    debugPrint('WebDAV 上传响应: statusCode=${response.statusCode}');

    if (response.statusCode == 201 ||
        response.statusCode == 204 ||
        response.statusCode == 200) {
      return;
    }

    // 409 Conflict 可能是目录不存在，尝试创建目录后重试
    if (response.statusCode == 409) {
      debugPrint('WebDAV 上传收到409，尝试创建父目录后重试');
      final pathSegments = uri.pathSegments;
      if (pathSegments.length > 1) {
        // 构建父目录路径
        final parentPath = pathSegments
            .sublist(0, pathSegments.length - 1)
            .join('/');
        final parentUri = uri.replace(path: '/$parentPath');
        debugPrint('WebDAV 尝试创建目录: $parentUri');

        final mkcolRequest = http.Request('MKCOL', parentUri)
          ..headers['Authorization'] = authHeader;
        final streamedResponse = await http.Client()
            .send(mkcolRequest)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw HttpException('WebDAV 创建目录超时', uri: parentUri);
              },
            );
        final mkcolBody = await streamedResponse.stream.bytesToString();
        debugPrint(
          'WebDAV 创建目录响应: statusCode=${streamedResponse.statusCode}, body=$mkcolBody',
        );

        // 201 Created 或 405 Method Not Allowed(目录已存在) 都表示成功
        if (streamedResponse.statusCode == 201 ||
            streamedResponse.statusCode == 405) {
          // 重试上传
          final retryResponse = await http
              .put(
                uri,
                headers: {
                  'Content-Type': 'application/octet-stream',
                  'Authorization': authHeader,
                },
                body: fileBytes,
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw HttpException('WebDAV 上传超时', uri: uri);
                },
              );
          debugPrint('WebDAV 重试上传响应: statusCode=${retryResponse.statusCode}');
          if (retryResponse.statusCode == 201 ||
              retryResponse.statusCode == 204 ||
              retryResponse.statusCode == 200) {
            return;
          }
          final retryBody = retryResponse.body;
          debugPrint(
            'WebDAV 重试上传失败: statusCode=${retryResponse.statusCode}, body=$retryBody',
          );
          throw HttpException(
            'WebDAV 上传失败: HTTP ${retryResponse.statusCode}, $retryBody',
            uri: uri,
          );
        }
      }
    }

    final responseBody = response.body;
    debugPrint(
      'WebDAV 上传失败: statusCode=${response.statusCode}, body=$responseBody',
    );
    throw HttpException(
      'WebDAV 上传失败: HTTP ${response.statusCode}, $responseBody',
      uri: uri,
    );
  }

  /// 从 WebDAV 服务器下载文件
  ///
  /// [url] WebDAV 服务器 URL
  /// [username] 用户名
  /// [password] 密码
  /// [savePath] 本地保存路径
  static Future<File> downloadFile(
    String url,
    String username,
    String password,
    String savePath,
  ) async {
    final uri = Uri.parse(url);
    debugPrint('WebDAV 下载: url=$url');
    final request = http.Request('GET', uri)
      ..headers['Authorization'] = _buildBasicAuth(username, password);

    // 设置30秒超时
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw HttpException('WebDAV 下载超时', uri: uri);
      },
    );
    debugPrint('WebDAV 下载响应: statusCode=${response.statusCode}');
    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      debugPrint(
        'WebDAV 下载失败: statusCode=${response.statusCode}, body=$responseBody',
      );
      throw HttpException(
        'WebDAV 下载失败: HTTP ${response.statusCode}, $responseBody',
        uri: uri,
      );
    }

    final file = File(savePath);
    await response.stream.pipe(file.openWrite());
    return file;
  }

  /// 列出 WebDAV 目录中的文件名
  ///
  /// [url] WebDAV 服务器 URL
  /// [username] 用户名
  /// [password] 密码
  static Future<List<String>> listFiles(
    String url,
    String username,
    String password,
  ) async {
    // PROPFIND 需要 URL 以 / 结尾表示目录
    final normalizedUrl = url.endsWith('/') ? url : '$url/';
    final uri = Uri.parse(normalizedUrl);
    debugPrint('WebDAV 列出文件: url=$url, normalizedUrl=$normalizedUrl');
    final request = http.Request('PROPFIND', uri)
      ..headers.addAll({
        'Depth': '1',
        'Content-Type': 'application/xml; charset=utf-8',
        'Authorization': _buildBasicAuth(username, password),
      })
      ..body =
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<D:propfind xmlns:D="DAV:">'
          '<D:prop>'
          '<D:displayname/>'
          '<D:getlastmodified/>'
          '</D:prop>'
          '</D:propfind>';

    // 设置30秒超时
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw HttpException('WebDAV 列出文件超时', uri: uri);
      },
    );
    if (response.statusCode != 207) {
      final responseBody = await response.stream.bytesToString();
      debugPrint(
        'WebDAV 列出文件失败: statusCode=${response.statusCode}, body=$responseBody',
      );
      throw HttpException(
        'WebDAV 列出文件失败: HTTP ${response.statusCode}, $responseBody',
        uri: uri,
      );
    }

    final responseBody = await response.stream.bytesToString();
    return _parseFileList(responseBody);
  }

  /// 构建 HTTP Basic Auth 请求头
  static String _buildBasicAuth(String username, String password) {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $credentials';
  }

  /// 解析 WebDAV PROPFIND 响应
  static List<String> _parseFileList(String xmlBody) {
    final document = xml.XmlDocument.parse(xmlBody);
    final files = <String>[];

    // 坚果云使用 DAV: 命名空间，元素名可能是 <D:response> 或 <response>
    // 使用 localName 来匹配不考虑命名空间的元素名
    for (final element in document.descendantElements) {
      if (element.localName != 'response') continue;

      // 查找 href 子元素（可能是 <D:href> 或 <href>）
      String? href;
      for (final child in element.descendantElements) {
        if (child.localName == 'href') {
          href = child.innerText;
          break;
        }
      }
      if (href == null || href.isEmpty) continue;

      // 跳过目录（以/结尾）
      if (href.endsWith('/')) continue;

      // 提取文件名（取路径最后一部分）
      final fileName = href.split('/').last;
      if (fileName.isNotEmpty) {
        files.add(fileName);
      }
    }

    debugPrint('WebDAV 解析文件列表: $files');
    return files;
  }

  /// 删除 WebDAV 服务器上的文件
  ///
  /// [url] WebDAV 服务器 URL
  /// [username] 用户名
  /// [password] 密码
  ///
  /// 执行步骤：
  /// 1. 构建 HTTP DELETE 请求
  /// 2. 设置认证信息
  /// 3. 发送请求并检查响应状态码
  /// 4. 如果删除失败，抛出异常
  static Future<void> deleteFile(
    String url,
    String username,
    String password,
  ) async {
    /// 构建 HTTP DELETE 请求
    final uri = Uri.parse(url);
    final request = http.Request('DELETE', uri)
      ..headers['Authorization'] = _buildBasicAuth(username, password);

    /// 发送请求并检查响应状态码，设置30秒超时
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw HttpException('WebDAV 删除超时', uri: uri);
      },
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw HttpException('WebDAV 删除失败: HTTP ${response.statusCode}', uri: uri);
    }
  }
}
