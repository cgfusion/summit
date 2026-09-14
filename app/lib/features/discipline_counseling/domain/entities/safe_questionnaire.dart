/// SAFE (School Anti-Bullying Framework for Empowerment) questionnaire --
/// 12 Likert-scale items (1-5) across 3 sections. See
/// docs/SOAL_SELIDIK_PENILAIAN_PROGRAM_SCHOOL_ANTIBULLIYING_FRAMEWORK.docx.
library;

/// The 12 questions in fixed order, grouped by section. `items[i]` in a
/// submission/result always corresponds to `safeQuestionnaireItems[i]`.
const List<SafeQuestionnaireItem> safeQuestionnaireItems = [
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.pengetahuanKesedaran,
    text: 'Saya faham perbezaan antara buli fizikal, lisan, sosial, dan siber.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.pengetahuanKesedaran,
    text: 'Saya tahu kesan buruk perbuatan membuli terhadap mangsa.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.pengetahuanKesedaran,
    text: 'Saya sedar bahawa membuli adalah perbuatan yang melanggar disiplin sekolah.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.pengetahuanKesedaran,
    text: 'Saya tahu saluran yang betul untuk melaporkan kes buli di sekolah.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.amalanSekolahPenyayang,
    text: 'Saya mengamalkan budaya Senyum, Salam, Sapa, Sopan, Santun dan Sayang di sekolah.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.amalanSekolahPenyayang,
    text: 'Saya rasa guru-guru melayan murid dengan penuh empati dan kasih sayang.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.amalanSekolahPenyayang,
    text: 'Program dan aktiviti yang dilaksanakan sangat membantu saya menjadi rakan yang lebih baik.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.amalanSekolahPenyayang,
    text: 'Saya berasa selamat dan harmoni berada di kawasan sekolah.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.perananPrs,
    text: 'Saya mengenali rakan PRS di dalam kelas atau sekolah saya.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.perananPrs,
    text: 'Rakan PRS sentiasa bersedia mendengar luahan atau masalah saya.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.perananPrs,
    text: 'Saya yakin PRS boleh membantu menghalang rakan lain daripada membuli.',
  ),
  SafeQuestionnaireItem(
    section: SafeQuestionnaireSection.perananPrs,
    text: 'PRS di sekolah ini aktif menjalankan tugas sebagai agen antibuli.',
  ),
];

enum SafeQuestionnaireSection {
  pengetahuanKesedaran,
  amalanSekolahPenyayang,
  perananPrs;

  String get label {
    switch (this) {
      case SafeQuestionnaireSection.pengetahuanKesedaran:
        return 'Bahagian A: Pengetahuan & Kesedaran Antibuli';
      case SafeQuestionnaireSection.amalanSekolahPenyayang:
        return 'Bahagian B: Amalan Sekolah Penyayang (6S)';
      case SafeQuestionnaireSection.perananPrs:
        return 'Bahagian C: Peranan Pembimbing Rakan Sebaya (PRS)';
    }
  }
}

class SafeQuestionnaireItem {
  const SafeQuestionnaireItem({required this.section, required this.text});
  final SafeQuestionnaireSection section;
  final String text;
}

/// A single student's scored result, as returned by `fn_get_my_safe_questionnaire`.
class SafeQuestionnaireResult {
  const SafeQuestionnaireResult({
    required this.items,
    required this.totalScore,
    required this.maxScore,
    required this.percent,
    required this.level,
    required this.memahami,
    required this.sectionAScore,
    required this.sectionBScore,
    required this.sectionCScore,
    required this.submittedAt,
    required this.updatedAt,
  });

  final List<int> items;
  final int totalScore;
  final int maxScore;
  final double percent;
  final SafeQuestionnaireLevel level;
  final bool memahami;
  final int sectionAScore;
  final int sectionBScore;
  final int sectionCScore;
  final DateTime submittedAt;
  final DateTime updatedAt;

