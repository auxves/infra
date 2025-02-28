use utils.nu *

export def "series parse" [
    id: string      # id of the series
    html: string    # html content of the series page
] {
    let name = $html | pup -p 'h2 text{}' | str trim
    let author = $html | pup -p 'dl a[rel=author] json{}' | from json | each { $in.text } | str join ", "
    let description = $html | pup -p 'dt:contains("Description") + dd text{}' | str trim
    let published = $html | pup -p 'dt:contains("Series Begun") + dd text{}' | into date
    let updated = $html | pup -p 'dt:contains("Series Updated") + dd text{}' | into date

    let works = $html | pup 'ul.series.work > li attr{id}'
        | lines
        | each { |css_id|
            let el = $html | pup $'li#($css_id)'
            let series = $name

            let id = $el | pup 'h4 a:first-child attr{href}'
                | parse "/{type}/{id}" | get 0.id

            let name = $el | pup -p 'h4 a:first-child text{}' | str trim
            let author = $el | pup -p 'a[rel=author] json{}' | from json | each { $in.text } | str join ", "
            let updated = $el | pup -p 'p.datetime text{}' | into date
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
        name: $name
        author: $author
        description: $description
        published: $published
        updated: $updated
        works: $works
    }
}

export def "series get" [
    id: string              # the id of the series
    --client (-c): record   # client obtained from client new-<type>
    --delay (-d) = 0sec     # delay between loading of additional pages
] {
    let url = $"/series/($id)"

    let success = { |res| $res.code == 200 }
    let res = retry -i 10sec --until $success { do $client.get $url }

    if $res.code == 404 {
        error make {
            msg: "series not found"
            label: { text: "id", span: (metadata $id).span }
        }
    }

    let series = series parse $id $res.body
    let works = $series | get works

    let pages = $res.body | pup -p 'ul + h4 + ol[role=navigation] li:not([class]) text{}' | lines | skip 1

    let works = $pages | reduce --fold $works { |page, acc|
        sleep $delay

        let url = $"/series/($id)?page=($page)"
        let res = retry -i 10sec --until $success { do $client.get $url }

        $acc ++ (series parse $id $res.body | get works)
    }

    $series | upsert works $works
}
