#!/usr/bin/env tclsh8.6

#environment setup
namespace eval conf {
    set install_path [file dirname [file dirname $argv0]]
    set src_path [file join $install_path "src"]
    set lib_path [file join $install_path "lib"]
    set img_path [file join $install_path "img"]
    set home_path $env(HOME)
    set pkgs {arc0.1 black0.0.1 menubar0.5 twapi4.3.5 waldorf0.1}
    
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

package require sha1
package require sqlite3
package require blowfish
namespace import ::tcl::mathop::*
namespace import ::tcl::mathfunc::rand
namespace import ::tcl::mathfunc::round
source [file join $conf::src_path crypto.tcl]
source [file join $conf::src_path vault.tcl]
source [file join $conf::src_path state.tcl]
source [file join $conf::src_path window.tcl]
source [file join $conf::src_path gui.tcl]
source [file join $conf::src_path cli.tcl]
source [file join $conf::src_path controller.tcl]

#run application
set vault [Vault new $conf::db_path $conf::db_sql $conf::max_size]
set controller [Controller new $conf::command $conf::target $vault]

#clean up
$controller destroy
