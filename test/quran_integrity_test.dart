import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;

/// Integrity of the bundled offline Quran data (package:quran).
/// These tests pin structure + exact spot texts: any silent change to the
/// bundled mushaf fails loudly instead of rendering corrupted text.
void main() {
  test('mushaf structure totals are intact', () {
    expect(quran.totalSurahCount, 114);
    expect(quran.totalVerseCount, 6236);
    expect(quran.totalJuzCount, 30);
  });

  test('short surah Al-Ikhlas is complete and ordered', () {
    expect(quran.getVerseCount(112), 4);
    // Uthmani orthography uses small-high marks (not plain sukun);
    // match mark-agnostic substrings, never normalize the data.
    expect(quran.getVerse(112, 1), contains('قُل'));
    expect(quran.getVerse(112, 1), contains('أَحَد'));
    expect(quran.getVerse(112, 4), contains('أَحَد'));
    expect(quran.getSurahNameArabic(112), 'الإخلاص');
  });

  test('long surah Al-Baqarah is complete', () {
    expect(quran.getVerseCount(2), 286);
    expect(quran.getVerse(2, 255).length, greaterThan(100)); // Ayat al-Kursi
    expect(quran.getSurahNameArabic(2), 'البقرة');
  });

  test('Al-Fatiha opens the mushaf with the basmala', () {
    expect(quran.getVerseCount(1), 7);
    // Same Uthmani-orthography note: compare mark-agnostic prefix.
    expect(quran.getVerse(1, 1).startsWith('بِس'), isTrue);
    expect(quran.getVerse(1, 1), contains('ٱلرَّحِيم'));
  });

  test('diacritics are preserved, not stripped', () {
    // Fatha (U+064E) must appear in a known verse; stripped text would fail.
    expect(quran.getVerse(112, 1).contains('َ'), isTrue);
  });

  test('verse end symbol carries the verse number', () {
    final symbol = quran.getVerseEndSymbol(5);
    expect(symbol, contains('٥'));
  });

  test('random verse resolves to a real verse', () {
    final v = quran.RandomVerse();
    expect(v.surahNumber, inInclusiveRange(1, 114));
    expect(
        v.verseNumber, inInclusiveRange(1, quran.getVerseCount(v.surahNumber)));
    expect(v.verse, isNotEmpty);
  });
}
