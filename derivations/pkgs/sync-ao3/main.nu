use ao3 *

let archive_dir = $env.ARCHIVE_DIR
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
    $state | save -f $state_file
}

def main [] {
    let user = $env.AO3_USER
    let password = $env.AO3_PASSWORD

    print 'level=info msg="Logging into Archive of Our Own..."'

    auth login $user $password

    print 'level=info msg="Logged in successfully!"'

    print 'level=info msg="Fetching user bookmarks"'

    let incoming_state = bookmarks get $user
    let saved_state = get_saved_state

    let modified_entries = $incoming_state
        | join -l $saved_state id
        | default null updated_
        | where { $in.updated != $in.updated_ }

    let total = $modified_entries | length

    print $'level=info msg="There are ($total) works that need to be archived"'

    for entry in ($modified_entries | enumerate) {
        let pos = $entry.index + 1
        let work = $entry.item

        print $'level=info msg="Downloading work ($pos)/($total)"'

        let filepath = $archive_dir | path join $"($work.id).epub"
        $filepath | path dirname | mkdir $in

        works download $work.id $filepath
        sleep 2sec # to avoid rate-limiting
    }

    save_state $incoming_state

    print 'level=info msg="Saved new state successfully"'
}
