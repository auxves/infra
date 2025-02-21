# converts a date string into a UTC datetime
export def "into date" []: string -> datetime {
    ($in ++ " 00:00:00 +00:00") | into datetime
}
