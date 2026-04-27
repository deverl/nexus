
font create myTitleFont -family Helvetica -size 12 -weight bold
font create myDefaultFont -family Helvetica -size 10
option add *font myDefaultFont
option add *background white

set logFile "/home/dstokes/tmp/download_unity.log"
set theTitle "Unity Download Results"

if { $argc > 0 } {
    set logFile [lindex $argv 0]
    if { $argc > 1 } {
        set theTitle [lindex $argv 1]
    }
}

set infile [open $logFile r]
set msg [read $infile]
close $infile

set isError [string match -nocase *error* $msg ]

frame .top -background white
label .top.title -text $theTitle -background white -font myTitleFont
# label .top.title -text $theTitle -background white -font {-family Helvetica -size 12 -weight bold}

frame .middle
# label .middle.msg -text $msg -width 90 -background white -justify left
# text .middle.t -yscrollcommand ".middle.vscroll set" -width 85 -height 15 -background white
text .middle.t -yscrollcommand {.middle.vscroll set} -xscrollcommand {.middle.hscroll set} -width 85 -height 16 -background white
scrollbar .middle.vscroll -orient vertical -command {.middle.t yview}
scrollbar .middle.hscroll -orient horizontal -command {.middle.t xview}

.middle.t insert end $msg

if { $isError } {
    .middle.t configure -foreground red
}

.middle.t configure -state disabled

frame .bottom -background white
button .bottom.ok_btn -text "OK" -width 15 -background gray -command {destroy .}
# button .bottom.ok_btn -text "OK" -width 15 -command {destroy .}

pack .top.title -pady 10
pack .top -fill x

# pack .middle.msg -ipadx 10
pack .middle.vscroll -side right -fill y
pack .middle.hscroll -side bottom -fill x
# pack .middle.hscroll -fill x
pack .middle.t -ipadx 10 -fill x -fill y -expand 1
pack .middle -fill x -fill y -expand 1

pack .bottom.ok_btn -pady 10
pack .bottom -fill x

# bind .bottom.ok_btn <Button-1> { exit 0 }

