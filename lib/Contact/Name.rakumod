use Actionable;

class Contact::Name is Actionable {
    my constant @prefix-syns = <Mr Mrs Ms Miss Dr Prof Rev>;
    my constant @suffix-syns = <Jr Sr II III IV Esq PhD MD JD>;

    grammar Grammar {
        regex name {
            [<prefix> \h+]?
            [
            | <given=word> [\h+ <additional=word>]* \h+ <family=word>
            | <family=word>
            ]
            [\h+ <suffix>]?
        }
        token prefix { :i @prefix-syns '.'? }
        token suffix { :i @suffix-syns '.'? }
        token word   { <!before :i @suffix-syns '.'? [\s|$]> \S+ }
    }

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
