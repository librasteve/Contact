use Contact;
use Contact::Name;
use Contact::Address;

class Contact::vCard {
    has Contact::Card $.card;

    grammar Grammar {
        token TOP {
            'BEGIN:VCARD' \v
            'VERSION:' <-[\v]>+ \v
            [
            | <fn>
            | <n>
            | <adr>
            | <tel>
            | <email>
            | <skip>
            ]*
            <?{ $<fn> && $<n>.elems <= 1 }>
            'END:VCARD' \v?
        }
        token fn    { 'FN:'    <value> \v }
        token n     {
            'N:'
            <family=comp> ';' <given=comp> ';' <additional=word>* % \h ';'
            <prefix=comp> ';' <suffix=comp>
            \v
        }
        token word  { <-[;\v\h]>+ }
        token adr   {
            'ADR' <parms>? ':'
            <po-box=comp>   ';' <ext-address=comp> ';' <street=comp>      ';'
            <locality=comp> ';' <region=comp>       ';' <postal-code=comp> ';'
            <country=comp>
            \v
        }
        token tel   { 'TEL'   <parms>? ':' <value> \v }
        token email { 'EMAIL' <parms>? ':' <value> \v }
        token skip  { <!before 'END:'> \V* \v }
        token parms { <-[:]>+ }
        token value { <-[\v]>+ }
        token comp  { <-[;\v]>* }
    }

    sub name-from-fn(Str $fn) {
        Contact::Name.action(Contact::Name::Grammar.parse($fn, :rule<name>));
    }

    class Actions {
        method TOP($/) {
            my %extra;
            %extra<name> = $<n>
                ?? $<n>[0].made
                !! name-from-fn($<fn>[0].made);
            make Contact::Card.action($/, |%extra)
        }
        method fn($/)    { make ~$<value> }
        method n($/)     { make Contact::Name.action($/)              }
        method adr($/)   { make Contact::Address::Generic.action($/)  }
        method tel($/)   { make ~$<value> }
        method email($/) { make ~$<value> }
    }

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

    method parse(Str:D $vcard --> Contact::Card) {
        Grammar.parse($vcard, actions => Actions.new).made
            // X::Contact::CannotParse.new(:text($vcard)).throw
    }
}
