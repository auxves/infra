use std/assert

use ../utils.nu *
use ../../ao3 ["bookmarks get"]

export def bookmarks-get [] {
    let cli = client new-mock
    let entries = bookmarks get -c $cli samvara

    assert equal $entries [
        [type, id, name, author, series, fandoms, updated];

        # Page 1
        [work, "120496", Indelible, shaenie, "", "Stargate: Atlantis", 2010-09-24T00:00:00]
        [work, "122131", "How Not to Fly", toomuchplor, "How Not to Fly", "Stargate Atlantis", 2010-09-28T00:00:00]
        [work, "61303", "A Study in Natural Philosophy", Mad_Maudlin, "", "Merlin (TV)", 2010-02-10T00:00:00]
        [work, "134755", "Con Dance", OnYourMark, "", "White Collar", 2010-11-20T00:00:00]
        [series, "211", "Drastically Redefining Protocol", rageprufrock, "", "Merlin (BBC), Merlin (TV), Merlin - Fandom", 2016-02-05T00:00:00]
        [work, "14832", "The Death of Jensen Ackles", james, "", "Supernatural RPS", 2009-11-17T00:00:00]
        [work, "85844", Terraform, james, "", "Supernatural RPF", 2010-05-10T00:00:00]
        [work, "133805", "Waiting for My Real Life to Begin", Sena, "Waiting to Begin", "Supernatural RPF", 2010-11-17T00:00:00]
        [work, "135294", "Ours is a Reciprocal Gravitation Orbit", Viridescence, Orbit!Verse, "Supernatural RPF, CW Network RPF", 2010-11-24T00:00:00]
        [work, "91894", "The Girlfriend Experience", rageprufrock, "", Supernatural, 2010-06-03T00:00:00]
        [work, "86345", "Out Of This Darkness", Maygra, "", Supernatural, 2006-04-03T00:00:00]
        [work, "135090", "A Priori", rubberbutton, "A Priori 'Verse", "Sherlock (TV)", 2010-11-23T00:00:00]
        [work, "86037", "Like a Fish Needs a Bicycle", "Netgirl_y2k", "", "Merlin (TV)", 2010-05-12T00:00:00]
        [work, "137551", "I Got Soul but I'm Not a Soldier", starandrea, "", Supernatural, 2010-12-04T00:00:00]
        [work, "102470", "Five Sons Mr and Mrs Bennet Never Had", biichan, "", "Pride and Prejudice - Austen, AUSTEN Jane - Works", 2010-08-27T00:00:00]
        [work, "61002", Restraint, DarkEmeralds, "", "Supernatural RPF", 2011-01-11T00:00:00]
        [work, "91885", "The Student Prince", FayJay, "The student prince", "Merlin - Fandom", 2010-07-10T00:00:00]
        [work, "17017", "The Buttcrack of Dawn", kyuuketsukirui, "", Supernatural, 2007-08-28T00:00:00]
        [series, "2180", "Ordeals 'Verse", "autoschediastic, Ponderosa (ponderosa121)", "", Supernatural, 2010-01-28T00:00:00]

        # Page 2
        [work, "47938", "Figure It Out", lightgetsin, "", "White Collar", 2010-01-09T00:00:00+00:00]
        [work, "34591", "An Ever-Fixèd Mark", Vyola, "", "Modesty Blaise - O'Donnell", 2009-12-21T00:00:00+00:00]
        [work, "34961", "Complete Blank", rivkat, "", "Grosse Pointe Blank", 2009-12-21T00:00:00+00:00]
        [work, "31203", "Small Favors", orphan_account, "", "Girl Genius - Phil and Kaja Foglio", 2009-12-18T00:00:00+00:00]
        [work, "37677", "Killing Elvis", "David Hines (hradzka)", "", "Alien series (1979 1986 1992)", 2009-12-24T00:00:00+00:00]
        [work, "34036", "Start At The Edge", hariboo, "", "Aliens (1986)", 2009-12-21T00:00:00+00:00]
        [work, "3682", "Buildings and bridges (the rockabye remix)", Zooey_Glass, "", Supernatural, 2009-03-25T00:00:00+00:00]
        [work, "200", "A Maze of Twisty Passages, All Alike", "Mollyamory (Molly)", "", "Vorkosigan Saga", 2008-09-17T00:00:00+00:00]
    ]

    # ensure lack of pagination does not break things 
    let entries = bookmarks get -c $cli onlyonepage
    assert equal $entries [
        [type, id, name, author, series, fandoms, updated];
        [work, "6281467", "Taking Responsibility", Somewei, "Taking Responsibility Universe", "Powerpuff Girls", 2016-03-18T00:00:00+00:00]
        [work, "28631379", "internal travesties", thexanwillshine, "remember me when the stars align", "Shingeki no Kyojin | Attack on Titan", 2021-01-20T00:00:00+00:00]
    ]

    # ensure bookmarks can be lazy iterated
    let entries = bookmarks get -c $cli zvi | take 5
    assert length $entries 5
}
