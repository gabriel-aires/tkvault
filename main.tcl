#!/usr/bin/tclsh8.6

#environment setup
set install_path [file dirname $argv0]
set command [lindex $argv 0]
set target [lindex $argv 1]
set home_path $env(HOME)
set db_name .tkvault
set db_path [file join $home_path $db_name]
set db_sql [file join $install_path db.sql]
set max_size 256
package require sha1
package require sqlite3
package require blowfish
namespace import ::tcl::mathop::*
namespace import ::tcl::mathfunc::rand
namespace import ::tcl::mathfunc::round
source [file join $install_path crypto.tcl]
source [file join $install_path vault.tcl]
source [file join $install_path state.tcl]
source [file join $install_path cli.tcl]
source [file join $install_path controller.tcl]

#run application
set vault [Vault new $db_path $db_sql $max_size]
set controller [Controller new $command $target $vault]

#clean up
$controller destroy