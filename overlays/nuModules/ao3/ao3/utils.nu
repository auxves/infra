# converts a date string into a UTC datetime
export def "into date" []: string -> datetime {
    ($in ++ " 00:00:00 +00:00") | into datetime
}

export def retry [
    --interval (-i) = 2min      # Interval between attempts
    --times (-t) = 5            # Number of attempts to make before throwing an error
    --until: closure
    closure
] {
    use std/log

    for attempt in 1..=$times {
        try {
            let res = do $closure
            if (do $until $res) { return $res }
        }

        log warning $"Operation unsuccessful, waiting ($interval)"
        sleep $interval
    }

    error make {msg: "too many failed attempts"}
}
