use std/assert

use ../utils.nu *
use ../../ao3 ["series get"]

export def series-get [] {
    let cli = client new-mock
    let rec = series get -c $cli 3

    assert equal $rec {
        id: "3"
        name: "Balance&Brace"
        author: "cupidsbow"
        description: "John has a problem after The Siege, and its name is Rodney."
        published: 2008-09-16T00:00:00
        updated: 2008-09-16T00:00:00
        works: [
            [id, type, name, author, series, fandoms, updated];
            ["58", work, Balance, cupidsbow, "Balance&Brace", "Stargate Atlantis", 2008-09-16T00:00:00]
            ["59", work, Brace, cupidsbow, "Balance&Brace", "Stargate Atlantis", 2008-09-16T00:00:00]
        ]
    }

    # ensure all works for paginated series are parsed
    let rec = series get -c $cli 1669567
    assert equal ($rec.works | length) 60
}
