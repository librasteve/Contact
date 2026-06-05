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

    method json { self.action-to-json }
}

class Actions {
    method TOP($/) { make vCard.action($/) }
}
