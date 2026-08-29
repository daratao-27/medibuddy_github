import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_insight.dart';
import '../models/medication.dart';

// sends the med list to Groq and turns the reply into
// MedInteraction/DrugInfo objects for the AI Insights screen
class MedAiService {
  // supplied at build/run time via --dart-define-from-file=env.json (see env.example.json)
  static const groqKey = String.fromEnvironment('GROQ_API_KEY');
  static const groqModel = 'llama-3.1-8b-instant';
  static const groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // main function the provider calls, returns interactions + drug info
  Future<Map<String, dynamic>> analyseMeds(List<Medication> meds) async {
    if (meds.isEmpty) {
      throw ArgumentError('meds must not be empty.');
    }

    // turn the meds into simple lines the AI can read
    // e.g. "Lisinopril | 10mg | Once daily | After breakfast"
    String medList = '';
    for (final m in meds) {
      final dose = m.dosage % 1 == 0 ? m.dosage.toInt() : m.dosage;
      medList += '${m.name} | $dose${m.unit} | ${m.frequency} | ${m.instructions}\n';
    }

    // instructions for the AI
    final prompt = '''
You are a helpful medication assistant inside a medication tracking app.

MEDICATION LIST:
$medList

RULES:
1. List potential interactions between pairs of medications above. If there
   are fewer than 2 medications, or you find no notable interactions, return
   an empty interactions list.
2. Write a short, plain-English description of what each medication does.
3. Keep every "body" and "description" to 2 to 3 short sentences.
4. This is general information only, not medical advice. Do not diagnose or
   tell the user to change their dosage.
5. Do not use any markdown formatting.

Respond with ONLY this JSON, no extra text:
{
  "interactions": [
    { "title": "Medication A and Medication B", "body": "explanation here" }
  ],
  "drugInfo": [
    { "name": "Medication name", "description": "what it does" }
  ]
}
''';

    // ask groq and get the raw reply back
    final aiReply = await askGroq(prompt);

    // parse that reply into real objects
    return turnReplyIntoInsights(aiReply);
  }

  // sends the prompt to groq and returns the raw text reply
  Future<String> askGroq(String prompt) async {
    final response = await http.post(
      Uri.parse(groqUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqKey',
      },
      body: jsonEncode({
        'model': groqModel,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body);
    return json['choices'][0]['message']['content'];
  }

  // reads the AI's json reply and turns it into interaction/drug info lists
  Map<String, dynamic> turnReplyIntoInsights(String aiReply) {
    // sometimes the AI wraps its json in ```json fences, strip those
    String cleanText = aiReply.trim();
    cleanText = cleanText.replaceAll('```json', '').replaceAll('```', '').trim();

    final data = jsonDecode(cleanText);

    final interactions = (data['interactions'] as List? ?? [])
        .map((e) => MedInteraction.fromJson(e))
        .toList();

    final drugInfo = (data['drugInfo'] as List? ?? [])
        .map((e) => DrugInfo.fromJson(e))
        .toList();

    return {
      'interactions': interactions,
      'drugInfo': drugInfo,
    };
  }
}
