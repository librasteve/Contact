role Contact::GrammarBase {
    my @street-types = <Street St Avenue Ave Av Road Rd Lane Ln Boulevard Blvd>;

    token street-type  { @street-types }

    token number       { '#'? \d ** 1..5 }

    token nost-word    { \w+  <?{ $/ ne @street-types.any }> }

    token nost-words   { <nost-word>+ % \h }

    token street       { ^^ [<number> ','? <.ws>]? <nost-words> [<.ws> <street-type> '.'?]? $$ }

    token whole-line   { ^^ \V* $$ }
}

sub prep($address is rw) is export {
    $address ~~ s:g/','$$//;
    $address ~~ s:g/<['\%]>//;
    $address .= chomp;
    $address
}
