use auth.nu *

export def "series get" [id] {
    let url = $"https://archiveofourown.org/series/($id)"
    let res = auth curl -L $url

    let name = $res | pup -p 'h2 text{}' | str trim
    let author = $res | pup -p 'dl a[rel=author] json{}' | from json | each { $in.text } | str join ", "
    let description = $res | pup -p 'dt:contains("Description") + dd text{}' | str trim
    let published = $res | pup -p 'dt:contains("Series Begun") + dd text{}' | into datetime
    let updated = $res | pup -p 'dt:contains("Series Updated") + dd text{}' | into datetime

    let works = $res | pup 'ul.series.work > li attr{id}'
        | lines
        | each { |css_id|
            let el = $res | pup $'li#($css_id)'
            let series = $name

            let id = $el | pup 'h4 a:first-child attr{href}'
                | parse "/{type}/{id}" | get 0.id

            let name = $el | pup -p 'h4 a:first-child text{}' | str trim
            let author = $el | pup -p 'a[rel=author] json{}' | from json | each { $in.text } | str join ", "
            let updated = $el | pup -p 'p.datetime text{}' | into datetime
            let fandoms = $el | pup -p 'h5.fandoms a json{}' | from json | each { $in.text } | str join ", "

            {
                id: $id
                name: $name
                author: $author
                series: $series
                fandoms: $fandoms
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
