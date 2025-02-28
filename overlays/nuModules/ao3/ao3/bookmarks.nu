use series.nu *
use utils.nu *

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
] {
    let url = $"/users/($user)/bookmarks?page=1"

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

    let pages = $res.body | pup -p 'ul + h4 + ol[role=navigation] li:not([class]) text{}' | lines | skip 1

    $pages | reduce --fold $entries { |page, acc|
        sleep $delay

        let url = $"/users/($user)/bookmarks?page=($page)"

        let res = retry -i 10sec --until $success { do $client.get $url }

        $acc ++ (bookmarks parse $res.body)
    }
}
