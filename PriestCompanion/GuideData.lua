local addonName, ns = ...

-- Route text and percentage coordinates were supplied by the user. This is a
-- playable checklist draft, not a claim that the Classic route is verified on
-- every Forever build. No third-party quest database is copied into this file.
ns.GuideData = ns.GuideData or {}

local function point(x, y, label)
    return {areaID=85, zone="Tirisfal Glades", x=x/100, y=y/100,
        label=label, provenance="user", coordinateFrame="Tirisfal Glades"}
end

ns.GuideData.deathknell = {
    id="deathknell", title="Deathknell 1-6", zone="Tirisfal Glades", areaID=85,
    minLevel=1, maxLevel=6, faction="Horde", race="Scourge",
    revision=1, sourceStepCount=15,
    provenance="User-supplied route; class scroll corrected from inspected quest records.",
    verification="Route draft. Confirm current Forever quest offers and locations in game.",
    classScrolls={
        PRIEST={id=3097,name="Hallowed Scroll",trainer="Dark Cleric Duesten"},
        WARLOCK={id=3099,name="Tainted Scroll",trainer="Maximillion"},
    },
    steps={
        {id="dk01-exit",sourceStep=1,kind="goto",text="Run up the steps and leave the crypt.",manualOnly=true},
        {id="dk02-accept363",sourceStep=2,kind="accept",text="Accept Rude Awakening from Undertaker Mordo in front of the crypt.",questIDs={363}},
        {id="dk02-turnin363",sourceStep=2,kind="turnin",text="Run down the hill and turn in Rude Awakening to Shadow Priest Sarvis.",questIDs={363}},
        {id="dk03-accept364",sourceStep=3,kind="accept",text="Accept The Mindless Ones.",questIDs={364}},
        {id="dk03-class",sourceStep=3,kind="reminder",text="Check for your class's other starting quests as you pass the trainers.",manualOnly=true},
        {id="dk04-objective364",sourceStep=4,kind="objective",text="Leave the building and go down the hill to the left. Complete The Mindless Ones.",questIDs={364}},
        {id="dk04-turnin364",sourceStep=4,kind="turnin",text="Return to Shadow Priest Sarvis and turn in The Mindless Ones.",questIDs={364}},
        {id="dk05-accept3901",sourceStep=5,kind="accept",text="Accept Rattling the Rattlecages.",questIDs={3901}},
        {id="dk05-scroll",sourceStep=5,kind="accept",text="Accept {scroll} from Shadow Priest Sarvis.",classQuest=true},
        {id="dk05-accept376",sourceStep=5,kind="accept",text="Accept The Damned.",questIDs={376}},
        {id="dk06-scroll",sourceStep=6,kind="turnin",text="Read {scroll} and turn it in to {trainer}.",classQuest=true},
        {id="dk06-train",sourceStep=6,kind="train",text="Learn available spells from your class trainer. If you need coin, sell unwanted items across the road.",manualOnly=true},
        {id="dk07-objectives",sourceStep=7,kind="objective",text="Around the village, complete The Damned and Rattling the Rattlecages.",questIDs={376,3901}},
        {id="dk07-turnin",sourceStep=7,kind="turnin",text="Return and turn in The Damned and Rattling the Rattlecages.",questIDs={376,3901}},
        {id="dk07-accept6395",sourceStep=7,kind="accept",text="Accept Marla's Last Wish.",questIDs={6395}},
        {id="dk08-accept380",sourceStep=8,kind="accept",text="Outside the church, accept Night Web's Hollow.",questIDs={380}},
        {id="dk08-accept3902",sourceStep=8,kind="accept",text="Accept Scavenging Deathknell.",questIDs={3902}},
        {id="dk09-scavenge",sourceStep=9,kind="objective",text="Collect the Scavenging Deathknell supplies around and inside the village buildings.",questIDs={3902}},
        {id="dk09-fipps",sourceStep=9,kind="objective",text="Go to 36, 62 and kill Samuel Fipps for Marla's Last Wish. Loot the skull.",questIDs={6395},manualOnly=true,points={point(36,62,"Samuel Fipps")},note="Mark Done after looting. Whole-quest readiness cannot prove this individual action at the right time."},
        {id="dk10-cave",sourceStep=10,kind="goto",text="Go to Night Web's Hollow cave at 27, 59.",manualOnly=true,points={point(27,59,"Night Web's Hollow cave")}},
        {id="dk10-spiders",sourceStep=10,kind="objective",text="Complete Night Web's Hollow in the cave.",questIDs={380},points={point(27,59,"Night Web's Hollow")}},
        {id="dk10-grave",sourceStep=10,kind="interact",text="Return to the village cemetery at 31, 64 and click the grave to bury the skull.",questIDs={6395},manualOnly=true,points={point(31,64,"Marla's grave")},note="Mark Done after interacting with the grave."},
        {id="dk11-turnin",sourceStep=11,kind="turnin",text="Turn in Night Web's Hollow, Scavenging Deathknell and Marla's Last Wish in town.",questIDs={380,3902,6395}},
        {id="dk12-accept381",sourceStep=12,kind="accept",text="Outside the church, accept The Scarlet Crusade.",questIDs={381}},
        {id="dk12-scarlet",sourceStep=12,kind="objective",text="Go to 35, 68 and complete The Scarlet Crusade.",questIDs={381},points={point(35,68,"The Scarlet Crusade")}},
        {id="dk12-turnin381",sourceStep=12,kind="turnin",text="Return and turn in The Scarlet Crusade.",questIDs={381}},
        {id="dk13-accept382",sourceStep=13,kind="accept",text="Accept The Red Messenger.",questIDs={382}},
        {id="dk13-messenger",sourceStep=13,kind="objective",text="Go to 36, 68 and kill Meven Korgal for The Red Messenger.",questIDs={382},points={point(36,68,"Meven Korgal")}},
        {id="dk13-turnin382",sourceStep=13,kind="turnin",text="Return and turn in The Red Messenger.",questIDs={382}},
        {id="dk14-accept383",sourceStep=14,kind="accept",text="Accept Vital Intelligence.",questIDs={383}},
        {id="dk14-train",sourceStep=14,kind="train",text="Reach level 6 if needed, then visit your class trainer for available spells.",manualOnly=true},
        {id="dk15-accept8",sourceStep=15,kind="accept",text="North of Deathknell, check the current offer and accept A Rogue's Deal.",questIDs={8},note="The supplied route names quest 8. Confirm the offered ID on Forever; this draft does not substitute an unverified replacement."},
        {id="dk15-leave",sourceStep=15,kind="goto",text="Leave the starting area and continue toward the next part of your leveling route.",manualOnly=true},
    },
}
