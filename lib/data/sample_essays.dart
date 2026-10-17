import '../models/app_language.dart';
import '../models/essay.dart';

/// Bundled starter passages: two per language so the vertical slice can be
/// exercised in English, Chinese and Bahasa Malaysia from day one.
///
/// These are deliberately short and concrete. Replace or extend freely — the
/// app treats essays as data, so nothing else needs to change.
const List<Essay> kSampleEssays = [
  // ---------------------------------------------------------------- English
  Essay(
    id: 'en-morning-garden',
    title: 'My Morning Garden',
    language: ReadingLanguage.english,
    gradeLevel: 2,
    text: 'Every morning I walk into our small garden. '
        'The grass is still wet with dew. '
        'My mother waters the red flowers near the gate. '
        'I say good morning to the old mango tree. '
        'A little bird sings on the fence. '
        'I like my garden because it is quiet and green.',
  ),
  Essay(
    id: 'en-brave-kite',
    title: 'The Brave Little Kite',
    language: ReadingLanguage.english,
    gradeLevel: 3,
    text: 'Ali took his new kite to the open field. '
        'The wind was strong and the sky was wide. '
        'His kite climbed higher and higher. '
        'Then the string slipped from his hand. '
        'The kite flew over the tall trees and was gone. '
        'Ali was sad, but he did not cry. '
        'Next week he will make a bigger one.',
  ),

  // ---------------------------------------------------------------- Chinese
  Essay(
    id: 'zh-xiao-yu-di',
    title: '小雨滴的旅行',
    language: ReadingLanguage.chinese,
    gradeLevel: 2,
    text: '小雨滴住在云里。 '
        '有一天，风把它吹到了山上。 '
        '它顺着小溪流进河里，又流进了大海。 '
        '小鱼问它，你要去哪里。 '
        '小雨滴说，我要回家。 '
        '太阳出来了，它又飞回了天上。',
  ),
  Essay(
    id: 'zh-wo-ai-xue-xiao',
    title: '我爱我的学校',
    language: ReadingLanguage.chinese,
    gradeLevel: 1,
    text: '我的学校很大，也很漂亮。 '
        '每天早上，我和同学们一起读书。 '
        '老师对我们很好。 '
        '下课的时候，我们在操场上跑步和玩游戏。 '
        '我很喜欢我的学校。',
  ),

  // ---------------------------------------------------------------- Bahasa Malaysia
  Essay(
    id: 'ms-pokok-kegemaran',
    title: 'Pokok Kegemaran Saya',
    language: ReadingLanguage.malay,
    gradeLevel: 2,
    text: 'Di belakang rumah saya ada sebatang pokok mangga. '
        'Pokok itu tinggi dan rendang. '
        'Setiap pagi burung berkicau di dahannya. '
        'Ayah dan saya menyiram pokok itu bersama-sama. '
        'Pada musim buah, kami memetik mangga yang masak. '
        'Saya sayang akan pokok itu.',
  ),
  Essay(
    id: 'ms-hari-pertama',
    title: 'Hari Pertama ke Sekolah',
    language: ReadingLanguage.malay,
    gradeLevel: 1,
    text: 'Hari ini hari pertama saya ke sekolah. '
        'Saya memakai baju baru dan kasut baru. '
        'Ibu menghantar saya ke pintu pagar. '
        'Cikgu membawa saya ke dalam kelas. '
        'Saya berkenalan dengan kawan baru. '
        'Saya berasa gembira.',
  ),
];

/// Returns the passages available for [language], in the order defined above.
List<Essay> essaysFor(ReadingLanguage language) {
  return kSampleEssays.where((e) => e.language == language).toList(growable: false);
}

/// Looks up a single passage by id, or `null` when it no longer exists.
Essay? essayById(String id) {
  for (final essay in kSampleEssays) {
    if (essay.id == id) return essay;
  }
  return null;
}

/// One short sentence per language, read aloud on the hearing test screen.
///
/// Kept short and phonetically plain so that a poor result points at the
/// device rather than at the vocabulary.
const Map<ReadingLanguage, String> kHearingTestSentences = {
  ReadingLanguage.english: 'The quick brown cat sat on the mat.',
  ReadingLanguage.chinese: '今天天气很好，我去公园散步。',
  ReadingLanguage.malay: 'Hari ini cuaca baik, saya pergi ke taman.',
};
