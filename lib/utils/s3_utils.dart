import 'dart:io';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

/// S3 工具类
///
/// 提供 S3 兼容存储服务的基本操作，包括上传、下载和列出文件。
class S3Utils {
  /// 上传文件到 S3 兼容存储
  ///
  /// [filePath] 本地文件路径
  /// [endpoint] S3 兼容存储端点
  /// [bucketName] 桶名
  /// [objectKey] 对象键（文件名）
  /// [accessKeyId] 访问密钥 ID
  /// [secretAccessKey] 秘密访问密钥
  ///
  /// 执行步骤：
  /// 1. 读取本地文件内容
  /// 2. 构建 HTTP PUT 请求
  /// 3. 设置请求头，包括内容类型、内容长度和认证信息
  /// 4. 发送请求并检查响应状态码
  /// 5. 如果上传失败，抛出异常
  static Future<void> uploadFile(
    String filePath,
    String endpoint,
    String bucketName,
    String objectKey,
    String accessKeyId,
    String secretAccessKey,
  ) async {
    final file = File(filePath);
    final fileBytes = await file.readAsBytes();

    final uri = Uri.parse('$endpoint/$bucketName/$objectKey');

    // 构建 AWS 签名
    final credentials = AWSCredentials(accessKeyId, secretAccessKey);

    // 创建签名器
    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(credentials),
    );

    // 构建签名范围
    final region = 'us-east-1'; // 默认区域，可根据实际情况调整
    final scope = AWSCredentialScope(region: region, service: AWSService.s3);

