import 'package:linkify/linkify.dart';
import 'package:linkify/src/email_matcher.dart';

class EmailLinkifier extends Linkifier {
  const EmailLinkifier();

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    for (var element in elements) {
      if (element is TextElement) {
        final match = emailRegex.firstMatch(element.text);

        if (match == null) {
          list.add(element);
        } else {
          final text = element.text.replaceFirst(match.group(0)!, '');

          if (match.group(emailPrefixGroup)?.isNotEmpty == true) {
            list.add(TextElement(match.group(emailPrefixGroup)!));
          }

          if (match.group(emailElementGroup)?.isNotEmpty == true) {
            // Always humanize emails
            list.add(EmailElement(match.group(emailAddressGroup)!));
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

/// Represents an element containing an email address
class EmailElement extends LinkableElement {
  final String emailAddress;

  EmailElement(this.emailAddress) : super(emailAddress, 'mailto:$emailAddress');

  @override
  String toString() {
    return "EmailElement: '$emailAddress' ($text)";
  }

  @override
  bool operator ==(other) => equals(other);

  @override
  int get hashCode => Object.hash(text, originText, url, emailAddress);

  @override
  bool equals(other) =>
      other is EmailElement &&
      super.equals(other) &&
      other.emailAddress == emailAddress;
}
