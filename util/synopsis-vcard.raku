#!/usr/bin/env raku
use v6.d;

use Contact::vCard;

my $text = q:to/STOP/;
BEGIN:VCARD
VERSION:4.0
FN:John Doe
ADR;TYPE=home:;;123 Main St.;Springfield;IL;62704;

END:VCARD
STOP

my $card = Contact::vCard::Grammar.parse($text,
    actions => Contact::vCard::Actions.new).made;

say "{.fn}\n{.street}\n{.locality}, {.region} {.postal-code}"
    given $card;