    // 构建 AWS HTTP 请求
    final awsRequest = AWSHttpRequest(
      method: AWSHttpMethod.put,
      uri: uri,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Length': fileBytes.length.toString(),
      },
      body: fileBytes,
    );

    // 生成签名
    final signedRequest = await signer.sign(awsRequest, credentialScope: scope);

    // 构建 HTTP 请求
    final request = http.Request('PUT', uri)
      ..bodyBytes = fileBytes
      ..headers.addAll(signedRequest.headers);

    // 设置30秒超时
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw HttpException('S3 上传超时', uri: uri);
      },
    );
    if (response.statusCode != 200) {
      throw HttpException('S3 上传失败: HTTP ${response.statusCode}', uri: uri);
    }
  }

  /// 从 S3 兼容存储下载文件
  ///
  /// [endpoint] S3 兼容存储端点
  /// [bucketName] 桶名
  /// [objectKey] 对象键（文件名）
  /// [accessKeyId] 访问密钥 ID
  /// [secretAccessKey] 秘密访问密钥
  /// [savePath] 本地保存路径
  static Future<File> downloadFile(
    String endpoint,
    String bucketName,
    String objectKey,
    String accessKeyId,
    String secretAccessKey,
    String savePath,
  ) async {
    final uri = Uri.parse('$endpoint/$bucketName/$objectKey');

    // 构建 AWS 签名
    final credentials = AWSCredentials(accessKeyId, secretAccessKey);

    // 创建签名器
    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(credentials),
    );

    // 构建签名范围
    final region = 'us-east-1'; // 默认区域，可根据实际情况调整
    final scope = AWSCredentialScope(region: region, service: AWSService.s3);

    // 构建 AWS HTTP 请求
    final awsRequest = AWSHttpRequest(
      method: AWSHttpMethod.get,
      uri: uri,
      headers: {},
    );

    // 生成签名
    final signedRequest = await signer.sign(awsRequest, credentialScope: scope);

    // 构建 HTTP 请求
    final request = http.Request('GET', uri)
      ..headers.addAll(signedRequest.headers);

    // 设置30秒超时
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw HttpException('S3 下载超时', uri: uri);
      },
    );
    if (response.statusCode != 200) {
      throw HttpException('S3 下载失败: HTTP ${response.statusCode}', uri: uri);
    }

    final file = File(savePath);
    await response.stream.pipe(file.openWrite());
    return file;
  }

  /// 列出 S3 桶中的对象
  ///
  /// [endpoint] S3 兼容存储端点
  /// [bucketName] 桶名
  /// [accessKeyId] 访问密钥 ID
  /// [secretAccessKey] 秘密访问密钥
  static Future<List<String>> listObjects(
    String endpoint,
    String bucketName,
    String accessKeyId,
    String secretAccessKey,
  ) async {
    final uri = Uri.parse('$endpoint/$bucketName?list-type=2');

    // 构建 AWS 签名
    final credentials = AWSCredentials(accessKeyId, secretAccessKey);

    // 创建签名器
    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(credentials),
    );

    // 构建签名范围
    final region = 'us-east-1'; // 默认区域，可根据实际情况调整
    final scope = AWSCredentialScope(region: region, service: AWSService.s3);

    // 构建 AWS HTTP 请求
    final awsRequest = AWSHttpRequest(
      method: AWSHttpMethod.get,
      uri: uri,
      headers: {},
    );

    // 生成签名
    final signedRequest = await signer.sign(awsRequest, credentialScope: scope);

    // 构建 HTTP 请求
    final request = http.Request('GET', uri)
      ..headers.addAll(signedRequest.headers);

    // 设置30秒超时
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw HttpException('S3 列出文件超时', uri: uri);
      },
    );
    if (response.statusCode != 200) {
      throw HttpException('S3 列出文件失败: HTTP ${response.statusCode}', uri: uri);
    }

    final responseBody = await response.stream.bytesToString();
    return _parseObjectList(responseBody);
  }

  /// 解析 S3 ListObjectsV2 响应
  static List<String> _parseObjectList(String xmlBody) {
    final document = xml.XmlDocument.parse(xmlBody);
    final objects = <String>[];

    for (final contents in document.findAllElements('Contents')) {
      final keyElements = contents.findElements('Key');
      if (keyElements.isEmpty) continue;
      objects.add(keyElements.first.innerText);
    }

    return objects;
  }

  /// 删除 S3 兼容存储中的对象
  ///
  /// [endpoint] S3 兼容存储端点
  /// [bucketName] 桶名
  /// [objectKey] 对象键（文件名）
  /// [accessKeyId] 访问密钥 ID
  /// [secretAccessKey] 秘密访问密钥
  ///
  /// 执行步骤：
  /// 1. 构建请求 URI
  /// 2. 构建 AWS 签名
  /// 3. 创建签名器
  /// 4. 构建签名范围
  /// 5. 构建 AWS HTTP 请求
  /// 6. 生成签名
  /// 7. 构建 HTTP 请求
  /// 8. 发送请求并检查响应状态码
  /// 9. 如果删除失败，抛出异常
  static Future<void> deleteObject(
    String endpoint,
    String bucketName,
    String objectKey,
    String accessKeyId,
    String secretAccessKey,
  ) async {
    /// 构建请求 URI
    final uri = Uri.parse('$endpoint/$bucketName/$objectKey');

    /// 构建 AWS 签名
    final credentials = AWSCredentials(accessKeyId, secretAccessKey);

    /// 创建签名器
    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(credentials),
    );

    /// 构建签名范围
    final region = 'us-east-1'; // 默认区域，可根据实际情况调整
    final scope = AWSCredentialScope(region: region, service: AWSService.s3);

    /// 构建 AWS HTTP 请求
    final awsRequest = AWSHttpRequest(
      method: AWSHttpMethod.delete,
      uri: uri,
      headers: {},
    );

    /// 生成签名
    final signedRequest = await signer.sign(awsRequest, credentialScope: scope);

    /// 构建 HTTP 请求
    final request = http.Request('DELETE', uri)
      ..headers.addAll(signedRequest.headers);

    /// 发送请求并检查响应状态码，设置30秒超时
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw HttpException('S3 删除超时', uri: uri);
      },
    );
    if (response.statusCode != 204) {
      throw HttpException('S3 删除失败: HTTP ${response.statusCode}', uri: uri);
    }
  }
}
