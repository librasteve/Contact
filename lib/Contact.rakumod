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

say $card.n;                                              # John Doe
say $card.street;                                          # 123 Main St.
say "{.locality}, {.region} {.postal-code}" given $card;  # Springfield, IL 62704

print $vcard;        # vCard (RFC 6350) text
say $jcard.to-json;  # jCard (RFC 7095) JSON
=end code

=head1 DESCRIPTION

C<Contact> parses free-form plain-text contact records and produces structured
data conforming to B<vCard 4.0 (RFC 6350)> and B<jCard (RFC 7095)>.

=head2 Input format

The input is a plain-text block. The full name (C<n>) is always the first line;
all other fields are optional and may appear in any order:

=begin code
John Doe                     ← n        (required, always first)
PO Box 999                   ← po-box    (optional)
Apt 4B                       ← ext-address (optional, see %syns<apt>)
123 Main St.                 ← street
Springfield                  ← locality
IL 62704                     ← region + postal-code
United States                ← country   (optional, see %syns<country>)
Tel: 555-867-5309            ← tel       (optional, see %syns<tel>)
Email: john.doe@example.com  ← email     (optional, see %syns<email>)
=end code

Label synonyms (C<Tel>/C<Telephone>/C<Phone>, C<Email>/C<E-mail>) and apartment
prefixes (C<Apt>/C<Suite>/C<Unit>/…) are case-insensitive. The colon separator
after a label is optional. All synonym lists are extensible via C<%syns>.

=head2 Contact::Grammar

Parses a contact string. Inherits address tokens from C<Contact::Adr-Grammar>.
Throws C<X::Contact::CannotParse> if the input cannot be parsed.

=begin code :lang<raku>
my $card = Contact::Grammar.parse($text, actions => Contact::Actions.new).made;
=end code

=head2 Contact::Address

Holds the seven jCard ADR components defined in B<RFC 6350 §6.3.1>:
C<po-box>, C<ext-address>, C<street>, C<locality>, C<region>, C<postal-code>,
C<country>. The C<components> method returns them as an ordered list with absent
fields as empty strings, ready for embedding in a jCard C<adr> array.

=head2 Contact::Card

The primary parsed result, populated automatically from grammar captures via
L<Actionable|https://raku.land/zef:librasteve/Actionable>. Attributes:
C<version> (default C<"4.0">), C<n>, C<adr> (a C<Contact::Address>), C<tel>,
C<email>. Address sub-fields (C<street>, C<locality>, etc.) are delegated
directly from C<$.adr>.

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

C<%syns> is the single configuration point for all keyword lists.
All matches are case-insensitive:

=begin code :lang<raku>
constant %syns = (
    tel     => <Tel Telephone Phone>,
    email   => <Email E-mail>,
    apt     => <Apt Apartment Suite Ste Unit Flat Fl>,
    country => ('United States of America', 'United States', 'USA', 'US', 'America'),
);
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

=begin pod

=head1 TODOS

=item bring in UK
=item externalize USA specific
=item parse vCard (as LLM DSL?) ie returns a Contact::Card
=item auto-detect country (pre-parse?)
=item make intenational loadable
=item breakdown tel

=head1 SNAGS

=item weird parse logic / inheritance
=item UK attrs not gonna fit
=item exception for each Grammar block - locale and thingy

=end pod

use Actionable;

unit class Contact;

class X::Contact::CannotParse is Exception {
    has Str $.text;
    method message { "Cannot parse contact:\n$.text" }
}

constant %syns = (
    tel     => <Tel Telephone Phone>,
    email   => <Email E-mail>,
    apt     => <Apt Apartment Suite Ste Unit Flat Fl>,
    country => ('United States of America', 'United States', 'USA', 'US', 'America'),
    prefix  => <Mr Mrs Ms Miss Dr Prof Rev>,
    suffix  => <Jr Sr II III IV Esq PhD MD JD>,
);

sub prep(Str $text is copy) {
    $text ~~ s:g/','$$//;
    $text .= chomp;
    $text
}

