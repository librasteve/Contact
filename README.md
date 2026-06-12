[![Actions Status](https://github.com/librasteve/Contact/actions/workflows/test.yml/badge.svg)](https://github.com/librasteve/Contact/actions)

NAME
====

Contact - Parse free-form contact text into vCard (RFC 6350) and jCard (RFC 7095)

SYNOPSIS
========

```raku
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
```

DESCRIPTION
===========

`Contact` parses free-form plain-text contact records and produces structured data conforming to **vCard 4.0 (RFC 6350)** and **jCard (RFC 7095)**.

Input format
------------

The input is a plain-text block. The full name is always the first line; all other fields are optional and may appear in any order.

US format:

    John Doe                     ← name     (required, always first)
    PO Box 999                   ← po-box   (optional)
    Apt 4B                       ← ext-address (optional — Apt/Suite/Unit/…)
    123 Main St.                 ← street
    Springfield                  ← locality
    IL 62704                     ← region + postal-code
    United States                ← country  (optional)
    Tel: 555-867-5309            ← tel      (optional — Tel/Telephone/Phone)
    Email: john.doe@example.com  ← email    (optional — Email/E-mail)

UK format (trailing commas stripped automatically):

    Jane Smith
    PO Box 42                    ← po-box   (optional)
    Sleepy Cottage               ← ext-address (optional — named house, no digits)
    123 High Street              ← street
    Henley-on-Thames             ← locality
    Oxon                         ← region   (optional)
    RG9 2XX                      ← postal-code
    UK                           ← country  (optional)

The single `Contact::Grammar` auto-detects locale from the address structure. Label and country synonyms are defined per locale in their respective modules.

Contact::Grammar
----------------

Boss grammar that assembles locale sub-grammars. Strips trailing commas and chomps the input before parsing. Throws `X::Contact::CannotParse` if the input cannot be parsed.

```raku
my $card = Contact::Grammar.parse($text, actions => Contact::Actions.new).made;
```

Locale address grammars are registered in `@locale-adrs`:

  * `Contact::Address::en_US::Grammar` — US street addresses

  * `Contact::Address::en_UK::Grammar` — UK street addresses

Contact::Address
----------------

Role defining the seven RFC 6350 §6.3.1 address components: `po-box`, `ext-address`, `street`, `locality`, `region`, `postal-code`, `country`. The `components` method returns them as an ordered list with absent fields as empty strings, ready for embedding in a jCard `adr` array.

Locale classes (`Contact::Address::en_US::Address`, `Contact::Address::en_UK::Address`) implement this role, mapping their local attribute names (e.g. `town`, `postcode`) to the RFC methods.

Contact::Name
-------------

Module providing `Contact::Name::Grammar` and `Contact::Name`. The grammar parses a free-form name line into prefix, given, additional, family, and suffix components. The class implements RFC 6350 `N` and `FN` fields via `components` and `fn`.

Contact::Card
-------------

The primary parsed result, populated automatically from grammar captures via [Actionable](https://raku.land/zef:librasteve/Actionable). Attributes: `version` (default `"4.0"`), `name`, `adr`, `tel`, `email`. Name sub-fields (`fn`, `given`, `family`, etc.) and address sub-fields (`street`, `locality`, etc.) are delegated directly from `$.name` and `$.adr`.

Contact::jCard
--------------

Wraps a `Card` and serialises to **jCard format (RFC 7095)**:

```raku
my $jcard = Contact::jCard.new(:$card);
say $jcard.to-json;
```

Contact::vCard
--------------

Wraps a `Card` and stringifies to **vCard 4.0 format (RFC 6350)**:

```raku
my $vcard = Contact::vCard.new(:$card);
print $vcard;   # coerces via method Str
```

Also parses a vCard string back to a `Card` (locale-agnostic, via `Contact::vCard::Grammar`):

```raku
my $card = Contact::vCard.parse($vcard-string);
```

This enables round-trip use and LLM DSL workflows: prompt the LLM to extract contact data as vCard 4.0, then parse the result directly. The `Contact::vCard::Grammar` and `Contact::vCard::Actions` from `Contact::vCard` can also be used directly in the slangify.org playground.

Synonyms
--------

Label synonyms live in `Contact.rakumod`; address and name synonyms live in their locale modules. All matches are case-insensitive.

`Contact` (tel/email labels):

```raku
constant %syns = (
    tel   => <Tel Telephone Phone>,
    email => <Email E-mail>,
);
```

`Contact::Address::en_US` (apt prefixes, country names):

```raku
my constant @apt-syns     = <Apt Apartment Suite Ste Unit Flat Fl>;
my constant @country-syns = ('United States of America', 'United States', 'USA', 'US', 'America');
```

`Contact::Address::en_UK` (country names):

```raku
my constant @country-syns = ('England', 'Scotland', 'Wales', 'Northern Ireland',
                              'United Kingdom', 'UK', 'Great Britain', 'GB', 'Britain', ...);
```

`Contact::Name` (honorifics, suffixes):

```raku
my constant @prefix-syns = <Mr Mrs Ms Miss Dr Prof Rev>;
my constant @suffix-syns = <Jr Sr II III IV Esq PhD MD JD>;
```

Exceptions
----------

`X::Contact::CannotParse` is thrown when the input cannot be parsed. The `$.text` attribute carries the offending input.

Standards
---------

  * [RFC 6350 — vCard Format Specification](https://www.rfc-editor.org/rfc/rfc6350)

  * [RFC 7095 — jCard: The JSON Format for vCard](https://www.rfc-editor.org/rfc/rfc7095)

AUTHOR
======

librasteve <librasteve@furnival.net>

COPYRIGHT AND LICENSE
=====================

Copyright 2026 librasteve

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

