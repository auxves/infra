use std/log

const BASE_URI = "https://archiveofourown.org"

def --wrapped curl-retry [
    --interval (-i) = 1min      # Interval between attempts
    --times (-t) = 5            # Number of attempts to make before throwing an error
    ...rest
] {
    for attempt in 1..=$times {
        let resp = curl ...$rest

        if ($resp != "Retry later") { return $resp }

        log warning $"ao3: Rate limit exceeded, waiting ($interval)"
        sleep $interval
    }

    error make {msg: "too many failed attempts"}
}

export def "client new" [
    user: string                # ao3 user to log in as
    password: string            # ao3 password to use
    --state-dir (-s): path      # path to store session information; if not specified will be a tmpdir
] {
    let login_url = $"($BASE_URI)/users/login"

    let state_dir = if $state_dir != null { $state_dir } else { mktemp -d }
    mkdir $state_dir

    let cookie_file = $state_dir | path join "ao3.session"

    let authenticity_token = curl-retry -sL $login_url -c $cookie_file
        | pup 'meta[name=csrf-token] attr{content}'

    let login_resp = (curl-retry -s -X POST -c $cookie_file -b $cookie_file
        -H "Content-Type: application/x-www-form-urlencoded"
        --data-urlencode $"user[login]=($user)"
        --data-urlencode $"user[password]=($password)"
        --data-urlencode $"authenticity_token=($authenticity_token)"
        $login_url)

    if ($login_resp | str contains "auth_error") {
        error make {msg: "authentication error"}
    }

    {
        get: { |path| curl-retry -sL -c $cookie_file -b $cookie_file $"($BASE_URI)($path)" }
        download: { |url, filepath| curl-retry -sL -c $cookie_file -b $cookie_file -o $filepath $"($BASE_URI)($url)" }
    }
}

export def "client new-guest" [] {
    {
        get: { |path| curl-retry -sL $"($BASE_URI)($path)" }
        download: { |url, filepath| curl-retry -sL -o $filepath $"($BASE_URI)($url)" }
    }
}
