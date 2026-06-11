use Actionable;
use Contact::Address;

unit module Contact::Address::en_US;

my constant @apt-syns     = <Apt Apartment Suite Ste Unit Flat Fl>;
my constant @country-syns = ('United States of America', 'United States', 'USA', 'US', 'America');

grammar Grammar {
    token adr {
        [ <po-box>      \v ]?
        [ <ext-address> \v ]?
        <street> \v
        <locality> \v
        <region> ' ' <postal-code>
        [ \v <country> ]?
    }

    token po-box      { :i 'PO Box ' <-[\v]>+ }
    token ext-address { [ :i @apt-syns ] ' ' <-[\v]>+ }
    token street      { <-[\v]>+ }
    token locality    { <-[\v]>+ }
    token region      { \S+ }
    token postal-code { \d+ ['-' \d ** 4]? }
    token country     { :i @country-syns }
}

class Address does Contact::Address does Actionable {
    has Str $.po-box;
    has Str $.ext-address;
    has Str $.street;
    has Str $.locality;
    has Str $.region;
    has Str $.postal-code;
    has Str $.country;
}
