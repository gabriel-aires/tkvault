#!/usr/bin/tclsh8.6

#environment setup
namespace import ::tcl::mathop::*
set install_path [file dirname $argv0]
set home_path $env(HOME)
set db_name .tkvault
set db_path [file join $home_path $db_name]

#hide password input
proc hide_input {prompt script} {
    puts -nonewline $prompt
    flush stdout
    catch {exec stty -echo}
    uplevel 1 $script
    catch {exec stty echo}
}

hide_input "Enter vault password: " {
    set master_pw [gets stdin]
}

#fake authentication
if {$master_pw != "okay"} {
    puts denied
    exit
} else {
    puts "\n----------------"
}

#fake credentials
dict set credentials email  {test@test.com          jkasdjf9i34}
dict set credentials bank   {0000-0000-0000-0000    000000}
dict set credentials work   {admin                  dsaj9f02kjndkf2}
dict set credentials home   {user                   9dsad3}

proc count_credentials {credentials} {
    return [dict size $credentials]
}

proc show_credentials {credentials} {
    foreach {name credential} $credentials {
        lassign $credential identity password
        puts ""
        puts "Name: $name"
        puts "Identity: $identity"
        puts "Password: $password"
    }
}

#display stored credentials
puts "Stored credentials: [count_credentials $credentials]"
show_credentials $credentials