use std/assert

use ../utils.nu *
use ../../ao3/works.nu *

export def works-get [] {
    let cli = client new-mock
    let rec = works get -c $cli 561

    assert equal $rec {
        id: "561"
        name: "A vaguely accurate RPF story about the Archive partially told in ALT text"
        author: "samvara"
        series: {id: "443", name: "Archive of Our Own"},
        published: 2008-10-03T00:00:00,
        updated: 2008-10-03T00:00:00,
        tags: ["General Audiences", "No Archive Warnings Apply", Gen, "Archive of Our Own", "OTW - RPF", Astolat, "Black Samvara", Crack, Humor, Historical]
    }

    # ensure pseuds are parsed correctly
    let rec = works get -c $cli 6
    assert equal $rec.author "Ice is Blue (ice_is_blue)"
}
