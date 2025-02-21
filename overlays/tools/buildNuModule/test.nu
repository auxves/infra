# Taken from nupm: https://github.com/nushell/nupm/blob/e9f39eac45f8043261f18e85080f487a757f7d95/nupm/test.nu

export def throw-error [
    error: string
    text?: string
    --span: record<start: int, end: int>
] {
    let error = $"(ansi red_bold)($error)(ansi reset)"

    if $span == null {
        if $text == null {
            error make --unspanned { msg: $error }
        } else {
            error make --unspanned { msg: ($error + "\n" + $text) }
        }
    }

    error make {
        msg: $error
        label: {
            text: ($text | default "this caused an internal error")
            start: $span.start
            end: $span.end
        }
    }
}

# Experimental test runner
export def main [
    filter?: string  = ''  # Run only tests containing this substring
    --dir: path  # Directory where to run tests (default: $env.PWD)
    --show-stdout  # Show standard output of each test
]: nothing -> nothing {
    let dir = ($dir | default $env.PWD | path expand -s)
    let pkg_root = $dir

    if ($pkg_root | path join "tests" | path type) != "dir" {
        return
    }

    if ($pkg_root | path join "tests" "mod.nu" | path type) != "file" {
        return
    }

    print $'Testing package ($pkg_root)'
    cd $pkg_root

    let tests = ^$nu.current-exe ...[
        --no-config-file
        --commands
        'use tests/

        scope commands
        | where ($it.name | str starts-with tests)
        | get name
        | to nuon'
    ]
    | from nuon

    let out = $tests
        | where ($filter in $it)
        | par-each {|test|
            let res = do {
                ^$nu.current-exe ...[
                    --no-config-file
                    --commands
                    $'use tests/; ($test)'
                ]
            }
            | complete

            if $res.exit_code == 0 {
                print $'($test) ... (ansi gb)SUCCESS(ansi reset)'
            } else {
                print $'($test) ... (ansi rb)FAILURE(ansi reset)'
            }

            if $show_stdout {
                print 'stdout:'
                print $res.stdout
            }

            {
                name: $test
                stdout: $res.stdout
                stderr: $res.stderr
                exit_code: $res.exit_code
            }
        }

    let successes = $out | where exit_code == 0
    let failures = $out | where exit_code != 0

    $failures | each {|fail|
        print ($'(char nl)Test "($fail.name)" failed with exit code'
            + $' ($fail.exit_code):(char nl)'
            + ($fail.stderr | str trim))
    }

    if ($failures | length) != 0 {
        print ''
    }

    print ($'Ran ($out | length) tests.'
        + $' ($successes | length) succeeded,'
        + $' ($failures | length) failed.')

    if ($failures | length) != 0 {
        error make --unspanned {msg: "some tests failed"}
    }
}
