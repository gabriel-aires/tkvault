#!/usr/bin/tclsh8.6

#environment setup
package require sha1
package require sqlite3
namespace import ::tcl::mathop::*
set install_path [file dirname $argv0]
set operation [lindex $argv 0]
set object [lindex $argv 1]
set home_path $env(HOME)
set db_name .tkvault
set db_path [file join $home_path $db_name]

#setup database
set first_access [! [file exists $db_path]]
sqlite3 db $db_path

if $first_access {
    set db_schema [open [file join $install_path db.sql]]
    set db_sql    [read $db_schema]
    close $db_schema
    db transaction [list db eval $db_sql]
}

#hide password input
proc hide_input {script} {
    catch {exec stty -echo}
    uplevel 1 $script
    catch {exec stty echo}
    puts "\n"
}

proc prompt {message} {
    puts -nonewline "$message "
    flush stdout
}

#authentication
proc login {first_access db} {
    prompt "Enter vault password:"
    hide_input [list gets stdin master_pw]
    set master_sha1 [::sha1::sha1 $master_pw]

    if $first_access {
        $db eval { INSERT INTO login VALUES ($master_sha1); }        
    } elseif {$master_sha1 != [$db eval {SELECT master_sha1 FROM login;}]} {        
        puts "access denied."
        exit
    }
}

#manage credentials
proc count_credentials {db} {
    return [$db eval {SELECT COUNT(name) FROM credential;}]
}

proc output_credential {name identity password args} {
    set mask_flag [== $args "-mask"]
    set passwd_out [expr {$mask_flag ? [::sha1::sha1 $password] : $password}]   
    puts ""
    puts "Name: $name"
    puts "Identity: $identity"
    puts "Password: $passwd_out"
}

proc show_credentials {db} {
    set credentials [$db eval {SELECT * FROM credential ORDER BY name;}]
    puts "Stored credentials: [count_credentials $db]"
    foreach {name identity password} $credentials {
        output_credential $name $identity $password -mask
    }
}

proc upsert_credential {db name} {
    prompt "Enter identity:"
    gets stdin id
    prompt "Enter password:"
    hide_input [list gets stdin passwd]
    
    $db eval {
        INSERT INTO credential
            VALUES($name, $id, $passwd)
        ON CONFLICT(name)
        DO UPDATE SET
            identity = excluded.identity,
            password = excluded.password
        WHERE name = excluded.name;
    }
    
    show_credentials $db
}

proc delete_credential {db name} {
    $db eval {DELETE FROM credential WHERE name = $name;}
    show_credentials $db
}

proc reveal_credential {db name} {
    set details [$db eval {
        SELECT identity, password FROM credential WHERE name = $name;
    }]
        
    if {$details != ""} {
        lassign $details identity password
        output_credential $name $identity $password
    } else {
        puts "Credential '$name' not found."
    }
}

login $first_access "db"

switch $operation {
    insert  -
    add     -
    update  -
    modify  {upsert_credential "db" $object}
    delete  -
    remove  {delete_credential "db" $object}
    reveal  {reveal_credential "db" $object}
    list    -
    inspect {show_credentials "db"}
    default {
        puts "usage: $argv0 <operation>"
        puts "operations available: list, insert|update|delete|reveal <item>"
    }
}