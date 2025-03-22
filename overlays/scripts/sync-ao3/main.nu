export-env {
    $env.NU_LOG_FORMAT = "%ANSI_START%lvl=%LEVEL% | %MSG%%ANSI_STOP%"
    $env.NU_LOG_LEVEL = $env.NU_LOG_LEVEL? | default $env.LOG_LEVEL? | default "INFO"
}

use std/log

use ao3 *

let state_dir = $env.STATE_DIR
let state_file = $state_dir | path join "state.nuon"

def "str indent-by" [amt: int]: string -> string {
    let prefix = 0..$amt | each { " " } | str join
    $in | lines | each { $prefix ++ $in } | str join "\n"
}

def today-utc [] {
    date now | format date "%Y-%m-%d" | ($in ++ " 00:00:00 +00:00") | into datetime
}

def read-state [] {
    if ($state_file | path exists) {
        open $state_file
    } else {
        { bookmarks: [], last_updated: ("1970-1-1" | into datetime) }
    }
}

def update-state [delta] {
    let new_bookmarks = $delta
        | append (read-state).bookmarks
        | uniq-by id type

    {
        bookmarks: $new_bookmarks
        last_updated: (today-utc)
    } | save -f $state_file
}

def size-of [file: path] {
    du $file | get 0.apparent | into int
}

def is-safe-to-overwrite [old: path, new: path] {
    let size_new = size-of $new
    let size_old = size-of $old
    let min_size = $size_old * 0.8

    $size_new > $min_size
}

def main [
    --dry-run   # if enabled, no changes will be done to disk
] {
    let user = $env.AO3_USER
    let password = $env.AO3_PASSWORD

    log info "Logging into Archive of Our Own..."

    let cli = try {
        client new $user $password -s $state_dir -i 5min
    } catch { |err|
        log error $"Unable to log in: ($err.msg)"
        exit 1
    }

    log info "Logged in successfully!"

    let state = read-state

    let ids = {
        series: ($state.bookmarks | where type == series | get id)
        work: ($state.bookmarks | where type == work | get id)
    }

    log info "Fetching new bookmarks"

    let new_bookmarks = try {
        bookmarks get $user -c $cli -d 10sec -s "created_at"
        | take while { |bm| $bm.id not-in ($ids | get $bm.type) }
    } catch { |err|
        log error $"Unable to get new bookmarks: ($err.msg)
($err.rendered | str indent-by 4)"
        exit 1
    }

    log debug $"New Bookmarks:
($new_bookmarks | select id type name | table | str indent-by 4)"

    log info "Fetching updated bookmarks"

    let updated_bookmarks = try {
        bookmarks get $user -c $cli -d 10sec -s "bookmarkable_date"
        | take while { $in.updated >= $state.last_updated }
    } catch { |err|
        log error $"Unable to get updated bookmarks: ($err.msg)
($err.rendered | str indent-by 4)"
        exit 1
    }

    log debug $"Updated Bookmarks:
($updated_bookmarks | select id type name | table | str indent-by 4)"

    let delta = $new_bookmarks ++ $updated_bookmarks
        | uniq-by id type
        | each { |entry|
            match $entry.type {
                "work" => $entry
                "series" => {
                    sleep 5sec
                    let works = series get -c $cli -d 5sec $entry.id | get works

                    log debug $"Fetched series id=($entry.id) with works:
($works | select id name | table | str indent-by 4)"

                    $entry | upsert works $works
                }
            }
        }

    let modified_works = try {
        $delta
        | each { |entry|
            match $entry.type {
                "work" => [ $entry ]
                "series" => {
                    let works = $entry.works

                    if $entry.id in $ids.series {
                        # series was updated, only include updated works
                        $works | filter { $in.updated >= $state.last_updated }
                    } else {
                        # series is new, include works not already in bookmarks unless updated
                        $works | filter { $in.id not-in $ids.work or $in.updated >= $state.last_updated }
                    }
                }
            }
        }
        | flatten
        | uniq-by id
        | reject -i type
    } catch { |err|
        log error $"Unable to calculate modified works: ($err.msg)
($err.rendered | str indent-by 4)"
        exit 1
    }

    log debug $"Modified:
($modified_works | select id name | table | str indent-by 4)"

    let total = $modified_works | length

    log info $"There are ($total) works that need to be archived"

    if $dry_run { return }

    $modified_works
        | enumerate
        | each { |entry|
            let pos = $entry.index + 1
            let work = $entry.item

            let final_path = $state_dir | path join $"($work.id).epub"
            $final_path | path dirname | mkdir $in
            let download_path = $final_path ++ ".download"

            log info $"Downloading work id=($work.id) \(($pos)/($total)\)"
            sleep 10sec # to avoid rate-limiting

            try {
                works download -c $cli $work.id $download_path
            } catch { |err|
                log error $"Work id=($work.id) did not download successfully: ($err.msg)"
                exit 1
            }

            if ($final_path | path exists) and not (is-safe-to-overwrite $final_path $download_path) {
                log warning $"Work id=($work.id) cannot be overwritten safely, skipping..."
                rm -f $download_path
                return
            }

            mv -f $download_path $final_path
        }

    update-state $delta
    log info "Updated state successfully"
}
