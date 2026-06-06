use Contact::GrammarBase;

class X::Contact::Address::CannotParse is Exception {
    has Str $.text;
    method message { "Cannot parse address:\n$.text" }
}

grammar Contact::Address::Grammar does Contact::GrammarBase {
    # locale subgrammars provide complete implementation via `is` inheritance
}

class Contact::Address::Actions {
    # locale actions subclass this
}
