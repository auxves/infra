use auth.nu *

export def "series get" [id] {
    let url = $"https://archiveofourown.org/series/($id)"
    let res = auth curl -L $url

    let name = $res | pup -p 'h2 text{}' | str trim
    let author = $res | pup -p 'dl a[rel=author] text{}'
    let description = $res | pup -p 'dl.series > :nth-child(8) text{}' | str trim
    let published = $res | pup -p 'dl.series > :nth-child(4) text{}' | into datetime
    let updated = $res | pup -p 'dl.series > :nth-child(6) text{}' | into datetime

    let works = $res | pup 'ul.series.work > li attr{id}'
        | lines
        | each { |css_id|
            let el = $res | pup $'li#($css_id)'

            let id = $el | pup 'h4 a:first-child attr{href}'
                | parse "/{type}/{id}" | get 0.id

            let name = $el | pup -p 'h4 a:first-child text{}' | str trim
            let author = $el | pup -p 'a[rel=author] text{}' | str trim
            let updated = $el | pup -p 'p.datetime text{}' | into datetime

            {
                id: $id
                name: $name
                author: $author
                updated: $updated
            }
        }

    {
        id: $id
        url: $url
        name: $name
        author: $author
        description: $description
        published: $published
        updated: $updated
        works: $works
    }
}
