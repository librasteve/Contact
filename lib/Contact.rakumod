use Actionable;

unit class Contact;

grammar Grammar {
    token TOP     { <name> \n <address> 'Tel: ' <phone> \n 'Email: ' <email> \n? }
    token name    { <-[\n]>+ }
    token address { [<!before 'Tel:'> <-[\n]>+ \n]+ }
    token phone   { <-[\n]>+ }
    token email   { <-[\n]>+ }
}

class vCard does Actionable {
    has $.name;
    has $.address;
    has $.phone;
    has $.email;

    method transform(Str $attr, $raw) { $raw.trim }

    method full-card {
        my $adr = $!address.lines.join('\\n');
        join "\n",
            "BEGIN:VCARD",
            "VERSION:4.0",
            "FN:$!name",
            "ADR;TYPE=home:;;$adr;;;",
            "TEL;TYPE=voice:$!phone",
            "EMAIL:$!email",
            "END:VCARD",
            ""
    }

    method field(Str $f) { self."$f"() }

    method json {
        use JSON::Fast;
        my ($street, $locality, $region-zip) = $!address.lines;
        my ($region, $postal-code)           = ($region-zip // '').split(' ', 2);
        to-json [
            "vcard", [
                ["version", {},               "text", "4.0"                                              ],
                ["fn",      {},               "text", $!name                                             ],
                ["adr",     {type => "home"}, "text", ["", "", $street//'', $locality//'',
                                                             $region//'', $postal-code//'', ""]          ],
                ["tel",     {type => "voice"},"uri",  "tel:$!phone"                                      ],
                ["email",   {},               "text", $!email                                            ],
            ]
        ]
    }
}

class Actions {
    method TOP($/) { make vCard.action($/) }
}
