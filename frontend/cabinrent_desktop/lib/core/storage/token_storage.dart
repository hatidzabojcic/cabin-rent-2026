import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:win32/win32.dart';

/// Stores the refresh token encrypted with Windows DPAPI.
///
/// DPAPI binds the encrypted bytes to the current Windows user, so copying the
/// file to another account or computer does not expose the token.
class TokenStorage {
  static const _fileName = 'session.dat';
  static const _cryptProtectUiForbidden = 0x1;

  Future<void> saveRefreshToken(String token) async {
    final encrypted = _protect(Uint8List.fromList(utf8.encode(token)));
    final file = await _tokenFile();
    await file.parent.create(recursive: true);
    await file.writeAsBytes(encrypted, flush: true);
  }

  Future<String?> readRefreshToken() async {
    final file = await _tokenFile();
    if (!await file.exists()) return null;
    try {
      final decrypted = _unprotect(await file.readAsBytes());
      return utf8.decode(decrypted);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final file = await _tokenFile();
    if (await file.exists()) await file.delete();
  }

  Future<File> _tokenFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  Uint8List _protect(Uint8List bytes) => _transform(bytes, protect: true);
  Uint8List _unprotect(Uint8List bytes) => _transform(bytes, protect: false);

  Uint8List _transform(Uint8List bytes, {required bool protect}) {
    final inputBytes = calloc<Uint8>(bytes.length);
    final input = calloc<CRYPT_INTEGER_BLOB>();
    final output = calloc<CRYPT_INTEGER_BLOB>();
    try {
      inputBytes.asTypedList(bytes.length).setAll(0, bytes);
      input.ref
        ..cbData = bytes.length
        ..pbData = inputBytes;

      final result = protect
          ? CryptProtectData(
              input,
              null,
              null,
              null,
              _cryptProtectUiForbidden,
              output,
            )
          : CryptUnprotectData(
              input,
              null,
              null,
              null,
              _cryptProtectUiForbidden,
              output,
            );
      if (!result.value) {
        throw WindowsException(result.error.toHRESULT());
      }
      return Uint8List.fromList(
        output.ref.pbData.asTypedList(output.ref.cbData),
      );
    } finally {
      if (output.ref.pbData != nullptr) {
        HLOCAL(output.ref.pbData.cast()).close();
      }
      calloc.free(output);
      calloc.free(input);
      calloc.free(inputBytes);
    }
  }
}
