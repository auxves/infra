use utils.nu *

export def "blurbs parse" [
    html: string    # html of the blurb
] {
    let href = $html | pup 'h4 a:first-child attr{href}'
        | parse "/{type}/{id}"
        | if ($in | length) < 1 { return null } else { get 0 }

    let type = match $href.type {
        "works" => "work"
        "series" => "series"
    }

    let id = $href.id
    let name = $html | pup -p 'h4 a:first-child text{}' | str trim
    let author = $html | pup -p 'a[rel=author] json{}' | from json | each { $in.text } | str join ", "
    let updated = $html | pup -p 'ul.required-tags + p.datetime text{}' | into date
    let fandoms = $html | pup -p 'h5.fandoms a json{}' | from json | each { $in.text } | str join ", "
    let series = $html | pup -p 'h6:contains("Series") + ul a text{}' | str trim

    {
        id: $id
        type: $type
        name: $name
        author: $author
        series: $series
        fandoms: $fandoms
        updated: $updated
    }
}
