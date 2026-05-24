import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/dio_provider.dart';
import '../storage/secure_storage.dart';

part 'gemini_client.g.dart';

class GeminiException implements Exception {
  const GeminiException(this.message, {this.code});
  final String message;
  final int? code;
  @override
  String toString() => 'GeminiException($code): $message';
}

class NoApiKeyException extends GeminiException {
  const NoApiKeyException()
      : super('Gemini API key not configured', code: null);
}

// ─────────────────────────────────────────────────────────────
// Domain types
// ─────────────────────────────────────────────────────────────

class ChatTurn {
  const ChatTurn({required this.role, required this.text});
  final String role; // 'user' | 'model'
  final String text;

  Map<String, dynamic> toJson() => {
        'role': role,
        'parts': [
          {'text': text},
        ],
      };
}

class GeminiResponse {
  const GeminiResponse({required this.text, this.finishReason = 'STOP'});
  final String text;
  final String finishReason;
}

// ─────────────────────────────────────────────────────────────
// Client
// ─────────────────────────────────────────────────────────────

class GeminiClient {
  GeminiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _primaryModel  = 'gemini-2.0-flash';
  static const _fallbackModel = 'gemini-1.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Send a message with optional conversation history.
  /// Throws [NoApiKeyException] if key not set.
  Future<GeminiResponse> generateContent(
    String prompt, {
    List<ChatTurn> history = const [],
    String? systemInstruction,
  }) async {
    final key = await SecureStorageService.instance.geminiApiKey;
    if (key == null || key.isEmpty) throw const NoApiKeyException();

    return _callWithFallback(
      key: key,
      prompt: prompt,
      history: history,
      systemInstruction: systemInstruction,
    );
  }

  Future<GeminiResponse> _callWithFallback({
    required String key,
    required String prompt,
    required List<ChatTurn> history,
    String? systemInstruction,
  }) async {
    try {
      return await _call(
        model: _primaryModel,
        key: key,
        prompt: prompt,
        history: history,
        systemInstruction: systemInstruction,
      );
    } on GeminiException catch (e) {
      if (e.code == 404 || e.code == 400) {
        // model not available, try fallback
        debugPrint('Primary model unavailable, falling back to $_fallbackModel');
        return _call(
          model: _fallbackModel,
          key: key,
          prompt: prompt,
          history: history,
          systemInstruction: systemInstruction,
        );
      }
      rethrow;
    }
  }

  Future<GeminiResponse> _call({
    required String model,
    required String key,
    required String prompt,
    required List<ChatTurn> history,
    String? systemInstruction,
  }) async {
    final url = '$_baseUrl/$model:generateContent?key=$key';

    final contents = [
      ...history.map((t) => t.toJson()),
      {
        'role': 'user',
        'parts': [
          {'text': prompt},
        ],
      },
    ];

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };

    if (systemInstruction != null) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction},
        ],
      };
    }

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        url,
        data: body,
      );

      return _parse(res.data!);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = (e.response?.data as Map?)?['error']?['message'] as String? ??
          e.message ??
          'Unknown error';
      throw GeminiException(msg, code: status);
    }
  }

  GeminiResponse _parse(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiException('No candidates in response');
    }
    final c = candidates.first as Map<String, dynamic>;
    final parts = c['content']?['parts'] as List?;
    final text = (parts?.first as Map?)?['text'] as String? ?? '';
    final finish = c['finishReason'] as String? ?? 'STOP';
    return GeminiResponse(text: text.trim(), finishReason: finish);
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

@riverpod
GeminiClient geminiClient(GeminiClientRef ref) {
  return GeminiClient(dio: ref.watch(dioProvider));
}
