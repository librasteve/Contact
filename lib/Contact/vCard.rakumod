use Contact;

unit module Contact::vCard;

grammar Grammar {
    token TOP {
        'BEGIN:VCARD' \v
        'VERSION:' <-[\v]>+ \v
        <prop>*
        'END:VCARD' \v?
    }

    token prop {
        | <fn>
        | <n>
        | <adr>
        | <tel>
        | <email>
        | <skip>
    }

    token fn    { 'FN:'    <value> \v }
    token n     { 'N:'     <nval>  \v }
    token adr   { 'ADR'   <parms>? ':' <adrval> \v }
    token tel   { 'TEL'   <parms>? ':' <value>  \v }
    token email { 'EMAIL' <parms>? ':' <value>  \v }
    token skip  { <!before 'END:'> \V* \v }

    token parms { <-[:]>+ }
    token value { <-[\v]>+ }

    # N:   family;given;additional;prefix;suffix  (RFC 6350 §6.2.2)
    token nval   { <comp> ** 5 % ';' }
    # ADR: po-box;ext-address;street;locality;region;postal-code;country  (§6.3.1)
    token adrval { <comp> ** 7 % ';' }
    token comp   { <-[;\v]>* }
}

class Actions {
    method TOP($/) {
        my %f;
        for $<prop> -> $p {
            %f<fn>     = ~$p<fn><value>    with $p<fn>;
            %f<nval>   = $p<n><nval>       with $p<n>;
            %f<adrval> = $p<adr><adrval>   with $p<adr>;
            %f<tel>    = ~$p<tel><value>   with $p<tel>;
            %f<email>  = ~$p<email><value> with $p<email>;
        }

        my @n = %f<nval>.defined ?? %f<nval><comp>.map(*.Str) !! (('') xx 5).list;
        my ($family, $given, $additional-str, $prefix, $suffix) = @n;
        my $name = Contact::Name::Name.new(
            family     => ($family  || Str),
            given      => ($given   || Str),
            prefix     => ($prefix  || Str),
            suffix     => ($suffix  || Str),
            additional => Array[Str].new($additional-str.split(/\s+/).grep(*.so)),
        );

        my @adr = %f<adrval>.defined ?? %f<adrval><comp>.map(*.Str) !! (('') xx 7).list;
        my ($po-box, $ext-address, $street, $locality, $region, $postal-code, $country) = @adr;
        my $adr = Contact::Address::Generic.new(
            :$po-box, :$ext-address, :$street,
            :$locality, :$region, :$postal-code, :$country,
        );

        make Contact::Card.new(
            :$name, :$adr,
            tel   => (%f<tel>   || Str),
            email => (%f<email> || Str),
        )
    }
}
