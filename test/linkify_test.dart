import 'package:collection/collection.dart';
import 'package:linkify/linkify.dart';
import 'package:test/test.dart';

final listEqual = const ListEquality().equals;

void expectListEqual(List actual, List expected) {
  expect(
    listEqual(
      actual,
      expected,
    ),
    true,
    reason: "Expected $actual to be $expected",
  );
}

void main() {
  test('Parses only text', () {
    expectListEqual(
      linkify("Lorem ipsum dolor sit amet"),
      [TextElement("Lorem ipsum dolor sit amet")],
    );
  });

  test('Parses only text with multiple lines', () {
    expectListEqual(
      linkify("Lorem ipsum\ndolor sit amet"),
      [TextElement("Lorem ipsum\ndolor sit amet")],
    );
  });

  test('Parses only link', () {
    expectListEqual(
      linkify("https://example.com"),
      [UrlElement("https://example.com", "example.com")],
    );

    expectListEqual(
      linkify("https://www.example.com",
          options: LinkifyOptions(removeWww: true)),
      [UrlElement("https://www.example.com", "example.com")],
    );
  });

  test('Parses only link with no humanize', () {
    expectListEqual(
      linkify("https://example.com", options: LinkifyOptions(humanize: false)),
      [UrlElement("https://example.com")],
    );
  });

  test('Parses only link with removeWwww', () {
    expectListEqual(
      linkify(
        "https://www.example.com",
        options: LinkifyOptions(removeWww: true),
      ),
      [UrlElement("https://www.example.com", "example.com")],
    );
  });

  test('Parses only links with space', () {
    expectListEqual(
      linkify("https://example.com https://google.com"),
      [
        UrlElement("https://example.com", "example.com"),
        TextElement(" "),
        UrlElement("https://google.com", "google.com"),
      ],
    );
  });

  test('Parses links with text', () {
    expectListEqual(
      linkify(
        "Lorem ipsum dolor sit amet https://example.com https://google.com",
      ),
      [
        TextElement("Lorem ipsum dolor sit amet "),
        UrlElement("https://example.com", "example.com"),
        TextElement(" "),
        UrlElement("https://google.com", "google.com"),
      ],
    );
  });

  test('Parses links with text with no humanize', () {
    expectListEqual(
      linkify(
        "Lorem ipsum dolor sit amet https://example.com https://google.com",
        options: LinkifyOptions(humanize: false),
      ),
      [
        TextElement("Lorem ipsum dolor sit amet "),
        UrlElement("https://example.com"),
        TextElement(" "),
        UrlElement("https://google.com"),
      ],
    );
  });

  test('Parses links with text with newlines', () {
    expectListEqual(
      linkify(
        "https://google.com\nLorem ipsum\ndolor sit amet\nhttps://example.com",
      ),
      [
        UrlElement("https://google.com", "google.com"),
        TextElement("\nLorem ipsum\ndolor sit amet\n"),
        UrlElement("https://example.com", "example.com"),
      ],
    );
  });

  test('Parses email', () {
    expectListEqual(
      linkify("person@example.com"),
      [EmailElement("person@example.com")],
    );
  });

  test('Parses email and link', () {
    expectListEqual(
      linkify("person@example.com at https://google.com"),
      [
        EmailElement("person@example.com"),
        TextElement(" at "),
        UrlElement("https://google.com", "google.com")
      ],
    );
  });

  test('Parses emails with loose URL detection', () {
    const options = LinkifyOptions(
      looseUrl: true,
      defaultToHttps: true,
    );

    expectListEqual(
      linkify('person@example.com', options: options),
      [EmailElement('person@example.com')],
    );

    expectListEqual(
      linkify(
        'person@example.com',
        options: options,
        linkifiers: [UrlLinkifier()],
      ),
      [TextElement('person@example.com')],
    );

    expectListEqual(
      linkify('mailto:person@example.com', options: options),
      [EmailElement('person@example.com')],
    );

    expectListEqual(
      linkify('person+tag@example.travel', options: options),
      [EmailElement('person+tag@example.travel')],
    );

    expectListEqual(
      linkify('person@mail.example.com', options: options),
      [EmailElement('person@mail.example.com')],
    );

    expectListEqual(
      linkify('person@example.com.', options: options),
      [EmailElement('person@example.com'), TextElement('.')],
    );

    expectListEqual(
      linkify(
        'Email person@example.com and visit example.com.',
        options: options,
      ),
      [
        TextElement('Email '),
        EmailElement('person@example.com'),
        TextElement(' and visit '),
        UrlElement('https://example.com', 'example.com'),
        TextElement('.'),
      ],
    );

    expectListEqual(
      linkify('https://user@example.com', options: options),
      [UrlElement('https://user@example.com', 'user@example.com')],
    );

    expectListEqual(
      linkify('https://user:password@example.com', options: options),
      [
        UrlElement(
          'https://user:password@example.com',
          'user:password@example.com',
        ),
      ],
    );
  });

  test("Doesn't parses email and link with no linkifiers", () {
    expectListEqual(
      linkify("person@example.com at https://google.com", linkifiers: []),
      [
        TextElement("person@example.com at https://google.com"),
      ],
    );
  });

  test('Parses loose URL', () {
    expectListEqual(
      linkify("example.com/test", options: LinkifyOptions(looseUrl: true)),
      [UrlElement("http://example.com/test", "example.com/test")],
    );

    expectListEqual(
      linkify("www.example.com",
          options: LinkifyOptions(
            looseUrl: true,
            removeWww: true,
            defaultToHttps: true,
          )),
      [UrlElement("https://www.example.com", "example.com")],
    );

    expectListEqual(
      linkify("https://example.com", options: LinkifyOptions(looseUrl: true)),
      [UrlElement("https://example.com", "example.com")],
    );

    expectListEqual(
      linkify("https://example.com.", options: LinkifyOptions(looseUrl: true)),
      [UrlElement("https://example.com", "example.com"), TextElement(".")],
    );
  });

  test('Parses both loose and not URL on the same text', () {
    expectListEqual(
      linkify('example.com http://example.com',
          options: LinkifyOptions(looseUrl: true)),
      [
        UrlElement('http://example.com', 'example.com'),
        TextElement(' '),
        UrlElement('http://example.com', 'example.com')
      ],
    );

    expectListEqual(
      linkify(
          'This text mixes both loose urls like example.com and not loose urls like http://example.com and http://another.example.com',
          options: LinkifyOptions(looseUrl: true)),
      [
        TextElement('This text mixes both loose urls like '),
        UrlElement('http://example.com', 'example.com'),
        TextElement(' and not loose urls like '),
        UrlElement('http://example.com', 'example.com'),
        TextElement(' and '),
        UrlElement('http://another.example.com', 'another.example.com')
      ],
    );
  });

  test('Does not parse invalid URLs with consecutive periods', () {
    expectListEqual(
      linkify('awdaw....aw', options: LinkifyOptions(looseUrl: true)),
      [TextElement('awdaw....aw')],
    );

    expectListEqual(
      linkify('awdaw...wad...wadw', options: LinkifyOptions(looseUrl: true)),
      [TextElement('awdaw...wad...wadw')],
    );

    expectListEqual(
      linkify('test..example.com', options: LinkifyOptions(looseUrl: true)),
      [TextElement('test..'), UrlElement('http://example.com', 'example.com')],
    );

    expectListEqual(
      linkify(
        '....and i am a sentence',
        options: LinkifyOptions(looseUrl: true),
      ),
      [TextElement('....and i am a sentence')],
    );
  });

  test('Parses subdomains correctly', () {
    expectListEqual(
      linkify('https://subdomain.example.com'),
      [UrlElement('https://subdomain.example.com', 'subdomain.example.com')],
    );

    expectListEqual(
      linkify('https://api.subdomain.example.com'),
      [
        UrlElement(
          'https://api.subdomain.example.com',
          'api.subdomain.example.com',
        )
      ],
    );

    expectListEqual(
      linkify('subdomain.example.com', options: LinkifyOptions(looseUrl: true)),
      [UrlElement('http://subdomain.example.com', 'subdomain.example.com')],
    );

    expectListEqual(
      linkify(
        'Check out api.subdomain.example.com for more info',
        options: LinkifyOptions(looseUrl: true),
      ),
      [
        TextElement('Check out '),
        UrlElement(
          'http://api.subdomain.example.com',
          'api.subdomain.example.com',
        ),
        TextElement(' for more info'),
      ],
    );
  });

  test('Parses localhost URLs', () {
    expectListEqual(
      linkify('http://localhost'),
      [UrlElement('http://localhost', 'localhost')],
    );

    expectListEqual(
      linkify('http://localhost:3000'),
      [UrlElement('http://localhost:3000', 'localhost:3000')],
    );

    expectListEqual(
      linkify('http://localhost:8080/api/test'),
      [UrlElement('http://localhost:8080/api/test', 'localhost:8080/api/test')],
    );

    expectListEqual(
      linkify('localhost', options: LinkifyOptions(looseUrl: true)),
      [TextElement('localhost')],
    );

    expectListEqual(
      linkify(
        'Check out localhost for testing',
        options: LinkifyOptions(looseUrl: true),
      ),
      [TextElement('Check out localhost for testing')],
    );

    expectListEqual(
      linkify('localhost:3000', options: LinkifyOptions(looseUrl: true)),
      [UrlElement('http://localhost:3000', 'localhost:3000')],
    );
  });

  test('Parses URLs with ports', () {
    expectListEqual(
      linkify('https://example.com:8080'),
      [UrlElement('https://example.com:8080', 'example.com:8080')],
    );

    expectListEqual(
      linkify('https://api.example.com:3000/path'),
      [
        UrlElement(
          'https://api.example.com:3000/path',
          'api.example.com:3000/path',
        )
      ],
    );

    expectListEqual(
      linkify('example.com:8080', options: LinkifyOptions(looseUrl: true)),
      [UrlElement('http://example.com:8080', 'example.com:8080')],
    );
  });

  test('Parses IP address URLs', () {
    expectListEqual(
      linkify('http://192.168.1.1'),
      [UrlElement('http://192.168.1.1', '192.168.1.1')],
    );

    expectListEqual(
      linkify('http://192.168.1.1:8080'),
      [UrlElement('http://192.168.1.1:8080', '192.168.1.1:8080')],
    );

    expectListEqual(
      linkify('https://10.0.0.1:3000/api'),
      [UrlElement('https://10.0.0.1:3000/api', '10.0.0.1:3000/api')],
    );

    expectListEqual(
      linkify('192.168.1.1:8080', options: LinkifyOptions(looseUrl: true)),
      [UrlElement('http://192.168.1.1:8080', '192.168.1.1:8080')],
    );

    expectListEqual(
      linkify(
        'Check out 192.168.1.1:8080 for the dashboard',
        options: LinkifyOptions(looseUrl: true),
      ),
      [
        TextElement('Check out '),
        UrlElement('http://192.168.1.1:8080', '192.168.1.1:8080'),
        TextElement(' for the dashboard'),
      ],
    );
  });

  test('Parses punycode domains', () {
    // xn--n3h.com is ☃.com (snowman emoji domain)
    expectListEqual(
      linkify('https://xn--n3h.com'),
      [UrlElement('https://xn--n3h.com', 'xn--n3h.com')],
    );

    // xn--bcher-kva.com is bücher.com (books in German)
    expectListEqual(
      linkify('https://xn--bcher-kva.com'),
      [UrlElement('https://xn--bcher-kva.com', 'xn--bcher-kva.com')],
    );

    expectListEqual(
      linkify('xn--n3h.com', options: LinkifyOptions(looseUrl: true)),
      [UrlElement('http://xn--n3h.com', 'xn--n3h.com')],
    );

    expectListEqual(
      linkify('Visit xn--bcher-kva.com for more',
          options: LinkifyOptions(looseUrl: true)),
      [
        TextElement('Visit '),
        UrlElement('http://xn--bcher-kva.com', 'xn--bcher-kva.com'),
        TextElement(' for more'),
      ],
    );
  });

  test('Parses TLDs with more than 4 letters', () {
    expectListEqual(
      linkify('https://example.design'),
      [UrlElement('https://example.design', 'example.design')],
    );

    expectListEqual(
      linkify('https://example.travel'),
      [UrlElement('https://example.travel', 'example.travel')],
    );

    expectListEqual(
      linkify('https://example.cloud'),
      [UrlElement('https://example.cloud', 'example.cloud')],
    );

    expectListEqual(
      linkify('example.design', options: LinkifyOptions(looseUrl: true)),
      [UrlElement('http://example.design', 'example.design')],
    );

    expectListEqual(
      linkify('example.travel', options: LinkifyOptions(looseUrl: true)),
      [UrlElement('http://example.travel', 'example.travel')],
    );

    expectListEqual(
      linkify('example.cloud', options: LinkifyOptions(looseUrl: true)),
      [UrlElement('http://example.cloud', 'example.cloud')],
    );

    expectListEqual(
      linkify(
        'Check out example.design for more info',
        options: LinkifyOptions(looseUrl: true),
      ),
      [
        TextElement('Check out '),
        UrlElement('http://example.design', 'example.design'),
        TextElement(' for more info'),
      ],
    );
  });

  test('Parses ending period and trailing punctuation', () {
    expectListEqual(
      linkify("https://example.com/test."),
      [
        UrlElement("https://example.com/test", "example.com/test"),
        TextElement(".")
      ],
    );

    expectListEqual(
      linkify('Check out https://example.com!'),
      [
        TextElement('Check out '),
        UrlElement('https://example.com', 'example.com'),
        TextElement('!'),
      ],
    );

    expectListEqual(
      linkify('Visit https://example.com, then come back.'),
      [
        TextElement('Visit '),
        UrlElement('https://example.com', 'example.com'),
        TextElement(', then come back.'),
      ],
    );

    expectListEqual(
      linkify('See https://example.com?'),
      [
        TextElement('See '),
        UrlElement('https://example.com', 'example.com'),
        TextElement('?'),
      ],
    );

    expectListEqual(
      linkify('Go to example.com.', options: LinkifyOptions(looseUrl: true)),
      [
        TextElement('Go to '),
        UrlElement('http://example.com', 'example.com'),
        TextElement('.'),
      ],
    );
  });

  test('Parses CR correctly.', () {
    expectListEqual(
      linkify('lorem\r\nipsum https://example.com'),
      [
        TextElement('lorem\r\nipsum '),
        UrlElement('https://example.com', 'example.com'),
      ],
    );
  });

  test('Parses user tag', () {
    expectListEqual(
      linkify(
        "@example",
        linkifiers: [
          UrlLinkifier(),
          EmailLinkifier(),
          UserTagLinkifier(),
        ],
      ),
      [UserTagElement("@example")],
    );
  });

  test('Parses email, link, and user tag', () {
    expectListEqual(
      linkify(
        "person@example.com at https://google.com @example",
        linkifiers: [
          UrlLinkifier(),
          EmailLinkifier(),
          UserTagLinkifier(),
        ],
      ),
      [
        EmailElement("person@example.com"),
        TextElement(" at "),
        UrlElement("https://google.com", "google.com"),
        TextElement(" "),
        UserTagElement("@example")
      ],
    );
  });

  test('Parses invalid phone number', () {
    expectListEqual(
      linkify(
        "This is an invalid numbers 17.00",
        linkifiers: [
          UrlLinkifier(),
          EmailLinkifier(),
          PhoneNumberLinkifier(),
        ],
      ),
      [
        TextElement("This is an invalid numbers 17.00"),
      ],
    );
  });

  test('Parses german phone number', () {
    expectListEqual(
      linkify(
        "This is a german example number +49 30 901820",
        linkifiers: [
          UrlLinkifier(),
          EmailLinkifier(),
          PhoneNumberLinkifier(),
        ],
      ),
      [
        TextElement("This is a german example number "),
        PhoneNumberElement("+49 30 901820"),
      ],
    );
  });

  test('Parses seattle phone number', () {
    expectListEqual(
      linkify(
        "This is a seattle example number +1 206 555 0100",
        linkifiers: [
          UrlLinkifier(),
          EmailLinkifier(),
          PhoneNumberLinkifier(),
        ],
      ),
      [
        TextElement("This is a seattle example number "),
        PhoneNumberElement("+1 206 555 0100"),
      ],
    );
  });

  test('Parses uk phone number', () {
    expectListEqual(
      linkify(
        "This is an example number from uk: +44 113 496 0000",
        linkifiers: [
          UrlLinkifier(),
          EmailLinkifier(),
          PhoneNumberLinkifier(),
        ],
      ),
      [
        TextElement("This is an example number from uk: "),
        PhoneNumberElement("+44 113 496 0000"),
      ],
    );
  });

  test('Excludes wrapping parentheses from URLs', () {
    expectListEqual(
      linkify('Some text before (https://github.com/Cretezy/flutter_linkify).'),
      [
        TextElement('Some text before ('),
        UrlElement(
          'https://github.com/Cretezy/flutter_linkify',
          'github.com/Cretezy/flutter_linkify',
        ),
        TextElement(').'),
      ],
    );

    expectListEqual(
      linkify('Check this out (https://example.com)'),
      [
        TextElement('Check this out ('),
        UrlElement('https://example.com', 'example.com'),
        TextElement(')'),
      ],
    );

    expectListEqual(
      linkify('Link: [https://example.com]'),
      [
        TextElement('Link: ['),
        UrlElement('https://example.com', 'example.com'),
        TextElement(']'),
      ],
    );

    expectListEqual(
      linkify('Code: {https://example.com}'),
      [
        TextElement('Code: {'),
        UrlElement('https://example.com', 'example.com'),
        TextElement('}'),
      ],
    );
  });

  test('Excludes wrapping brackets from loose URLs', () {
    expectListEqual(
      linkify(
        'Some text before (example.com/path).',
        options: LinkifyOptions(looseUrl: true),
      ),
      [
        TextElement('Some text before ('),
        UrlElement('http://example.com/path', 'example.com/path'),
        TextElement(').'),
      ],
    );

    expectListEqual(
      linkify(
        'Check [example.com]',
        options: LinkifyOptions(looseUrl: true),
      ),
      [
        TextElement('Check ['),
        UrlElement('http://example.com', 'example.com'),
        TextElement(']'),
      ],
    );
  });

  test('Does not exclude non-wrapping closing brackets', () {
    expectListEqual(
      linkify('https://example.com/path)'),
      [
        UrlElement('https://example.com/path', 'example.com/path'),
        TextElement(')'),
      ],
    );

    expectListEqual(
      linkify('No opening bracket https://example.com]'),
      [
        TextElement('No opening bracket '),
        UrlElement('https://example.com', 'example.com'),
        TextElement(']'),
      ],
    );
  });
}
