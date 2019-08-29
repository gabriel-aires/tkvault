#!/usr/bin/tclsh8.6

#environment setup
package require sha1
package require sqlite3
package require blowfish
namespace import ::tcl::mathop::*
namespace import ::tcl::mathfunc::rand
namespace import ::tcl::mathfunc::round
set install_path [file dirname $argv0]
set operation [lindex $argv 0]
set object [lindex $argv 1]
set home_path $env(HOME)
set db_name .tkvault
set db_path [file join $home_path $db_name]
set max_size 256

#generate random passwords and initialization vector for cbc encryption
proc random_string {length} {
	binary scan " " c initial
	binary scan "~" c final
    set range [- $final $initial]
	set str {}

	for {set i 0} {$i < $length} {incr i} {
       	set char [+ $initial [round [* [rand] $range]]]
       	append str [binary format c $char]
	}
	
	return $str
}

proc retrieve_key {db max_size password} {
    set init_vector [db eval {SELECT init_vector FROM crypt;}]
    set padded_pw   [binary format A$max_size $password]
    return [::blowfish::Init cbc $padded_pw $init_vector]
}

proc release_key {key} {
    ::blowfish::Final $key
}

proc encrypt {key max_size plaintext} {
    return [::blowfish::Encrypt $key [binary format A$max_size $plaintext]]
}

proc decrypt {key ciphertext} {
    return [::blowfish::Decrypt $key $ciphertext]
}

#setup database and encryption
set first_access [! [file exists $db_path]]
sqlite3 db $db_path

if $first_access {
    set db_schema   [open [file join $install_path db.sql]]
    set db_sql      [read $db_schema]
    set init_vector [random_string $max_size]
    close $db_schema
    db transaction {
        db eval $db_sql
        db eval {INSERT INTO crypt VALUES($init_vector);}
    }
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
		puts "Vault created at '[clock format [clock seconds]]'."
    } elseif {$master_sha1 != [$db eval {SELECT master_sha1 FROM login;}]} {        
        puts "access denied."
        exit
    }
    
    return $master_pw
}

#manage credentials
proc count_credentials {db} {
    return [$db eval {SELECT COUNT(name) FROM credential;}]
}

proc output_credential {secret name identity password args} {
    set raw_name        [decrypt $secret $name]
    set raw_identity    [decrypt $secret $identity]
    set raw_password    [decrypt $secret $password]
    set mask_flag [== $args "-mask"]
    set passwd_out [expr {$mask_flag ? [::sha1::sha1 $raw_password] : $raw_password}]   
    puts ""
    puts "Name: $raw_name"
    puts "Identity: $raw_identity"
    puts "Password: $passwd_out"
}

proc show_credentials {db secret} {
    set credentials [$db eval {SELECT * FROM credential ORDER BY name;}]
    puts "Stored credentials: [count_credentials $db]"
    foreach {name identity password} $credentials {
        output_credential $secret $name $identity $password -mask
    }
}

proc upsert_credential {db secret max_size raw_name} {
    prompt "Enter identity:"
    gets stdin raw_id
    prompt "Enter password:"
    hide_input  [list gets stdin raw_passwd]
    set name    [encrypt $secret $max_size $raw_name]
    set id      [encrypt $secret $max_size $raw_id]
    set passwd  [encrypt $secret $max_size $raw_passwd]
    
    $db eval {
        INSERT INTO credential
            VALUES($name, $id, $passwd)
        ON CONFLICT(name)
        DO UPDATE SET
            identity = excluded.identity,
            password = excluded.password
        WHERE name = excluded.name;
    }
    
    show_credentials $db $secret
}

proc delete_credential {db secret max_size raw_name} {
    set name [encrypt $secret $max_size $raw_name]
    $db eval {DELETE FROM credential WHERE name = $name;}
    show_credentials $db $secret
}

proc reveal_credential {db secret max_size raw_name} {
    set name [encrypt $secret $max_size $raw_name]
    set details [$db eval {
        SELECT identity, password FROM credential WHERE name = $name;
    }]

    if {$details != ""} {
        lassign $details identity password
        output_credential $secret $name $identity $password
    } else {
        puts "Credential '$raw_name' not found."
    }
}

set master_password [login $first_access "db"]
set secret [retrieve_key "db" $max_size $master_password]
unset master_password

switch $operation {
    insert  -
    add     -
    update  -
    modify  {upsert_credential "db" $secret $max_size $object}
    delete  -
    remove  {delete_credential "db" $secret $max_size $object}
    reveal  {reveal_credential "db" $secret $max_size $object}
    list    -
    inspect {show_credentials "db" $secret}
    default {
        puts "usage: $argv0 <operation>"
        puts "operations available: list, insert|update|delete|reveal <item>"
    }
}

release_key $secret