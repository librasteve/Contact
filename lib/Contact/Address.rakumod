### common role for Contact::Address data classes ###
role Contact::Address {
    method list-attrs {
        self.^attributes.grep({
            .has_accessor  &&
            .package.^name eq self.^name
        }).map({
            .name.subst(/^'$!'/, '')
        })
    }

    method Str {
        gather {
            for |self.list-attrs {
                my $attr := self."$_"();
                take $attr with $attr
            }
        }.join(",\n")
    }
}

### locale-specific data classes ###

class Contact::Address::USA does Contact::Address {
    has Str $.street;
    has Str $.city;
    has Str $.state;
    has Str $.zip;
    has Str $.country = 'USA';
}

class Contact::Address::UK does Contact::Address {
    has Str $.house;
    has Str $.street;
    has Str $.town;
    has Str $.county;
    has Str $.postcode;
    has Str $.country = 'UK';
}
