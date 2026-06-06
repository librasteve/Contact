use Actionable;

unit class Contact;

grammar Grammar {
    token TOP         { <name> \n <street> \n <locality> \n <region> ' ' <postal-code> \n 'Tel: ' <phone> \n 'Email: ' <email> \n? }
    token name        { <-[\n]>+ }
    token street      { <-[\n]>+ }
    token locality    { <-[\n]>+ }
    token region      { \S+ }
    token postal-code { <-[\n]>+ }
    token phone       { <-[\n]>+ }
    token email       { <-[\n]>+ }
}

class jCard does Actionable {
    has $.version     = "4.0";
    has $.fn;
    has $.street;
    has $.locality;
    has $.region;
    has $.postal-code;
    has $.tel;
    has $.email;

    method capture-map { {fn => 'name', tel => 'phone'} }

    method transform(Str $attr, $raw) {
        $attr eq 'tel' ?? "tel:{$raw.trim}" !! $raw.trim
    }

    method action-to-json {
        use JSON::Fast;
        to-json [
            "vcard", [
                ["version", {},                "text", $!version ],
                ["fn",      {},                "text", $!fn      ],
                ["adr",     {type => "home"},  "text", self.adr],
                ["tel",     {type => "voice"}, "uri",  $!tel     ],
                ["email",   {},                "text", $!email   ],
            ]
        ]
    }

    method adr { ["", "", $!street, $!locality, $!region, $!postal-code, ""] }

    method field(Str $f) { self."$f"() }
}

class vCard {
    has jCard $.card;

    method full-card {
        given $!card { qq:to/END/;
            BEGIN:VCARD
            VERSION:{.version}
            FN:{.fn}
            ADR;TYPE=home:{.adr.join(';')}
            TEL;TYPE=voice:{.tel.subst(/^ 'tel:' /, '')}
            EMAIL:{.email}
            END:VCARD
            END
        }
    }
}

class Actions {
    method TOP($/) { make jCard.action($/) }
}
