export-env {
    use std/log []
}

export use ./client.nu [ "client new" "client new-guest" ]
export use ./series.nu [ "series get" "series parse" ]
export use ./works.nu [ "works get" "works parse" "works download" ]
export use ./bookmarks.nu [ "bookmarks get" "bookmarks parse" ]
