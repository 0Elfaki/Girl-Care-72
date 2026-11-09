class QuizQuestion {
  QuizQuestion({required this.question, required this.options, required this.answer});

  final String question;
  final List<String> options;
  final int answer;

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        question: j['q'] as String? ?? '',
        options: (j['options'] as List? ?? []).map((e) => e.toString()).toList(),
        answer: (j['answer'] as num?)?.toInt() ?? 0,
      );
}

class Lesson {
  Lesson({
    required this.n,
    required this.track,
    required this.title,
    required this.keyMessages,
    required this.story,
    required this.quiz,
    required this.sms,
  });

  final int n;
  final String track; // "10-14" or "15-24"
  final String title;
  final List<String> keyMessages;
  final String story;
  final List<QuizQuestion> quiz;
  final String sms;

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        n: (j['n'] as num).toInt(),
        track: j['track'] as String,
        title: j['title'] as String,
        keyMessages: (j['key'] as List).map((e) => e.toString()).toList(),
        story: j['story'] as String? ?? '',
        quiz: (j['quiz'] as List? ?? []).map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        sms: j['sms'] as String? ?? '',
      );
}

class Answer {
  Answer({required this.text, this.lesson, this.help = false, this.source = 'bank'});

  final String text;
  final int? lesson;
  final bool help;
  final String source; // ai, bank, none

  factory Answer.fromJson(Map<String, dynamic> j) => Answer(
        text: j['text'] as String? ?? '',
        lesson: (j['lesson'] as num?)?.toInt(),
        help: j['help'] == true,
        source: j['source'] as String? ?? 'ai',
      );
}

class ChatLine {
  ChatLine({required this.fromGirl, required this.text, this.answer});
  final bool fromGirl;
  final String text;
  final Answer? answer;
}
