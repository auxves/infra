use auth.nu *
use series.nu *

export def "bookmarks get" [
    user: string    # This user's bookmarks will be returned
    --page = 1      # The page to start from
] {
    let url = $"https://archiveofourown.org/users/($user)/bookmarks"
    let res = (
        auth curl -L --get
            --data-urlencode $"page=($page)"
            $url
    )

    let parse_work = { |el|
        let id = $el | pup 'h4 a:first-child attr{href}'
            | parse "/{type}/{id}" | get 0.id

        let name = $el | pup -p 'h4 a:first-child text{}' | str trim
        let author = $el | pup -p 'a[rel=author] json{}' | from json
            | each { $in.text } | str join ", "
        let updated = $el | pup -p 'ul.required-tags + p.datetime text{}' | into datetime
        let series = $el | pup -p 'h6:contains("Series") + ul a text{}' | str trim
            | if ($in | is-not-empty) { $in } else { null }
        let fandoms = $el | pup -p 'h5.fandoms a json{}' | from json
            | each { $in.text } | str join ", "

        [{
            id: $id
            name: $name
            author: $author
            series: $series
            fandoms: $fandoms
            updated: $updated
        }]
    }

    let parse_series = { |el|
        let id = $el | pup 'h4 a:first-child attr{href}'
            | parse "/{type}/{id}" | get 0.id

        sleep 8sec # avoid rate-limiting
        series get $id | get works
    }

    let works = $res | pup 'li.bookmark attr{id}'
        | lines
        | each { |css_id|
            let el = $res | pup $'li#($css_id)'
            let type = $el | pup 'h4 a:first-child attr{href}'
                | parse "/{type}/{id}" | get 0.type

            match $type {
                "works" => (do $parse_work $el)
                "series" => (do $parse_series $el)
            }
        }
        | flatten

    if ($works | is-empty) { return [] }

    ($works ++ (do {
        sleep 10sec
        bookmarks get $user --page ($page + 1)
    })) | uniq-by id
}
