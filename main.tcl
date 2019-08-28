#!/usr/bin/tclsh8.6

#environment setup
set install_path [file dirname $argv0]
set home_path $env(HOME)
set db_name .tkvault
set db_path [file join $home_path $db_name]

#hide password input
proc hide_input {prompt script} {
    puts -nonewline $prompt
    flush stdout
    exec stty -echo
    uplevel 1 $script
    exec stty echo
}

hide_input "Enter vault password: " {
    set master_pw [gets stdin]
}

#fake authentication
if {$master_pw == "okay"} {
    puts $master_pw    
} else {
    puts denied
}
