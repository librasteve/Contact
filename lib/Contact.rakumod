=begin pod

=head1 NAME

Contact - Parse free-form contact text into vCard (RFC 6350) and jCard (RFC 7095)

=head1 SYNOPSIS

=begin code :lang<raku>
use Contact;

my $text = q:to/END/;
John Doe
123 Main St.
Springfield
IL 62704
Tel: 555-867-5309
Email: john.doe@example.com
END

my $card  = Contact::Grammar.parse($text, actions => Contact::Actions.new).made;
my $jcard = Contact::jCard.new(:$card);
my $vcard = Contact::vCard.new(:$card);

say $card.fn;                                              # John Doe
say $card.street;                                          # 123 Main St.
say "{.locality}, {.region} {.postal-code}" given $card;  # Springfield, IL 62704

print $vcard;        # vCard (RFC 6350) text
say $jcard.to-json;  # jCard (RFC 7095) JSON
=end code

=head1 DESCRIPTION

C<Contact> parses free-form plain-text contact records and produces structured
data conforming to B<vCard 4.0 (RFC 6350)> and B<jCard (RFC 7095)>.

=head2 Input format

The input is a plain-text block. The full name is always the first line;
all other fields are optional and may appear in any order.

US format:

=begin code
John Doe                     ← name     (required, always first)
PO Box 999                   ← po-box   (optional)
Apt 4B                       ← ext-address (optional — Apt/Suite/Unit/…)
123 Main St.                 ← street
Springfield                  ← locality
IL 62704                     ← region + postal-code
United States                ← country  (optional)
Tel: 555-867-5309            ← tel      (optional — Tel/Telephone/Phone)
Email: john.doe@example.com  ← email    (optional — Email/E-mail)
=end code

UK format (trailing commas stripped automatically):

=begin code
Jane Smith
PO Box 42                    ← po-box   (optional)
Sleepy Cottage               ← ext-address (optional — named house, no digits)
123 High Street              ← street
Henley-on-Thames             ← locality
Oxon                         ← region   (optional)
RG9 2XX                      ← postal-code
UK                           ← country  (optional)
=end code

The single C<Contact::Grammar> auto-detects locale from the address structure.
Label and country synonyms are defined per locale in their respective modules.

=head2 Contact::Grammar

Boss grammar that assembles locale sub-grammars. Strips trailing commas and
chomps the input before parsing. Throws C<X::Contact::CannotParse> if the
input cannot be parsed.

=begin code :lang<raku>
my $card = Contact::Grammar.parse($text, actions => Contact::Actions.new).made;
=end code

Locale address grammars are registered in C<@locale-adrs>:

=item C<Contact::Address::en_US::Grammar> — US street addresses
=item C<Contact::Address::en_UK::Grammar> — UK street addresses

=head2 Contact::Address

Role defining the seven RFC 6350 §6.3.1 address components:
C<po-box>, C<ext-address>, C<street>, C<locality>, C<region>, C<postal-code>,
C<country>. The C<components> method returns them as an ordered list with absent
fields as empty strings, ready for embedding in a jCard C<adr> array.

Locale classes (C<Contact::Address::en_US::Address>,
C<Contact::Address::en_UK::Address>) implement this role, mapping their
local attribute names (e.g. C<town>, C<postcode>) to the RFC methods.

=head2 Contact::Name

Module providing C<Contact::Name::Grammar> and C<Contact::Name::Name>.
The grammar parses a free-form name line into prefix, given, additional,
family, and suffix components. The class implements RFC 6350 C<N> and C<FN>
fields via C<components> and C<fn>.

=head2 Contact::Card

The primary parsed result, populated automatically from grammar captures via
L<Actionable|https://raku.land/zef:librasteve/Actionable>. Attributes:
C<version> (default C<"4.0">), C<name>, C<adr>, C<tel>, C<email>.
Name sub-fields (C<fn>, C<given>, C<family>, etc.) and address sub-fields
(C<street>, C<locality>, etc.) are delegated directly from C<$.name> and C<$.adr>.

=head2 Contact::jCard

Wraps a C<Card> and serialises to B<jCard format (RFC 7095)>:

=begin code :lang<raku>
my $jcard = Contact::jCard.new(:$card);
say $jcard.to-json;
=end code

=head2 Contact::vCard

Wraps a C<Card> and stringifies to B<vCard 4.0 format (RFC 6350)>:

=begin code :lang<raku>
my $vcard = Contact::vCard.new(:$card);
print $vcard;   # coerces via method Str
=end code

=head2 Synonyms

Label synonyms live in C<Contact.rakumod>; address and name synonyms live in
their locale modules. All matches are case-insensitive.

