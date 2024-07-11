import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/random/fortuna_random.dart';

import 'currentUserData.dart';

class Encryption {
  final storage = const FlutterSecureStorage();

  // region Generate Keys
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair(
      SecureRandom secureRandom) {
    final rsaKeyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 12),
          secureRandom,
        ),
      );

    final keyPair = rsaKeyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      keyPair.publicKey as RSAPublicKey,
      keyPair.privateKey as RSAPrivateKey,
    );
  }

  SecureRandom getSecureRandom() {
    final secureRandom = FortunaRandom();

    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(255));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom;
  }
  // endregion

  // region En- and Decoding Keys
  String encodePublicKey(RSAPublicKey publicKey) {
    var algorithmSeq = ASN1Sequence();
    var algorithmAsn1Obj = ASN1ObjectIdentifier.fromName('rsaEncryption');
    var paramsAsn1Obj = ASN1Null();
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    var publicKeySeq = ASN1Sequence();
    var mod = ASN1Integer(publicKey.modulus);
    var exp = ASN1Integer(publicKey.exponent);

    publicKeySeq.add(mod);
    publicKeySeq.add(exp);

    var publicKeyEncoded = publicKeySeq.encode();

    var publicKeySeqBitString = ASN1BitString(stringValues: publicKeyEncoded);

    var topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);
    topLevelSeq.encode();

    var dataBase64 = base64.encode(topLevelSeq.encodedBytes as List<int>);
    return "-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----";
  }

  String encodePrivateKey(RSAPrivateKey privateKey) {
    var privateKeySeq = ASN1Sequence();
    privateKeySeq.add(
      ASN1Integer(BigInt.zero),
    );
    privateKeySeq.add(
      ASN1Integer(privateKey.modulus!),
    );
    privateKeySeq.add(
      ASN1Integer(privateKey.publicExponent!),
    );
    privateKeySeq.add(
      ASN1Integer(privateKey.privateExponent!),
    );
    privateKeySeq.add(
      ASN1Integer(privateKey.p!),
    );
    privateKeySeq.add(
      ASN1Integer(privateKey.q!),
    );

    privateKeySeq.encode();

    var dataBase64 = base64.encode(privateKeySeq.encodedBytes as List<int>);
    return "-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----";
  }

  RSAPrivateKey decodePrivateKey(String pemString) {
    String base64Content = pemString
        .split(RegExp(
            r'-----BEGIN RSA PRIVATE KEY-----|-----END RSA PRIVATE KEY-----'))
        .where((element) => element.isNotEmpty)
        .join('')
        .replaceAll('\n', '')
        .replaceAll('\r', '');

    Uint8List derBytes = base64.decode(base64Content);
    var asn1Parser = ASN1Parser(derBytes);
    ASN1Sequence topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    var modulus = (topLevelSeq.elements?[1] as ASN1Integer).integer;
    var privateExponent = (topLevelSeq.elements?[3] as ASN1Integer).integer;
    var p = (topLevelSeq.elements?[4] as ASN1Integer).integer;
    var q = (topLevelSeq.elements?[5] as ASN1Integer).integer;

    return RSAPrivateKey(modulus!, privateExponent!, p, q);
  }

  RSAPublicKey decodePublicKey(String pemString) {
    var lines = pemString.split('\n');
    var base64String = lines.skip(1).take(lines.length - 2).join('');

    var publicKeyDER = base64.decode(base64String);

    var asn1Parser = ASN1Parser(publicKeyDER);

    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    var publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString;

    List<int>? decodedBitString = publicKeyBitString.stringValues;

    var publicKeyParser = ASN1Parser(
      Uint8List.fromList(decodedBitString!),
    );

    var publicKeySeq = publicKeyParser.nextObject() as ASN1Sequence;

    var modulus = publicKeySeq.elements![0] as ASN1Integer;
    var exponent = publicKeySeq.elements![1] as ASN1Integer;

    return RSAPublicKey(modulus.integer!, exponent.integer!);
  }
  // endregion

  Future<void> storePrivateKey({
    required String private,
  }) async {
    await storage.write(
      key: 'private_key_${FirebaseAuth.instance.currentUser?.uid}',
      value: private,
    );
  }

  Future<String?> getPrivateKey() async {
    return await storage.read(
        key: 'private_key_${FirebaseAuth.instance.currentUser?.uid}');
  }

  String encrypt(String plaintext, RSAPublicKey publicKey) {
    final cipher = RSAEngine()
      ..init(
        true, // true for encryption
        PublicKeyParameter<RSAPublicKey>(publicKey),
      );

    final utf8Bytes = utf8.encode(plaintext);
    final cipherText = cipher.process(Uint8List.fromList(utf8Bytes));
    return base64.encode(cipherText);
  }

  String decrypt(String ciphertext, RSAPrivateKey privateKey) {
    final cipher = RSAEngine()
      ..init(
        false, // false for decryption
        PrivateKeyParameter<RSAPrivateKey>(privateKey),
      );

    try {
      final decodedBytes = base64.decode(ciphertext);

      final decryptedBytes = cipher.process(Uint8List.fromList(decodedBytes));

      return utf8.decode(decryptedBytes);
    } catch (e) {
      print("Decryption error: $e");
      return "Decryption Error";
    }
  }

  String lockPrivateKey(String pemPrivateKey, String passphrase) {
    var secureRandom = FortunaRandom();
    var random = Random.secure();
    List<int> seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    var iv = secureRandom.nextBytes(16);

    var pkcs = KeyDerivator('SHA-256/HMAC/PBKDF2');
    var salt = iv;
    var params = Pbkdf2Parameters(salt, 1000, 32);
    pkcs.init(params);
    var key = pkcs.process(Uint8List.fromList(utf8.encode(passphrase)));

    var keyParam = KeyParameter(key);
    var paramsWithIV = ParametersWithIV<KeyParameter>(keyParam, iv);
    var paddedParams = PaddedBlockCipherParameters(paramsWithIV, null);
    var cipher =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESFastEngine()))
          ..init(true, paddedParams);

    var privateKeyBytes = utf8.encode(pemPrivateKey);
    var encryptedBytes = cipher.process(Uint8List.fromList(privateKeyBytes));

    return '${base64.encode(iv)}:${base64.encode(encryptedBytes)}';
  }

  String unlockPrivateKey(String encryptedTextWithIv, String passphrase) {
    var parts = encryptedTextWithIv.split(':');
    if (parts.length != 2) {
      throw const FormatException(
          "Eingabedaten sind nicht korrekt formatiert.");
    }
    var iv = base64.decode(parts[0]);
    var encryptedBytes = base64.decode(parts[1]);

    var pkcs = KeyDerivator('SHA-256/HMAC/PBKDF2');
    var salt = iv;
    var params = Pbkdf2Parameters(salt, 1000, 32);
    pkcs.init(params);
    var key = pkcs.process(Uint8List.fromList(utf8.encode(passphrase)));

    var keyParam = KeyParameter(key);
    var paramsWithIV = ParametersWithIV<KeyParameter>(keyParam, iv);
    var paddedParams = PaddedBlockCipherParameters(paramsWithIV, null);
    var cipher =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESFastEngine()))
          ..init(false, paddedParams);

    var decryptedBytes = cipher.process(encryptedBytes);

    return utf8.decode(decryptedBytes);
  }

  Future<void> generateEncryptionKeys(String password) async {
    var secureRandom = getSecureRandom();
    var keyPair = generateRSAKeyPair(secureRandom);

    var publicKey = keyPair.publicKey;
    var privateKey = keyPair.privateKey;

    var encodedPublic = encodePublicKey(publicKey);
    var encodedPrivate = encodePrivateKey(privateKey);

    var lockedPrivateKey = lockPrivateKey(encodedPrivate, password);

    await storePrivateKey(private: encodedPrivate);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update(
      {
        'publicEncryptionKey': encodedPublic,
        'privateEncryptionKey': lockedPrivateKey,
      },
    );

    CurrentUser.privateKey = privateKey;
  }

  Future<void> loadPrivateKey(String password) async {
    var private = await getPrivateKey();

    if (private == null) {
      print('private key is not on device');

      if (password == '') return;

      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      var data = snapshot.data();

      if (data != null &&
          data.containsKey('privateEncryptionKey') &&
          data['privateEncryptionKey'] != null) {
        var private = data['privateEncryptionKey'];

        var unlockedPrivate = unlockPrivateKey(private, password);

        await storePrivateKey(private: unlockedPrivate);

        CurrentUser.privateKey = decodePrivateKey(unlockedPrivate);

        print('got private key!');
      } else {
        await generateEncryptionKeys(password);
      }
    } else {
      CurrentUser.privateKey = decodePrivateKey(private);

      print('got private Key!');
    }
  }
}
