use blurbs.nu *
use series.nu *
use utils.nu *

def "bookmarks url" [
    user: string
    --page (-p) = 1
    --sort-by (-s) = "created_at"
] {
    let query = {
        user_id: $user
        page: $page
        bookmark_search[sort_column]: $sort_by
    } | url build-query

    $"/bookmarks?($query)"
}

export def "bookmarks parse" [
    html: string    # html of the bookmarks page
] {
    $html | pup 'li.bookmark attr{id}'
    | lines
    | each { |css_id| $html | pup $'li#($css_id)' | blurbs parse $in }
}

export def "bookmarks get" [
    user: string            # This user's bookmarks will be returned
    --client (-c): record   # client obtained from client new-<type>
    --delay (-d) = 0sec     # delay between loading of additional pages
    --sort-by (-s) = "created_at"
] {
    let url = bookmarks url $user -s $sort_by

    let success = { |res|
        ($res.code == 200) and ($res.body | pup -n 'ol.index.group' | into int) == 1
    }

    let res = retry -i 10sec --until $success { do $client.get $url }

    if $res.code == 404 {
        error make {
            msg: "user not found"
            label: { text: "user", span: (metadata $user).span }
        }
    }

    let entries = bookmarks parse $res.body

    let last_page = $res.body | pup -p 'ul + h4 + ol[role=navigation] li:not([class]) text{}'
        | lines
        | if ($in | is-not-empty) { last | into int } else { 1 }

    generate { |state|
        match $state.entries {
            [$first ..$rest] => {
                let new_state = { entries: $rest, page: $state.page }
                {out: $first, next: $new_state}
            }

            [] => {
                let next_page = $state.page + 1
                if ($next_page > $last_page) { return {} }

                sleep $delay

                let url = bookmarks url $user -s $sort_by -p $next_page
                let res = retry -i 10sec --until $success { do $client.get $url }
                let entries = bookmarks parse $res.body

                let new_state = { entries: ($entries | skip 1), page: $next_page}
                {out: ($entries | first), next: $new_state}
            }
        }
    } { entries: $entries, page: 1 }
}
