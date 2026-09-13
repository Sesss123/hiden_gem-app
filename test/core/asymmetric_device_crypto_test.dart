import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart' as dart_crypto;

Uint8List encodeBigIntToDerInt(BigInt n) {
  var bytes = <int>[];
  var temp = n;
  while (temp > BigInt.zero) {
    bytes.insert(0, (temp & BigInt.from(0xff)).toInt());
    temp = temp >> 8;
  }
  if (bytes.isEmpty) bytes = [0];
  if ((bytes[0] & 0x80) != 0) {
    bytes.insert(0, 0x00);
  }
  return Uint8List.fromList(bytes);
}

Uint8List encodeEcdsaSignatureToDer(BigInt r, BigInt s) {
  final rBytes = encodeBigIntToDerInt(r);
  final sBytes = encodeBigIntToDerInt(s);
  final seqLen = rBytes.length + sBytes.length + 4;
  final builder = BytesBuilder();
  builder.addByte(0x30);
  if (seqLen < 128) {
    builder.addByte(seqLen);
  } else {
    builder.addByte(0x81);
    builder.addByte(seqLen);
  }
  builder.addByte(0x02);
  builder.addByte(rBytes.length);
  builder.add(rBytes);
  builder.addByte(0x02);
  builder.addByte(sBytes.length);
  builder.add(sBytes);
  return builder.toBytes();
}

String exportEcPublicKeyToPem(ECPublicKey key) {
  final q = key.Q!;
  final x = q.x!.toBigInteger()!;
  final y = q.y!.toBigInteger()!;

  List<int> toPadded32(BigInt n) {
    final b = <int>[];
    var temp = n;
    while (temp > BigInt.zero) {
      b.insert(0, (temp & BigInt.from(0xff)).toInt());
      temp = temp >> 8;
    }
    while (b.length < 32) {
      b.insert(0, 0);
    }
    return b.sublist(b.length - 32);
  }

  final xBytes = toPadded32(x);
  final yBytes = toPadded32(y);

  // SPKI header for prime256v1 (secp256r1)
  final spkiHeader = [
    0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
    0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
    0x42, 0x00, 0x04
  ];

  final fullSpki = Uint8List.fromList([...spkiHeader, ...xBytes, ...yBytes]);
  final base64Spki = base64.encode(fullSpki);
  return '-----BEGIN PUBLIC KEY-----\n$base64Spki\n-----END PUBLIC KEY-----';
}

void main() {
  test('ECDSA P-256 DER and SPKI format verification', () {
    final domain = ECDomainParameters('secp256r1');
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)))));

    final keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(ECKeyGeneratorParameters(domain), secureRandom));

    final pair = keyGen.generateKeyPair();
    final privKey = pair.privateKey as ECPrivateKey;
    final pubKey = pair.publicKey as ECPublicKey;

    final pem = exportEcPublicKeyToPem(pubKey);
    expect(pem.startsWith('-----BEGIN PUBLIC KEY-----'), isTrue);
    expect(pem.endsWith('-----END PUBLIC KEY-----'), isTrue);

    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    signer.init(true, PrivateKeyParameter(privKey));

    final payload = utf8.encode('TEST_PATH|12345678|DEV1|BODY');
    final hash = Uint8List.fromList(dart_crypto.sha256.convert(payload).bytes);

    final sig = signer.generateSignature(hash) as ECSignature;
    final derSig = encodeEcdsaSignatureToDer(sig.r, sig.s);
    expect(derSig.first, equals(0x30));
    expect(derSig.length, greaterThan(60));
  });
}