C<Contact> (tel/email labels):

=begin code :lang<raku>
constant %syns = (
    tel   => <Tel Telephone Phone>,
    email => <Email E-mail>,
);
=end code

C<Contact::Address::en_US> (apt prefixes, country names):

=begin code :lang<raku>
my constant @apt-syns     = <Apt Apartment Suite Ste Unit Flat Fl>;
my constant @country-syns = ('United States of America', 'United States', 'USA', 'US', 'America');
=end code

C<Contact::Address::en_UK> (country names):

=begin code :lang<raku>
my constant @country-syns = ('England', 'Scotland', 'Wales', 'Northern Ireland',
                              'United Kingdom', 'UK', 'Great Britain', 'GB', 'Britain', ...);
=end code

C<Contact::Name> (honorifics, suffixes):

=begin code :lang<raku>
my constant @prefix-syns = <Mr Mrs Ms Miss Dr Prof Rev>;
my constant @suffix-syns = <Jr Sr II III IV Esq PhD MD JD>;
=end code

=head2 Exceptions

C<X::Contact::CannotParse> is thrown when the input cannot be parsed.
The C<$.text> attribute carries the offending input.

=head2 Standards

=item L<RFC 6350 — vCard Format Specification|https://www.rfc-editor.org/rfc/rfc6350>
=item L<RFC 7095 — jCard: The JSON Format for vCard|https://www.rfc-editor.org/rfc/rfc7095>

=head1 AUTHOR

librasteve <librasteve@furnival.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 librasteve

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

use Actionable;
use Contact::Address;
use Contact::Name;
use Contact::Address::en_US;
use Contact::Address::en_UK;

unit class Contact;

class X::Contact::CannotParse is Exception {
    has Str $.text;
    method message { "Cannot parse contact:\n$.text" }
}

constant %syns = (
    tel   => <Tel Telephone Phone>,
    email => <Email E-mail>,
);

sub prep(Str $text is copy) {
    $text ~~ s:g/','$$//;
    $text .= chomp;
    $text
}

my @locale-adrs =
    (Contact::Address::en_US::Grammar, Contact::Address::en_US::Address),
    (Contact::Address::en_UK::Grammar, Contact::Address::en_UK::Address);

grammar Grammar is Contact::Name::Grammar {
    token TOP {
        <name>
        [ \v
        [
        | <adr>
        | [:i @(%syns<tel>)]   ':'? \h* <tel>
        | [:i @(%syns<email>)] ':'? \h* <email>
        ]
        ]* \v?
    }

    regex adr {
        [ | <Contact::Address::en_US::Grammar::adr>
          | <Contact::Address::en_UK::Grammar::adr>
        ] <?before \v | $>
    }

    token tel   { <-[\v]>+ }
    token email { <-[\v]>+ }

    method parse($text is copy, |c) {
        $text = prep($text);
        CATCH { default { X::Contact::CannotParse.new(:$text).throw } }
        my $m = callwith($text, |c);
        $m or X::Contact::CannotParse.new(:$text).throw
    }
}

class Card does Actionable {
    has Str  $.version = "4.0";
    has Contact::Name::Name $.name handles ('fn', |Contact::Name::Name.attrs);
    has      $.adr  handles <po-box ext-address street locality region postal-code country>;
    has Str  $.tel;
    has Str  $.email;
}

class Actions {
    method TOP($/)  { make Card.action($/) }
    method name($/) { make Contact::Name::Name.action($/) }
    method adr($/) {
        for @locale-adrs -> ($grammar, $class) {
            my $key = $grammar.^name ~ '::adr';
            make $class.action($/{$key}) with $/{$key};
        }
    }
}

class jCard {
    has Card $.card;

    method to-json {
        use JSON::Fast;
        given $!card {
            to-json [
                "vcard", [
                    ["version", {},                "text", .version        ],
                    ["fn",      {},                "text", .fn             ],
                    ["n",       {},                "text", .name.components.list ],
                    ["adr",     {type => "home"},  "text", .adr.components ],
                    ["tel",     {type => "voice"}, "uri",  .tel            ],
                    ["email",   {},                "text", .email          ],
                ]
            ]
        }
    }
}

class vCard {
    has Card $.card;

    method Str {
        given $!card { qq:to/END/;
            BEGIN:VCARD
            VERSION:{.version}
            FN:{.fn}
            N:{.name.components.join(';')}
            ADR;TYPE=home:{.adr.components.join(';')}
            TEL;TYPE=voice:{.tel // ''}
            EMAIL:{.email // ''}
            END:VCARD
            END
        }
    }
}