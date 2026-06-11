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

The input is a plain-text block. The full name (`fn`) is always the first line; all other fields are optional and may appear in any order.

    John Doe                     ← fn        (required, always first)
    PO Box 999                   ← po-box    (optional)
    Apt 4B                       ← ext-address (optional, see %syns<apt>)
    123 Main St.                 ← street
    Springfield                  ← locality
    IL 62704                     ← region + postal-code
    United States                ← country   (optional, see %syns<country>)
    Tel: 555-867-5309            ← tel       (optional, see %syns<tel>)
    Email: john.doe@example.com  ← email     (optional, see %syns<email>)

UK input (use `Grammar::UK`):

    Jane Smith
    Sleepy Cottage,              ← ext-address (optional, house name = no digits)
    123 High Street,             ← street
    Henley-on-Thames,            ← locality
    Oxon,                        ← region    (optional)
    RG9 2XX                      ← postal-code
    UK                           ← country   (optional)

Label synonyms (`Tel`/`Telephone`/`Phone`, `Email`/`E-mail`) and apartment prefixes (`Apt`/`Suite`/`Unit`/…) are case-insensitive. The colon separator after a label is optional. All synonym lists are extensible via `%syns`.

Contact::Grammar
----------------

Parses a US-format contact string. Throws `X::Contact::CannotParse` if the input cannot be parsed.

```raku
my $card = Contact::Grammar.parse($text, actions => Contact::Actions.new).made;
```

Contact::Grammar::UK
--------------------

Parses a UK-format contact string. Strips trailing commas from each line automatically (UK addresses often use comma-separated lines). Throws `X::Contact::CannotParse` if the input cannot be parsed.

```raku
my $card = Contact::Grammar::UK.parse($text, actions => Contact::Actions.new).made;
```

Contact::Address
----------------

Holds the seven jCard ADR components defined in **RFC 6350 §6.3.1**: `po-box`, `ext-address`, `street`, `locality`, `region`, `postal-code`, `country`. The `components` method returns them as an ordered list with absent fields as empty strings, ready for embedding in a jCard `adr` array.

Contact::Card
-------------

The primary parsed result, populated automatically from grammar captures via [Actionable](https://raku.land/zef:librasteve/Actionable). Attributes: `version` (default `"4.0"`), `fn`, `adr` (a `Contact::Address`), `tel`, `email`. Address sub-fields (`street`, `locality`, etc.) are delegated directly from `$.adr`.

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

Synonyms
--------

`%syns` is the single configuration point for all keyword lists. All matches are case-insensitive:

```raku
constant %syns = (
    tel     => <Tel Telephone Phone>,
    email   => <Email E-mail>,
    apt     => <Apt Apartment Suite Ste Unit Flat Fl>,
    country => ('United States of America', 'United States', 'USA', 'US', 'America'),
);
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

