# creates a mock client that reads files from the tests/mocks directory
export def "client new-mock" [] {
    {
        get: { |path|
            let path = $path | str substring 1..
            { parent: "tests/mocks", stem: $path, extension: "html" } | path join | open
        }
        
        download: { |url, filepath| }
    }
}
