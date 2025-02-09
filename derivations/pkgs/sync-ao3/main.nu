use ao3 *

let state_dir = $env.STATE_DIR

let state_file = $state_dir | path join ".state.nuon"

def get_saved_state [] {
    if ($state_file | path exists) {
        open $state_file
    } else {
        []
    }
}

def save_state [state] {
    $state | save -f $state_file
}

def main [
    --dry-run   # if enabled, works will not be downloaded
] {
    let user = $env.AO3_USER
    let password = $env.AO3_PASSWORD

    print "[info] Logging into Archive of Our Own..."

    auth login $user $password

    print "[info] Logged in successfully!"

    print "[info] Fetching user bookmarks"

    let incoming_state = bookmarks get $user

    let saved_state = get_saved_state
        | default null updated
        | select id updated
        | rename id last_updated

    let modified_entries = $incoming_state
        | join -l $saved_state id
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
    
            works download $work.id $filepath
            sleep 2sec # to avoid rate-limiting
        }

        save_state $incoming_state
    }

    print "[info] Saved new state successfully"
}
