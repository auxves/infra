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
    | each { |css_id|
        let el = $html | pup $'li#($css_id)'
        let href = $el | pup 'h4 a:first-child attr{href}'
            | parse "/{type}/{id}"
            | if ($in | length) < 1 { return null } else { get 0 }

        let type = match $href.type {
            "works" => "work"
            "series" => "series"
        }

        let id = $href.id
        let name = $el | pup -p 'h4 a:first-child text{}' | str trim
        let author = $el | pup -p 'a[rel=author] json{}' | from json | each { $in.text } | str join ", "
        let updated = $el | pup -p 'ul.required-tags + p.datetime text{}' | into date
        let fandoms = $el | pup -p 'h5.fandoms a json{}' | from json | each { $in.text } | str join ", "
        let series = $el | pup -p 'h6:contains("Series") + ul a text{}' | str trim

        {
            type: $type
            id: $id
            name: $name
            author: $author
            series: $series
            fandoms: $fandoms
            updated: $updated
        }
    }
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
