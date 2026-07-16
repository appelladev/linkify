import 'package:linkify/linkify.dart';
import 'package:linkify/src/email_matcher.dart';

final _urlRegex = RegExp(
  r'^(.*?)((?:https?:\/\/|www\.)[^\s<>\x22\x27]*[^\s<>\x22\x27\.,;:!?]\.?)(?=$|[\s<>\x22\x27\)\]\}\.,;:!?])',
  caseSensitive: false,
  dotAll: true,
);

const _ordinaryLooseUrlPrefixPattern =
    '(?:.*?)(?:^|[^$emailTokenCharacterClass])';
const _consecutivePeriodsLooseUrlPrefixPattern =
    '(?:.*?[^$emailTokenCharacterClass])?'
    '[$emailLocalPartCharacterClass]*\\.\\.';

const _urlSuffixPattern = r'(?:[\/?#][^\s<>\x22\x27]*'
    r'[^\s<>\x22\x27\.,;:!?]|\/)?';

const _protocolWithOptionalUserInfoPattern =
    r"(?:https?:\/\/)(?:[A-Z0-9._~!$&'()*+,;=:%\-]+@)?";
const _localhostWithOptionalPortPattern = r'localhost(?::\d{1,5})?';
const _localhostWithPortPattern = r'localhost(?::\d{1,5})';
const _networkHostPattern = r'(?:\[(?:[0-9a-f:.]+)\]|(?:\d{1,3}\.){3}\d{1,3}|'
    '$domainNamePattern'
    r')(?::\d{1,5})?';

const _looseUrlCandidatePattern = '(?:'
    '$_protocolWithOptionalUserInfoPattern'
    '(?:$_localhostWithOptionalPortPattern|$_networkHostPattern)'
    '|'
    '$_localhostWithPortPattern'
    '|'
    '$_networkHostPattern'
    ')'
    '$_urlSuffixPattern'
    r'\.?';

final _ordinaryLooseUrlRegex = _createLooseUrlRegex(
  _ordinaryLooseUrlPrefixPattern,
);
final _consecutivePeriodsLooseUrlRegex = _createLooseUrlRegex(
  _consecutivePeriodsLooseUrlPrefixPattern,
);

final _protocolIdentifierRegex = RegExp(
  r'^(https?:\/\/)',
  caseSensitive: false,
);

const _openingBracketByClosingBracket = {
  ')': '(',
  ']': '[',
  '}': '{',
};

class UrlLinkifier extends Linkifier {
  const UrlLinkifier();

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    for (var element in elements) {
      if (element is TextElement) {
        var match = options.looseUrl
            ? _firstLooseUrlMatch(element.text)
            : _urlRegex.firstMatch(element.text);

        if (match == null) {
          list.add(element);
        } else {
          final remainingTextAfterMatch =
              element.text.replaceFirst(match.group(0)!, '');
          var text = remainingTextAfterMatch;

          if (match.group(1)?.isNotEmpty == true) {
            list.add(TextElement(match.group(1)!));
          }

          if (match.group(2)?.isNotEmpty == true) {
            var originalUrl = match.group(2)!;
            var originText = originalUrl;

            while (true) {
              final wrapperStart = _trailingWrapperStart(originalUrl);
              if (wrapperStart != null) {
                text = originalUrl.substring(wrapperStart) + text;
                originText = originText.substring(0, wrapperStart);
                originalUrl = originalUrl.substring(0, wrapperStart);
                continue;
              }

              if (options.excludeLastPeriod && originalUrl.endsWith('.')) {
                text = '.$text';
                originText = originText.substring(0, originText.length - 1);
                originalUrl = originalUrl.substring(0, originalUrl.length - 1);
                continue;
              }

              break;
            }

            if (!_hasUrlAuthority(originalUrl)) {
              if (match.group(1)?.isNotEmpty == true) {
                list.removeLast();
              }
              final parsedRemaining = remainingTextAfterMatch.isEmpty
                  ? <LinkifyElement>[]
                  : parse([TextElement(remainingTextAfterMatch)], options);
              if (parsedRemaining.isNotEmpty &&
                  parsedRemaining.first is TextElement) {
                list.add(
                  TextElement(
                    match.group(0)! + parsedRemaining.first.text,
                  ),
                );
                list.addAll(parsedRemaining.skip(1));
              } else {
                list.add(TextElement(match.group(0)!));
                list.addAll(parsedRemaining);
              }
              continue;
            }

            var url = originalUrl;

            if (!originalUrl.startsWith(_protocolIdentifierRegex)) {
              originalUrl = (options.defaultToHttps ? "https://" : "http://") +
                  originalUrl;
            }

            if ((options.humanize) || (options.removeWww)) {
              if (options.humanize) {
                url = url.replaceFirst(RegExp(r'https?://'), '');
              }
              if (options.removeWww) {
                url = url.replaceFirst(RegExp(r'www\.'), '');
              }

              list.add(UrlElement(
                originalUrl,
                url,
                originText,
              ));
            } else {
              list.add(UrlElement(originalUrl, null, originText));
            }
          }

          if (text.isNotEmpty) {
            list.addAll(parse([TextElement(text)], options));
          }
        }
      } else {
        list.add(element);
      }
    }

