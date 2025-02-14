export-env {
    $env.NU_LOG_FORMAT = "%ANSI_START%[%LEVEL%] %MSG%%ANSI_STOP%"
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

def save-state [state] {
    if ($state | is-empty) and (read-state | is-not-empty) {
        log warning "New state is empty, not overwriting!"
    } else {
        $state | save -f $state_file
        log info "Saved new state successfully"
    }
}

def main [
    --dry-run   # if enabled, no changes will be done to disk
] {
    let user = $env.AO3_USER
    let password = $env.AO3_PASSWORD

    log info "Logging into Archive of Our Own..."

    let cli = try {
        client new $user $password -s $state_dir
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
                "series" => (do {
                    log debug $"Fetching series id=($entry.id)"

                    sleep 5sec
                    series get -c $cli -d 5sec $entry.id | get works
                })
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
        | default null last_updated
        | where { $in.updated != $in.last_updated }

    log debug $"Modified: ($modified_entries | get id | to json --raw)"

    let total = $modified_entries | length

    log info $"There are ($total) works that need to be archived"

    for entry in ($modified_entries | enumerate) {
        let pos = $entry.index + 1
        let work = $entry.item

        log info $"Downloading work ($pos)/($total)"
        log debug $"Work ID: ($work.id)"

        let filepath = $state_dir | path join $"($work.id).epub"

        if not $dry_run {
            try {
                $filepath | path dirname | mkdir $in
                works download -c $cli $work.id $filepath
            } catch { |err|
                log error $"Unable to download: ($err.msg)"
                exit 1
            }

            sleep 10sec # to avoid rate-limiting
        }
    }

    if not $dry_run {
        save-state $incoming_state
    }
}
