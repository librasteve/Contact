role Contact::Address {
    method po-box      { Str }
    method ext-address { Str }
    method street      { Str }
    method locality    { Str }
    method region      { Str }
    method postal-code { Str }
    method country     { Str }

    method attrs      { <po-box ext-address street locality region postal-code country> }
    method components { self.attrs.map: { self."$_"() // '' } }
}

class Contact::Address::Generic does Contact::Address {
    has Str $.po-box;
    has Str $.ext-address;
    has Str $.street;
    has Str $.locality;
    has Str $.region;
    has Str $.postal-code;
    has Str $.country;
}
