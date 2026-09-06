// SPEC.md §12's *Production and sharing*, as far as it is arithmetic.
//
// Three of its rules are pure decisions over inputs and are tested here without
// a canvas: which paper, what the file is called, and how many pages the
// records make. The drawing itself is the port's job.
//
// The filename rule is the one with teeth. "ASCII, vehicle name transliterated
// to [a-z0-9-] with a positional fallback." A Persian or Arabic vehicle name
// transliterates to NOTHING under that rule, and a filename of
// `odova-service-history--2026-09-02.pdf` — or worse, one carrying raw
// non-ASCII into a share sheet, an email attachment and someone's Windows
// download folder — is the bug the fallback exists to prevent.
@TestOn('vm')
library;

import 'package:odova/core/report/service_report_pdf.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

CivilDate day(String t) => CivilDate.tryParse(t)!;

void main() {
  group('paper size', () {
    test('is A4 everywhere', () {
      for (final region in ['DE', 'FR', 'IR', 'IQ', 'GB', 'JP', 'AU']) {
        expect(paperFor(region), PaperSize.a4, reason: region);
      }
    });

    test('is US Letter for US, CA, MX and PH — and only those', () {
      // §12 names four regions. Not "North America" and not "the Americas":
      // Brazil and Argentina are A4 countries, and a rule written by continent
      // would give them the wrong page.
      for (final region in ['US', 'CA', 'MX', 'PH']) {
        expect(paperFor(region), PaperSize.usLetter, reason: region);
      }
      expect(paperFor('BR'), PaperSize.a4);
      expect(paperFor('AR'), PaperSize.a4);
    });

    test('an unknown or absent region falls back to A4', () {
      // A4 is the majority of the world and the safer wrong answer: A4 content
      // fits on Letter with margin to spare, and Letter content on A4 clips at
      // the foot.
      expect(paperFor(null), PaperSize.a4);
      expect(paperFor(''), PaperSize.a4);
      expect(paperFor('ZZ'), PaperSize.a4);
    });

    test('the region is matched case-insensitively', () {
      expect(paperFor('us'), PaperSize.usLetter);
    });

    test('the override wins over the region', () {
      // §12: "overridable in the overflow menu." Someone printing a US
      // document on a European printer is a real case and the region cannot
      // know about it.
      expect(
        paperFor('US', override: PaperSize.a4),
        PaperSize.a4,
      );
      expect(
        paperFor('DE', override: PaperSize.usLetter),
        PaperSize.usLetter,
      );
    });
  });

  group('the filename', () {
    test('is the §12 shape, lowercase ASCII', () {
      expect(
        reportFileName(vehicleName: 'Golf', on: day('2026-09-02')),
        'odova-service-history-golf-2026-09-02.pdf',
      );
    });

    test('transliterates accents rather than dropping them', () {
      // A German or French name is the common case, and `Citroën` losing its
      // `e` entirely reads as a typo in a file someone is about to email.
      expect(
        reportFileName(vehicleName: 'Citroën Berlingo', on: day('2026-09-02')),
        'odova-service-history-citroen-berlingo-2026-09-02.pdf',
      );
    });

    test('collapses runs of punctuation into one hyphen, with no edges', () {
      expect(
        reportFileName(
          vehicleName: '  VW  Golf 1.6 TDI!! ',
          on: day('2026-09-02'),
        ),
        'odova-service-history-vw-golf-1-6-tdi-2026-09-02.pdf',
      );
    });

    test('falls back POSITIONALLY when the name transliterates to nothing', () {
      // §12's `odova-service-history-vehicle-2-2026-09-02.pdf`. A Persian name
      // has no ASCII to keep, and the alternative — an empty slot, or raw
      // non-ASCII in a share sheet — is a filename that breaks somewhere
      // between the OS and someone's Windows download folder.
      expect(
        reportFileName(
          vehicleName: 'پژو ۲۰۶',
          on: day('2026-09-02'),
          positionalIndex: 2,
        ),
        'odova-service-history-vehicle-2-2026-09-02.pdf',
      );
    });

    test('the fallback also covers a name that is only punctuation', () {
      expect(
        reportFileName(
          vehicleName: '???',
          on: day('2026-09-02'),
        ),
        'odova-service-history-vehicle-1-2026-09-02.pdf',
      );
    });

    test('the date is ISO Gregorian whatever the display calendar is', () {
      // §12: "Filenames stay ASCII Latin and Gregorian regardless of
      // language." A Jalali filename sorts wrongly in every file manager on
      // earth and cannot be read by the person the seller sends it to.
      expect(
        reportFileName(vehicleName: 'Golf', on: day('2026-09-02')),
        contains('2026-09-02'),
      );
    });

    test('a very long name is truncated, not left to break the filesystem', () {
      final name = reportFileName(
        vehicleName: 'A' * 300,
        on: day('2026-09-02'),
      );

      expect(name.length, lessThanOrEqualTo(120));
      expect(name, endsWith('-2026-09-02.pdf'));
    });
  });

  group('pagination', () {
    test('34 services produce 2 to 3 pages', () {
      // §12's own figure, and the reason the row budget is what it is.
      expect(pageCountFor(recordCount: 34), inInclusiveRange(2, 3));
    });

    test('about 200 services produce about 12 pages', () {
      expect(pageCountFor(recordCount: 200), inInclusiveRange(10, 14));
    });

    test('an empty document is still one page', () {
      // The header and the unremovable footer are a page on their own. Zero
      // pages is a file no viewer will open.
      expect(pageCountFor(recordCount: 0), 1);
    });

    test('one record is one page', () {
      // §12: "One documented cambelt change is worth printing." No apology,
      // and no second page for it either.
      expect(pageCountFor(recordCount: 1), 1);
    });

    test('page count grows monotonically with records', () {
      var previous = 0;
      for (var n = 0; n <= 400; n += 7) {
        final pages = pageCountFor(recordCount: n);
        expect(pages, greaterThanOrEqualTo(previous), reason: '$n records');
        previous = pages;
      }
    });

    test('the first page holds fewer rows than the ones after it', () {
      // The header block and the glance table live on page one. A paginator
      // that gave every page the same budget would overflow the first one,
      // which is the page a buyer actually reads.
      expect(kFirstPageRowBudget, lessThan(kPageRowBudget));
    });
  });

  test('the synchronous threshold is 200 records', () {
    // §12: "Over 200 records, generation shows a blocking 'Building your
    // report…' with a Cancel instead of a frozen button; under 200 it is
    // synchronous."
    expect(needsProgressUi(recordCount: 200), isFalse);
    expect(needsProgressUi(recordCount: 201), isTrue);
    expect(needsProgressUi(recordCount: 0), isFalse);
  });
}
