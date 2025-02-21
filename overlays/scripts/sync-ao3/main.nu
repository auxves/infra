export-env {
    $env.NU_LOG_FORMAT = "%ANSI_START%lvl=%LEVEL% | %MSG%%ANSI_STOP%"
    $env.NU_LOG_LEVEL = $env.NU_LOG_LEVEL? | default $env.LOG_LEVEL? | default "INFO"
}

use std/log

use ao3 *

let state_dir = $env.STATE_DIR
let state_file = $state_dir | path join "state.nuon"

def read-state [] {
    if ($state_file | path exists) {
        open $state_file
    } else {
        []
    }
}

def update-state [delta] {
    $delta
    | select id name author series fandoms updated
    | append (read-state)
    | uniq-by id
    | save -f $state_file
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

    log info "Fetching user bookmarks"

    let incoming_state = try {
        bookmarks get -c $cli -d 10sec $user
        | each { |entry|
            match $entry.type {
                "work" => [ $entry ]
                "series" => {
                    log debug $"Fetching series id=($entry.id)"

                    sleep 5sec
                    series get -c $cli -d 5sec $entry.id | get works
                }
            }
        }
        | flatten
        | uniq-by id
        | reject -i type
    } catch { |err|
        log error $"Unable to get bookmarks: ($err.msg)"
        exit 1
    }

    log debug $"Incoming: ($incoming_state | get id | to json --raw)"

    let saved_state = read-state
        | select id updated
        | rename id last_updated

    let modified_entries = $incoming_state
        | join -l $saved_state id
        | where { $in.updated != $in.last_updated? }

    log debug $"Modified: ($modified_entries | get id | to json --raw)"

    let total = $modified_entries | length

    log info $"There are ($total) works that need to be archived"

    if $dry_run { return }

    let delta = $modified_entries
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
                return
            }

            if ($final_path | path exists) and not (is-safe-to-overwrite $final_path $download_path) {
                log warning $"Work id=($work.id) cannot be overwritten safely, skipping..."
                rm -f $download_path
                return
            }

            mv -f $download_path $final_path

            $work
        }

    update-state $delta
    log info "Updated state successfully"
}
