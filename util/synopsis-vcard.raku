#!/usr/bin/env raku
use v6.d;

use Contact;
use Contact::vCard;
use Contact::jCard;

my $vcard-text = q:to/END/;
BEGIN:VCARD
VERSION:4.0
FN:John Doe
N:Doe;John;;;
ADR;TYPE=home:;;123 Main St.;Springfield;IL;62704;
TEL;TYPE=voice:555-867-5309
EMAIL:john.doe@example.com
END:VCARD
END

my $card = Contact::vCard::Grammar.parse($vcard-text, actions => Contact::vCard::Actions.new).made;

say "=== Card ===";
given $card {
    say .fn;
    say .street;
    say "{ .locality }, { .region } { .postal-code }";
}

say "\n=== vCard ===";
print Contact::vCard.new(:$card);

say "\n=== jCard ===";
print Contact::jCard.new(:$card).to-json;
