import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/draw_model.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  Future<void> shareDrawResult(Draw draw) async {
    final numbersText = draw.winningNumbers.join(', ');
    final dateFormatted = '${draw.date.day}/${draw.date.month}/${draw.date.year}';
    
    final message = '''
🎲 Résultat du tirage - Lucky Numbers

🏆 Numéros gagnants: $numbersText

📅 Date: $dateFormatted
🎰 Mode: ${draw.mode == 'random' ? 'Aléatoire' : 'Manuel'}
📊 Nombre de gagnants: ${draw.winnersCount}
🔢 Plage: ${draw.minRange} - ${draw.maxRange}

---
Généré avec Lucky Numbers 🎰
''';  

    await SharePlus.instance.share(ShareParams(text: message));
  }

  Future<void> copyDrawResult(Draw draw) async {
    await Clipboard.setData(ClipboardData(text: draw.winningNumbers.join(', ')));
  }
}
