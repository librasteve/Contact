my constant %name-syns = (
    prefix => <Mr Mrs Ms Miss Dr Prof Rev>,
    suffix => <Jr Sr II III IV Esq PhD MD JD>,
);

sub is-prefix(Str $w) { so $w.match(/^ :i @(%name-syns<prefix>) '.'? $/) }
sub is-suffix(Str $w) { so $w.match(/^ :i @(%name-syns<suffix>) '.'? $/) }

grammar Contact::Name-Grammar {
    token TOP  { <word>+ % \h+ \h* }
    token word { \S+ }
}

class Contact::Name {
    has Str $.prefix     = '';
    has Str $.given      = '';
    has Str $.additional = '';
    has Str $.family     = '';
    has Str $.suffix     = '';
}

class Contact::Name-Actions {
    method TOP($/) {
        my @all = $<word>>>.Str;
        my int $s = 0;
        my int $e = @all.elems - 1;

        my $prefix = '';
        if @all && is-prefix(@all[$s]) { $prefix = @all[$s++] }

        my $suffix = '';
        if $e >= $s && is-suffix(@all[$e]) { $suffix = @all[$e--] }

        my @w = $e >= $s ?? @all[$s .. $e].Array !! [];

        my ($given, $additional, $family) = do given @w.elems {
            when 0 { ('', '', $prefix || '') }
            when 1 { ('', '', @w[0]) }
            when 2 { (@w[0], '', @w[1]) }
            default { (@w[0], @w[1..^*-1].join(' '), @w[*-1]) }
        }

        make Contact::Name.new(:$prefix, :$given, :$additional, :$family, :$suffix);
    }
}
