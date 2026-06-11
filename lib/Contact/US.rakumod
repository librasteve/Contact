use Actionable;
use Contact::Address;

unit module Contact::US;

my constant @apt-syns     = <Apt Apartment Suite Ste Unit Flat Fl>;
my constant @country-syns = ('United States of America', 'United States', 'USA', 'US', 'America');

grammar Address-Grammar {
    token adr {
        [ <po-box>      \n ]?
        [ <ext-address> \n ]?
        <street> \n
        <locality> \n
        <region> ' ' <postal-code>
        [ \n <country> ]?
    }

    token po-box      { 'PO Box ' <-[\n]>+ }
    token ext-address { [ :i @apt-syns ] ' ' <-[\n]>+ }
    token street      { <-[\n]>+ }
    token locality    { <-[\n]>+ }
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
