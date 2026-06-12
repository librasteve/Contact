use Contact;
use JSON::Fast;

class Contact::jCard {
    has Contact::Card $.card;

    method to-json {
        given $!card {
            to-json [
                "vcard", [
                    ["version", {},                "text", .version             ],
                    ["fn",      {},                "text", .fn                  ],
                    ["n",       {},                "text", .name.components.list ],
                    ["adr",     {type => "home"},  "text", .adr.components      ],
                    ["tel",     {type => "voice"}, "uri",  .tel                 ],
                    ["email",   {},                "text", .email               ],
                ]
            ]
        }
    }
}
