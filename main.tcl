#!/usr/bin/tclsh8.6

#environment setup
set install_path [file dirname $argv0]
set operation [lindex $argv 0]
set object [lindex $argv 1]
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

#vault setup
set vault [Vault new $db_path $db_sql $max_size]
$vault open

#cli interface
switch $operation {
    insert  -
    add     -
    update  -
    modify  {$vault upsert_credential $object}
    delete  -
    remove  {$vault delete_credential $object}
    reveal  {$vault reveal_credential $object}
    list    -
    inspect {$vault show_credentials}
    default {
        puts "usage: $argv0 <operation>"
        puts "operations available: list, insert|update|delete|reveal <item>"
    }
}

$vault destroy