  factory SafeQuestionnaireResult.fromMap(Map<String, dynamic> map) {
    return SafeQuestionnaireResult(
      items: (map['items'] as List).map((e) => (e as num).toInt()).toList(),
      totalScore: (map['total_score'] as num).toInt(),
      maxScore: (map['max_score'] as num).toInt(),
      percent: (map['percent'] as num).toDouble(),
      level: SafeQuestionnaireLevel.fromDb(map['level'] as String),
      memahami: map['memahami'] as bool,
      sectionAScore: (map['section_a_score'] as num).toInt(),
      sectionBScore: (map['section_b_score'] as num).toInt(),
      sectionCScore: (map['section_c_score'] as num).toInt(),
      submittedAt: DateTime.parse(map['submitted_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}

enum SafeQuestionnaireLevel {
  rendah,
  sederhana,
  tinggi;

  static SafeQuestionnaireLevel fromDb(String value) {
    switch (value) {
      case 'rendah':
        return SafeQuestionnaireLevel.rendah;
      case 'sederhana':
        return SafeQuestionnaireLevel.sederhana;
      case 'tinggi':
        return SafeQuestionnaireLevel.tinggi;
      default:
        throw ArgumentError('Unknown SAFE questionnaire level: $value');
    }
  }

  String get label {
    switch (this) {
      case SafeQuestionnaireLevel.rendah:
        return 'Rendah';
      case SafeQuestionnaireLevel.sederhana:
        return 'Sederhana';
      case SafeQuestionnaireLevel.tinggi:
        return 'Tinggi';
    }
  }
}

/// Staff-facing aggregate, from `fn_safe_questionnaire_summary`.
class SafeQuestionnaireSummary {
  const SafeQuestionnaireSummary({
    required this.totalResponses,
    required this.avgPercent,
    required this.memahamiCount,
    required this.belumMemahamiCount,
    required this.levelRendah,
    required this.levelSederhana,
    required this.levelTinggi,
    required this.avgSectionA,
    required this.avgSectionB,
    required this.avgSectionC,
  });

  final int totalResponses;
  final double avgPercent;
  final int memahamiCount;
  final int belumMemahamiCount;
  final int levelRendah;
  final int levelSederhana;
  final int levelTinggi;
  final double avgSectionA;
  final double avgSectionB;
  final double avgSectionC;

  factory SafeQuestionnaireSummary.fromMap(Map<String, dynamic> map) {
    return SafeQuestionnaireSummary(
      totalResponses: (map['total_responses'] as num).toInt(),
      avgPercent: (map['avg_percent'] as num).toDouble(),
      memahamiCount: (map['memahami_count'] as num).toInt(),
      belumMemahamiCount: (map['belum_memahami_count'] as num).toInt(),
      levelRendah: (map['level_rendah'] as num).toInt(),
      levelSederhana: (map['level_sederhana'] as num).toInt(),
      levelTinggi: (map['level_tinggi'] as num).toInt(),
      avgSectionA: (map['avg_section_a'] as num).toDouble(),
      avgSectionB: (map['avg_section_b'] as num).toDouble(),
      avgSectionC: (map['avg_section_c'] as num).toDouble(),
    );
  }
}

/// One row in the staff drill-down list of individual responses.
class SafeQuestionnaireResponseRow {
  const SafeQuestionnaireResponseRow({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.totalScore,
    required this.percent,
    required this.level,
    required this.submittedAt,
  });

  final String studentId;
  final String studentName;
  final String? className;
  final int totalScore;
  final double percent;
  final SafeQuestionnaireLevel level;
  final DateTime submittedAt;

  factory SafeQuestionnaireResponseRow.fromMap(Map<String, dynamic> map) {
    final total = (map['item_01'] as num) +
        (map['item_02'] as num) +
        (map['item_03'] as num) +
        (map['item_04'] as num) +
        (map['item_05'] as num) +
        (map['item_06'] as num) +
        (map['item_07'] as num) +
        (map['item_08'] as num) +
        (map['item_09'] as num) +
        (map['item_10'] as num) +
        (map['item_11'] as num) +
        (map['item_12'] as num);
    final percent = (total.toDouble() / 60 * 100);
    final studentMap = map['students'] as Map<String, dynamic>?;
    final classMap = studentMap?['classes'] as Map<String, dynamic>?;
    return SafeQuestionnaireResponseRow(
      studentId: map['student_id'] as String,
      studentName: studentMap?['full_name'] as String? ?? 'Murid',
      className: classMap?['name'] as String?,
      totalScore: total.toInt(),
      percent: percent,
      level: percent >= 75
          ? SafeQuestionnaireLevel.tinggi
          : (percent >= 50 ? SafeQuestionnaireLevel.sederhana : SafeQuestionnaireLevel.rendah),
      submittedAt: DateTime.parse(map['submitted_at'] as String).toLocal(),
    );
  }
}
