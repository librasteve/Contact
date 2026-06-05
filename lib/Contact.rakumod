use Actionable;

unit class Contact;

grammar Grammar {
    token TOP     { <name> \n <address> 'Tel: ' <phone> \n 'Email: ' <email> \n? }
    token name    { <-[\n]>+ }
    token address { [<!before 'Tel:'> <-[\n]>+ \n]+ }
    token phone   { <-[\n]>+ }
    token email   { <-[\n]>+ }
}

class jCard does Actionable {
    has $.version = "4.0";
    has $.fn;
    has $.adr;
    has $.tel;
    has $.email;

    method capture-map { {fn => 'name', adr => 'address', tel => 'phone'} }

    method transform(Str $attr, $raw) {
        given $attr {
            when 'adr' {
                my ($street, $locality, $region-zip) = $raw.trim.lines;
                my ($region, $postal-code) = ($region-zip // '').split(' ', 2);
                ["", "", $street//'', $locality//'', $region//'', $postal-code//'', ""]
            }
            when 'tel' { "tel:{$raw.trim}" }
            default    { $raw.trim }
        }
    }

    method action-to-json {
        use JSON::Fast;
        to-json [
            "vcard", [
                ["version", {},                "text", $!version],
                ["fn",      {},                "text", $!fn     ],
                ["adr",     {type => "home"},  "text", $!adr    ],
                ["tel",     {type => "voice"}, "uri",  $!tel    ],
                ["email",   {},                "text", $!email  ],
            ]
        ]
    }

    method field(Str $f) { self."$f"() }
}

class vCard {
    has jCard $.card;

    method full-card {
        join "\n",
            "BEGIN:VCARD",
            "VERSION:{$!card.version}",
            "FN:{$!card.fn}",
            "ADR;TYPE=home:;;{$!card.adr[2]};{$!card.adr[3]};{$!card.adr[4]};{$!card.adr[5]};",
            "TEL;TYPE=voice:{$!card.tel.subst(/^ 'tel:' /, '')}",
            "EMAIL:{$!card.email}",
            "END:VCARD",
            ""
    }
}

class Actions {
    method TOP($/) { make jCard.action($/) }
}
