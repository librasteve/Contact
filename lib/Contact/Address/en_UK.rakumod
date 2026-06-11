use Actionable;
use Contact::Address;

unit module Contact::Address::en_UK;

my constant @country-syns = (
    'England', 'Scotland', 'Wales', 'Northern Ireland', 'N. Ireland',
    'United Kingdom', 'UK', 'U.K.', 'Great Britain', 'GB', 'Britain',
);

grammar Grammar {
    regex adr {
        [ <po-box> \v ]?
        [ <house>  \v ]?
          <street> \v
          <town>   <.ws>
        [ <county> ','? <.ws> ]?
          <postcode> \v?
        [ <country> \v? ]?
    }

    token po-box   { :i 'PO Box ' <-[\v]>+ }
    token house    { <nodt-words> }
    token town     { <nodt-words> }
    token county   { <nodt-words> }
    token street   { <-[\v]>+ }
    token postcode { \S+ \h \d \w \w }
    token country  { :i @country-syns }

    # no-digit word: rejects street numbers
    token nodt-word  { <[\w\-']>+ <?{ $/ !~~ /\d/ }> }
    token nodt-words { <nodt-word>+ % \h }
}

class Address does Contact::Address does Actionable {
    has Str $.po-box;
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
