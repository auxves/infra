use ao3 *

let state_dir = $env.STATE_DIR

let state_file = $state_dir | path join "state.nuon"

def get_saved_state [] {
    if ($state_file | path exists) {
        open $state_file
    } else {
        []
    }
}

def save_state [state] {
    if ($state | is-empty) and (get_saved_state | is-not-empty) {
        print "[warn] New state is empty, something probably went wrong"
        return
    }

    $state | save -f $state_file
}

def main [
    --dry-run   # if enabled, no changes will be done to disk
] {
    let user = $env.AO3_USER
    let password = $env.AO3_PASSWORD

    print "[info] Logging into Archive of Our Own..."

    let cli = client new $user $password -s $state_dir

    print "[info] Logged in successfully!"

    print "[info] Fetching user bookmarks"

    let incoming_state = bookmarks get -c $cli -d 10sec $user
        | each { |entry|
            match $entry.type {
                "work" => [ $entry ]
                "series" => (do {
                    sleep 5sec
                    series get -c $cli -d 5sec $entry.id | get works
                })
            }
        }
        | flatten
        | uniq-by id
        | reject -i type

    let saved_state = get_saved_state
        | select id updated
        | rename id last_updated

    let modified_entries = $incoming_state
        | join -l $saved_state id
        | default null last_updated
        | where { $in.updated != $in.last_updated }

    let total = $modified_entries | length

    print $"[info] There are ($total) works that need to be archived"

    if not $dry_run {
        for entry in ($modified_entries | enumerate) {
            let pos = $entry.index + 1
            let work = $entry.item

            print $"[info] Downloading work ($pos)/($total)"

            let filepath = $state_dir | path join $"($work.id).epub"
            $filepath | path dirname | mkdir $in
    
            works download -c $cli $work.id $filepath
            sleep 10sec # to avoid rate-limiting
        }

        save_state $incoming_state
        print "[info] Saved new state successfully"
    } else {
        print $incoming_state
    }
}
