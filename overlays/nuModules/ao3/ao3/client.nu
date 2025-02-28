use std/log

use utils.nu *

const BASE_URI = "https://archiveofourown.org"

def --wrapped curl-retry [
    --interval (-i) = 2min      # Interval between attempts
    ...rest
] {
    let success = { |res| $res.code != 429 }

    retry -i $interval --until $success {
        let res = curl -s -w "%{stderr}%{json}" ...$rest | complete
        let meta = $res.stderr | from json
        {body: $res.stdout, code: $meta.response_code}
    }
}

export def "client new" [
    user: string                        # ao3 user to log in as
    password: string                    # ao3 password to use
    --state-dir (-s): path              # path to store session information; if not specified will be a tmpdir
    --interval (-i) = 2min              # time between retry attempts when rate-limited
] {
    let login_url = $"($BASE_URI)/users/login"

    let state_dir = if $state_dir != null { $state_dir } else { mktemp -d }
    mkdir $state_dir

    let cookie_file = $state_dir | path join "ao3.session"

    let res = curl-retry -i $interval -L $login_url -c $cookie_file

    if $res.code == 302 {
        return # already logged in
    }

    let token = $res.body | pup 'meta[name=csrf-token] attr{content}'

    let res = (curl-retry  -i $interval -X POST
        -c $cookie_file -b $cookie_file
        -H "Content-Type: application/x-www-form-urlencoded"
        --data-urlencode $"user[login]=($user)"
        --data-urlencode $"user[password]=($password)"
        --data-urlencode $"authenticity_token=($token)"
        $login_url)

    if $res.code != 302 {
        error make {msg: "authentication error"}
    }

    {
        get: { |path| curl-retry -i $interval -L -c $cookie_file -b $cookie_file $"($BASE_URI)($path)" }
    }
}

export def "client new-guest" [
    --interval (-i) = 2min   # time between retry attempts when rate-limited
] {
    {
        get: { |path| curl-retry -i $interval -L $"($BASE_URI)($path)" }
    }
}
