use utils.nu *

export def "works parse" [html: string] {
    let id = $html | pup 'input#kudo_commentable_id attr{value}'
    let name = $html | pup -p 'h2.title text{}' | str trim
    let author = $html | pup -p 'h3.byline a[rel=author] json{}' | from json | each { $in.text } | str join ", "
    let published = $html | pup 'dd[class=published] text{}' | into date
    let updated = $html | pup 'dd[class=status] text{}' | if ($in | is-empty) { $published } else { into date }
    let tags = $html | pup -p 'dd.tags li a text{}' | lines

    let series = $html | pup 'span.series > span.position a json{}' | from json
        | (if ($in | is-empty) { null }
           else { get 0
                | insert id { |r| $r.href | str replace "/series/" "" }
                | rename -c { text: name }
                | select id name })

    {
        id: $id
        name: $name
        author: $author
        series: $series
        published: $published
        updated: $updated
        tags: $tags
    }
}

export def "works get" [
    id: string                  # id of the work
    --client (-c): record       # client obtained from client new-<type>
] {
    let url = $"/works/($id)"
    let res = do $client.get $url

    works parse $res
}

export def "works download" [
    id: string                  # id of the work
    path: path                  # filepath to download to
    --client (-c): record       # client obtained from client new-<type>
] {
    let url = $"/downloads/($id)/Work.epub"
    do $client.download $url $path
}
