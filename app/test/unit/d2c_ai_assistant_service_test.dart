import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/d2c_ai_assistant_service.dart';

void main() {
  group('D2CAiAssistantService Unit Tests', () {
    final service = D2CAiAssistantService();

    test('generates smart local response for merit questions', () async {
      final reply = await service.askAi('Bagaimana 4 mata merit harian dikira?', []);

      expect(reply, contains('4 Mata Merit'));
      expect(reply, contains('Step 01'));
      expect(reply, contains('Step 04'));
    });

    test('generates smart local response for intervention levels', () async {
      final reply = await service.askAi('Apakah 3 Aras Intervensi D2C?', []);

      expect(reply, contains('Aras 1 (Universal)'));
      expect(reply, contains('Aras 2 (Bersasar)'));
      expect(reply, contains('Aras 3 (Intensif)'));
    });

    test('generates smart local response for student voice rahsia', () async {
      final reply = await service.askAi('Bagaimana hantar Suara Murid secara rahsia?', []);

      expect(reply, contains('Suara Murid'));
      expect(reply, contains('Aduan Buli'));
      expect(reply, contains('Sulit / Rahsia'));
    });

    test('generates smart local response for parent portal IC lookup', () async {
      final reply = await service.askAi('Bagaimana ibu bapa menyemak kehadiran anak?', []);

      expect(reply, contains('Portal Ibu Bapa'));
      expect(reply, contains('No. IC / MyKad Penjaga'));
    });

    test('generates smart local response for tingkatan berapakah terlibat question', () async {
      final reply = await service.askAi('tingkatan berapakah terlibat', []);

      expect(reply, contains('Tingkatan 1 hingga Tingkatan 5'));
      expect(reply, contains('Sesi Pagi'));
      expect(reply, contains('Sesi Petang'));
    });
  });
}
