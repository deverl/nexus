

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
} else {
    puts "ERROR: You must at least specify a file to display!"
    exit 0
}

set infile [open $logFile r]
set msg [read $infile]
close $infile

set isError [string match -nocase *error* $msg ]

frame .top -background white
label .top.title -text $theTitle -background white -font myTitleFont

frame .middle
# label .middle.msg -text $msg -width 90 -background white -justify left
text .middle.t -yscrollcommand ".middle.scroll set" -width 90 -height 18 -background white
scrollbar .middle.scroll -command ".middle.t yview"

.middle.t insert end $msg

if { $isError } {
    .middle.t configure -foreground red
}

.middle.t configure -state disabled

frame .bottom -background white
button .bottom.ok_btn -text "OK" -width 15

pack .top.title -pady 10
pack .top -fill x

# pack .middle.msg -ipadx 10
pack .middle.scroll -side right -fill y
pack .middle.t -ipadx 10
pack .middle

pack .bottom.ok_btn -pady 10
pack .bottom -fill x

bind .bottom.ok_btn <Button-1> { exit 0 }

