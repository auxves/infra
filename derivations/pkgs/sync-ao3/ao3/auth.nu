def cookie_file [] { $env.STATE_DIR | path join ".session.txt" }

export def --wrapped "auth curl" [...rest] {
    if (cookie_file | path exists) {
        curl -s -c (cookie_file) -b (cookie_file) ...$rest
    } else {
        curl -s -c (cookie_file) ...$rest
    }
}

export def "auth login" [user: string, password: string] {
    let url = "https://archiveofourown.org/users/login"

    let authenticity_token = auth curl -L $url
        | pup 'meta[name=csrf-token] attr{content}'

    if (cookie_file | open | str contains "user_credentials") { return }

    (auth curl -X POST
        -H "Content-Type: application/x-www-form-urlencoded"
        --data-urlencode $"user[login]=($user)"
        --data-urlencode $"user[password]=($password)"
        --data-urlencode $"authenticity_token=($authenticity_token)"
        $url) | ignore
}
