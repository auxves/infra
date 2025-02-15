# creates a mock client that reads files from the tests/mocks directory
export def "client new-mock" [] {
    {
        get: { |path|
            let path = $path
                | str substring 1..
                | { parent: "tests/mocks", stem: $in, extension: "html" }
                | path join            

            if ($path | path exists) {
                { body: (open $path), code: 200 }
            } else {
                { body: "", code: 404 }
            }
        }

        download: { |url, filepath| }
    }
}