grammar Name-Grammar {
    regex name {
        [<prefix> \h+]?
        [
        | <given=word> [\h+ <additional=word>]* \h+ <family=word>
        | <family=word>
        ]
        [\h+ <suffix>]?
    }
    token prefix { :i @(%syns<prefix>) '.'? }
    token suffix { :i @(%syns<suffix>) '.'? }

    token word   { <!before :i @(%syns<suffix>) '.'? [\s|$]> \S+ }
}

class Name is Actionable {
    has Str $.prefix;
    has Str $.given;
    has Array[Str] $.additional;
    has Str $.family;
    has Str $.suffix;

    method attrs(:$target = 'n') {
        given $target {
            when 'fn' { <prefix given additional family suffix> }
            when 'n'  { <family given additional prefix suffix> }
        }
    }

    method components(*%h) { $.attrs(|%h).map: { self."$_"() // '' } }

    method fn { $.components(:target<fn>).grep(*.so).join(' ') }

    method additional { ($!additional // []).join(' ') }
}

grammar US-Adr-Grammar {
    token adr {
        [ <po-box>      \n ]?
        [ <ext-address> \n ]?
        <street> \n
        <locality> \n
        <region> ' ' <postal-code>
        [ \n <country> ]?
    }

    token po-box      { 'PO Box ' <-[\n]>+ }
    token ext-address { [ :i @(%syns<apt>) ] ' ' <-[\n]>+ }
    token street      { <-[\n]>+ }
    token locality    { <-[\n]>+ }
    token region      { \S+ }
    token postal-code { <-[\n]>+ }
    token country     { :i @(%syns<country>) }
}

grammar UK-Adr-Grammar {
    regex adr {
        [ <ext-address=house>   \n ]?
          <street>              \n
          <locality=town>
        [ \h+  <postal-code=postcode>
        | \n [ <region=county>  [ ','? \h+ <postal-code=postcode>
                                | \n   <postal-code=postcode> ]
             | <postal-code=postcode>
             ]
        ]
        \n?
        [ <country> \n? ]?
    }

    token house    { <nodt-words> }
    token town     { <nodt-words> }
    token county   { <nodt-words> }
    token street   { <-[\n]>+ }
    token postcode { \S+ \h \d \w \w }
    token country  { <-[\n]>+ }

    token nodt-word  { <[\w\-']>+ <?{ $/ !~~ /\d/ }> }
    token nodt-words { <nodt-word>+ % \h }
}

class Address does Actionable {
    has Str $.po-box;
    has Str $.ext-address;
    has Str $.street;
    has Str $.locality;
    has Str $.region;
    has Str $.postal-code;
    has Str $.country;

    method attrs { <po-box ext-address street locality region postal-code country> }
    method components { $.attrs.map: { self."$_"() // '' } }
}

grammar Grammar-Common is Name-Grammar {
    token TOP {
        <name>
        [ \n
        [
        | <adr>
        | [:i @(%syns<tel>)]   ':'? \h* <tel>
        | [:i @(%syns<email>)] ':'? \h* <email>
        ]
        ]* \n?
    }

    token tel   { <-[\n]>+ }
    token email { <-[\n]>+ }
}

grammar Grammar is Grammar-Common is US-Adr-Grammar {
    method parse($text, |c) {
        CATCH { default { X::Contact::CannotParse.new(:$text).throw } }
        my $m = callsame;
        $m or X::Contact::CannotParse.new(:$text).throw
    }
}

grammar Grammar::UK-Base is Grammar-Common is UK-Adr-Grammar {
    method parse($text, |c) {
        CATCH { default { X::Contact::CannotParse.new(:$text).throw } }
        my $m = callsame;
        $m or X::Contact::CannotParse.new(:$text).throw
    }
}

grammar Grammar::UK is Grammar::UK-Base {
    method parse($text is copy, |c) {
        $text = prep($text);
        nextwith($text, |c)
    }
}

class Card does Actionable {
    has Str           $.version = "4.0";
    has Name          $.name handles ('fn', |Name.attrs);
    has Address       $.adr  handles Address.attrs;
    has Str           $.tel;
    has Str           $.email;
}

class Actions {
    method TOP($/)  { make Card.action($/) }
    method name($/) { make Name.action($/) }
    method adr($/)  { make Address.action($/) }
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