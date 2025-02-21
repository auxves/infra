use utils.nu *

export def "works parse" [
    id: string      # id of the work
    html: string    # html content of the work page
] {
    let name = $html | pup -p 'h2.title text{}' | str trim
    let author = $html | pup -p 'h3.byline a[rel=author] json{}' | from json | each { $in.text } | str join ", "
    let published = $html | pup 'dd[class=published] text{}' | into date
    let updated = $html | pup 'dd[class=status] text{}' | if ($in | is-empty) { $published } else { into date }
    let tags = $html | pup -p 'dd.tags li a text{}' | lines

    let series = $html | pup 'span.series > span.position a json{}' | from json
        | (if ($in | is-empty) { null }
           else { get 0
                | upsert id { |r| $r.href | str replace "/series/" "" }
                | select id text
                | rename id name })

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

    if $res.code == 404 {
        error make {
            msg: "work not found"
            label: { text: "id", span: (metadata $id).span }
        }
    }

    works parse $id $res.body
}

export def "works download" [
    id: string                  # id of the work
    path: path                  # filepath to download to
    --client (-c): record       # client obtained from client new-<type>
] {
    let url = $"/downloads/($id)/Work.epub"

    let res = do $client.get $url

    if $res.code != 200 {
        error make {msg: $"got status ($res.code)"}
    }

    if ($res.body | describe) != "binary" {
        error make {msg: $"invalid body"}
    }

    $res.body | save -f $path
}
