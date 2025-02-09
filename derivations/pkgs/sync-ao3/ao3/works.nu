use auth.nu *

export def "works get" [id] {
    let url = $"https://archiveofourown.org/works/($id)"
    let res = auth curl -L $url

    let name = $res | pup 'h2.title text{}' | str trim
    let author = $res | pup 'a[rel=author] text{}'
    let published = $res | pup 'dd[class=published] text{}' | into datetime
    let updated = $res | pup 'dd[class=status] text{}' | if ($in | is-empty) { $published } else { into datetime }
    let tags = $res | pup -p 'dd.tags li a text{}' | lines

    let downloads = $res | pup 'li.download ul a attr{href}' | lines | each { |path| [
        ($path | str replace -r ".*\\.([^?]+).*" "$1")
        ("https://archiveofourown.org" ++ $path)
    ] } | into record

    let series = $res | pup 'span.series > span.position a json{}' | from json
        | (if ($in | is-empty) { null }
           else { get 0
                | insert id { |r| print $r; $r.href | str replace "/series/" "" }
                | rename -c { text: name }
                | select id name })

    {
        id: $id
        url: $url
        name: $name
        author: $author
        series: $series
        published: $published
        updated: $updated
        tags: $tags
        downloads: $downloads
    }
}

export def "works download" [id: string, path: path] {
    let url = $"https://archiveofourown.org/downloads/($id)/Work.epub"
    auth curl -L -o $path $url
}
