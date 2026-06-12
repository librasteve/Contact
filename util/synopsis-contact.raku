#!/usr/bin/env raku
use v6.d;
use Contact;

my $text = q:to/END/;
John Doe
123 Main St.
Springfield
IL 62704
Tel: 555-867-5309
Email: john.doe@example.com
END

my $card  = Contact::Grammar.parse($text,
                actions => Contact::Actions.new).made;
my $jcard = Contact::jCard.new(:$card);
my $vcard = Contact::vCard.new(:$card);

say "=== Card ===";
given $card {
    say .fn;
    say .street;
    say "{ .locality }, { .region } { .postal-code }";
}

say "\n=== vCard ===";
print $vcard;

say "\n=== jCard ===";
say $jcard.to-json;
