#use Grammar::Tracer;  # uncomment for debug
use Contact::GrammarBase;
use Contact::Address::Grammar;
use Contact::Address;

# ── Exception ──────────────────────────────────────────────────────────────
class X::Contact::Address::en_US::CannotParse is X::Contact::Address::CannotParse {
    method message { "Cannot parse US address:\n$.text" }
}

# ── Grammar ────────────────────────────────────────────────────────────────
grammar Contact::Address::Grammar::en_US is Contact::Address::Grammar {
    token TOP {
              <street>    \v
              <city> ','? <.ws>
              <state>     <.ws>
              <zip>       \v?
            [ <country>   \v? ]?
    }
    token city    { <nost-words> }
    token state   { \w ** 2 }
    token zip     { \d ** 5 ('-' \d ** 4)? }
    token country { <whole-line> }
}

# ── Actions ────────────────────────────────────────────────────────────────
class Contact::Address::Actions::en_US is Contact::Address::Actions {
    method TOP($/) {
        my %a;
        for <street city state zip country> -> $field {
            %a{$field} = $/{$field}.made with $/{$field}
        }
        make Contact::Address::USA.new: |%a
    }
    method street($/)  { make ~$/ }
    method city($/)    { make ~$/ }
    method state($/)   { make ~$/ }
    method zip($/)     { make ~$/ }
    method country($/) { make ~$/ }
}

# ── Entry point ────────────────────────────────────────────────────────────
sub parse(Str $text is copy) is export {
    my $prepped = prep($text);
    my $match   = Contact::Address::Grammar::en_US.parse($prepped,
                      :actions(Contact::Address::Actions::en_US.new));
    ($match andthen .made) // X::Contact::Address::en_US::CannotParse.new(:text($prepped)).throw
}
