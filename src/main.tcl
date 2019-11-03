#!/usr/bin/env tclsh8.6

#setup environment
namespace eval conf {
    set home_path $env(HOME)
    set install_path [file dirname [file dirname $argv0]]
    set src_path [file join $install_path "src"]
    set lib_path [file join $install_path "lib"]
    set img_path [file join $install_path "img"]
    set class_path [file join $src_path "class"]
    
    set classes {
        crypto
        vault
        state
        colors
        window
        sframe
        cframe
        controls
        folder
        gui
        cli
        controller
    }
    
    set pkgs {
        menubar0.5
        twapi4.3.5
        breeze0.6
    }
    
    foreach pkg_name $pkgs {
        lappend ::auto_path [file join $lib_path $pkg_name]
    }
    
    set command [lindex $argv 0]
    set target [lindex $argv 1]
    set db_name .tkvault
    set db_path [file join $home_path $db_name]
    set db_sql [file join $src_path db.sql]
    set max_size 256
}

#load common dependencies
package require sha1
package require sqlite3
package require blowfish
namespace import ::tcl::mathop::*
namespace import ::tcl::mathfunc::rand
namespace import ::tcl::mathfunc::round
namespace import ::tcl::mathfunc::floor
namespace import ::tcl::mathfunc::ceil
namespace import ::tcl::mathfunc::double
namespace import ::tcl::mathfunc::int
namespace import ::tcl::mathfunc::sqrt

#load conditional dependencies
if {$::tcl_platform(platform) == "windows"} {
    package require twapi
}

if {$conf::command == {}} {
    package require Tk
    package require menubar
    package require ttk::theme::Breeze
}

#source classes
foreach class $conf::classes {
    source [file join $conf::class_path "$class.tcl"]
}

#initialize vault and controller
set vault [Vault new $conf::db_path $conf::db_sql $conf::max_size]
set controller [Controller new $conf::command $conf::target $vault]