    return list;
  }
}

bool _endsWithUnmatchedClosingBracket(String value) {
  final closingBracket = value[value.length - 1];
  final openingBracket = _openingBracketByClosingBracket[closingBracket];
  if (openingBracket == null) {
    return false;
  }

  return _countCharacter(value, closingBracket) >
      _countCharacter(value, openingBracket);
}

int? _trailingWrapperStart(String value) {
  var bracketIndex = value.length - 1;
  while (bracketIndex >= 0 && value[bracketIndex] == '.') {
    bracketIndex--;
  }

  if (bracketIndex < 0) {
    return null;
  }

  final valueThroughBracket = value.substring(0, bracketIndex + 1);
  return _endsWithUnmatchedClosingBracket(valueThroughBracket)
      ? bracketIndex
      : null;
}

int _countCharacter(String value, String character) {
  var count = 0;
  for (var index = 0; index < value.length; index++) {
    if (value[index] == character) {
      count++;
    }
  }
  return count;
}

bool _hasUrlAuthority(String value) {
  final valueWithoutLastPeriod =
      value.endsWith('.') ? value.substring(0, value.length - 1) : value;

  if (valueWithoutLastPeriod.toLowerCase() == 'www') {
    return false;
  }

  final normalizedValue =
      valueWithoutLastPeriod.startsWith(_protocolIdentifierRegex)
          ? valueWithoutLastPeriod
          : 'http://$valueWithoutLastPeriod';
  return Uri.tryParse(normalizedValue)?.host.isNotEmpty == true;
}

RegExp _createLooseUrlRegex(String prefixPattern) => RegExp(
      '^($prefixPattern)($_looseUrlCandidatePattern)'
      r'(?=$|[\s<>\x22\x27\)\]\}\.,;:!?])',
      caseSensitive: false,
      dotAll: true,
    );

RegExpMatch? _firstLooseUrlMatch(String text) {
  final ordinaryMatch = _ordinaryLooseUrlRegex.firstMatch(text);
  final consecutivePeriodsMatch =
      _consecutivePeriodsLooseUrlRegex.firstMatch(text);

  if (ordinaryMatch == null) {
    return consecutivePeriodsMatch;
  }
  if (consecutivePeriodsMatch == null) {
    return ordinaryMatch;
  }

  return ordinaryMatch.group(1)!.length <=
          consecutivePeriodsMatch.group(1)!.length
      ? ordinaryMatch
      : consecutivePeriodsMatch;
}

/// Represents an element containing a link
class UrlElement extends LinkableElement {
  UrlElement(String url, [String? text, String? originText])
      : super(text, url, originText);

  @override
  String toString() {
    return "LinkElement: '$url' ($text)";
  }

  @override
  bool operator ==(other) => equals(other);

  @override
  int get hashCode => Object.hash(text, originText, url);

  @override
  bool equals(other) => other is UrlElement && super.equals(other);
}
