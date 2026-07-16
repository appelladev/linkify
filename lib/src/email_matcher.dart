const emailPrefixGroup = 1;
const emailElementGroup = 2;
const emailAddressGroup = 4;

const emailLocalPartCharacterClass = r'A-Z0-9._%+\-';
const emailTokenCharacterClass = '$emailLocalPartCharacterClass@';

const domainNamePattern = r'(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+'
    r'(?:[A-Z]{2,63}|xn--[A-Z0-9-]{2,59})';

final emailRegex = RegExp(
  r'^(.*?)((mailto:)?('
  '[$emailLocalPartCharacterClass]+@'
  '$domainNamePattern'
  r'))(?![A-Z0-9_-]|\.[A-Z0-9])',
  caseSensitive: false,
  dotAll: true,
);
