use Actionable;
use Contact::Address;

unit module Contact::UK;

grammar Address-Grammar {
    regex adr {
        [ <house>  \n ]?
          <street> \n
          <town>
        [ \h+  <postcode>
        | \n [ <county> [ ','? \h+ <postcode>
                        | \n   <postcode> ]
             | <postcode>
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

class Address does Contact::Address does Actionable {
    has Str $.house;
    has Str $.street;
    has Str $.town;
    has Str $.county;
    has Str $.postcode;
    has Str $.country;

    method ext-address { $.house    }
    method locality    { $.town     }
    method region      { $.county   }
    method postal-code { $.postcode }
}
