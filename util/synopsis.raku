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

my $jcard = Contact::Grammar.parse($text, actions => Contact::Actions.new).made;
my $vcard = Contact::vCard.new(card => $jcard);

say "=== full-card ===";
print $vcard.full-card;

say "\n=== field ===";
say $jcard.field('fn');
say $jcard.field('street');
say $jcard.field('locality') ~ ', ' ~ $jcard.field('region') ~ ' ' ~ $jcard.field('postal-code');

say "\n=== json ===";
say $jcard.action-to-json;
