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

my $card = Contact::Grammar.parse($text, actions => Contact::Actions.new).made;

say "=== full-card ===";
print $card.full-card;

say "\n=== field ===";
say $card.field('name');
say $card.field('address');

say "\n=== json ===";
say $card.json;
