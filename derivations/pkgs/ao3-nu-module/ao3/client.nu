export def "client new" [
    user: string                # ao3 user to log in as
    password: string            # ao3 password to use
    --state-dir (-s): path      # path to store session information; if not specified will be a tmpdir
] {
    let login_url = "https://archiveofourown.org/users/login"

    let state_dir = if $state_dir != null { $state_dir } else { mktemp -d }
    mkdir $state_dir

    let cookie_file = $state_dir | path join "ao3.session"

    let authenticity_token = curl -sL $login_url -c $cookie_file
        | pup 'meta[name=csrf-token] attr{content}'

    let login_resp = (curl -s -X POST -c $cookie_file -b $cookie_file
        -H "Content-Type: application/x-www-form-urlencoded"
        --data-urlencode $"user[login]=($user)"
        --data-urlencode $"user[password]=($password)"
        --data-urlencode $"authenticity_token=($authenticity_token)"
        $login_url)

    if ($login_resp | str contains "auth_error") {
        error make {msg: "Authentication error! Credentials may be invalid"}
    }

    {
        get: { |path| curl -sL -c $cookie_file -b $cookie_file $"https://archiveofourown.org($path)" }
        download: { |url, filepath| curl -sL -c $cookie_file -b $cookie_file -o $filepath $"https://archiveofourown.org($url)" }
    }
}

export def "client new-guest" [] {
    {
        get: { |path| curl -sL $"https://archiveofourown.org($path)" }
        download: { |url, filepath| curl -sL -o $filepath $"https://archiveofourown.org($url)" }
    }
}
