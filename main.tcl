#!/usr/bin/tclsh8.6

#environment setup
set install_path [file dirname $argv0]
set operation [lindex $argv 0]
set object [lindex $argv 1]
set home_path $env(HOME)
set db_name .tkvault
set db_path [file join $home_path $db_name]
set max_size 256
package require sha1
package require sqlite3
package require blowfish
namespace import ::tcl::mathop::*
namespace import ::tcl::mathfunc::rand
namespace import ::tcl::mathfunc::round
source [file join $install_path crypto.tcl]

#setup database
set first_access [! [file exists $db_path]]
sqlite3 db $db_path

if $first_access {
    set db_schema   [open [file join $install_path db.sql]]
    set db_sql      [read $db_schema]
    close $db_schema
    db transaction {db eval $db_sql}
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
proc encrypt_plaintext {crypto index plaintext used_vector} {
	lassign [$crypto query_cache $index $plaintext] cache_found encrypt_data
	if [! $cache_found] {
		if {$used_vector != ""} {
			$crypto import_vector $used_vector	
		}
		set encrypt_data [$crypto encrypt $index $plaintext]
	}
	set ciphertext [lindex $encrypt_data 0]
	return $ciphertext
}

proc decrypt_ciphertext {crypto index ciphertext used_vector} {
	lassign [$crypto query_cache $index $ciphertext] cache_found decrypt_data
	if [! $cache_found] {
		$crypto import_vector $used_vector
		set decrypt_data [$crypto decrypt $index $ciphertext]
	}
	set plaintext [lindex $decrypt_data 0]
	return $plaintext
}

proc credential_index {db crypto raw_name} {
	set found false
	set index {}
	set records [$db eval {SELECT oid, name, name_key FROM credential;}]
	foreach {index name used_vector} $records {
		set testname [encrypt_plaintext $crypto $index $raw_name $used_vector]
		if {$name == $testname} {
			$crypto set_cache $index $name [list $raw_name $used_vector]
			$crypto set_cache $index $raw_name [list $name $used_vector]			
			set found true
			break
		}
	}
	return [list $found $index]
}

proc count_credentials {db} {
    return [$db eval {SELECT COUNT(name) FROM credential;}]
}

proc output_credential {crypto credential args} {
	lassign $credential index name name_key id id_key passwd passwd_key
	set items [list \
		"name" $name $name_key \
		"id" $id $id_key \
		"passwd" $passwd $passwd_key \
	]
	set raw_data {}
	foreach {type ciphertext used_vector} $items {
		set plaintext [decrypt_ciphertext $crypto $index $ciphertext $used_vector]
		dict set raw_data $type [string trimright $plaintext]
	}
    set raw_passwd [dict get $raw_data passwd]
	set passwd_digest [::sha1::sha1 $raw_passwd]
    set mask_flag [in $args "-mask"]
    puts ""
    puts "Name: [dict get $raw_data name]"
    puts "Identity: [dict get $raw_data id]"
    puts "Password: [expr {$mask_flag ? $passwd_digest : $raw_passwd}]"
}

proc show_credentials {db crypto} {
    set credentials [$db eval {
		SELECT oid
			, name
			, name_key
			, identity
			, identity_key
			, password
			, password_key
		FROM credential;
	}]
    puts "Stored credentials: [count_credentials $db]"
    foreach {index name name_key id id_key passwd passwd_key} $credentials {
		set credential [list $index $name $name_key $id $id_key $passwd $passwd_key]
        output_credential $crypto $credential -mask
    }
}

proc upsert_credential {db crypto raw_name} {
    prompt "Enter identity:"
    gets stdin raw_id
    prompt "Enter password:"
    hide_input  [list gets stdin raw_passwd]
	lassign [credential_index $db $crypto $raw_name] found index
	
	if $found {
		puts "Updating credential for '$raw_name'..."
		set encrypt_data [$db eval {
			SELECT name, name_key
			FROM credential
			WHERE oid = $index;
		}]
		lassign $encrypt_data name name_key
	} else {
		puts "Adding credential for '$raw_name'..."
		set name_key	[$crypto get_vector]
		set name    	[encrypt_plaintext $crypto {} $raw_name {}]
	}
	
	set id_key		[$crypto get_vector]
    set id      	[encrypt_plaintext $crypto {} $raw_id {}]
	set passwd_key	[$crypto get_vector]
    set passwd  	[encrypt_plaintext $crypto {} $raw_passwd {}]
    
    $db eval {
        INSERT INTO credential
            VALUES($name, $name_key, $id, $id_key, $passwd, $passwd_key)
        ON CONFLICT(name)
        DO UPDATE SET
			name_key 		= excluded.name_key,
            identity 		= excluded.identity,
			identity_key 	= excluded.identity_key,
            password 		= excluded.password,
			password_key	= excluded.password_key
        WHERE name = excluded.name;
    }
	
	set index [$db eval {SELECT oid FROM credential WHERE name = $name}]
	foreach {item raw_item item_key} [list \
		$name $raw_name $name_key \
		$id $raw_id $id_key \
		$passwd $raw_passwd $passwd_key \
	] {
		$crypto set_cache $index $item [list $raw_item $item_key]
		$crypto set_cache $index $raw_item [list $item $item_key]
	}

    show_credentials $db $crypto
}


proc delete_credential {db crypto raw_name} {
	lassign [credential_index $db $crypto $raw_name] found index
	if $found {
		$db eval {DELETE FROM credential WHERE oid = $index;}
		puts "Removed credential for '$raw_name'."
	} else {
		puts "No credential assigned to '$raw_name'."
	}
    
    show_credentials $db $crypto
}

proc reveal_credential {db crypto raw_name} {
	lassign [credential_index $db $crypto $raw_name] found index
	if $found {
		set credential [$db eval {
			SELECT oid
				, name
				, name_key
				, identity
				, identity_key
				, password
				, password_key
			FROM credential
			WHERE oid = $index;
		}]
		output_credential $crypto $credential
	} else {
		puts "Credential '$raw_name' not found."
    }
}

set master_password [login $first_access "db"]
set crypto [Crypto new $master_password $max_size]
unset master_password

switch $operation {
    insert  -
    add     -
    update  -
    modify  {upsert_credential "db" $crypto $object}
    delete  -
    remove  {delete_credential "db" $crypto $object}
    reveal  {reveal_credential "db" $crypto $object}
    list    -
    inspect {show_credentials "db" $crypto}
    default {
        puts "usage: $argv0 <operation>"
        puts "operations available: list, insert|update|delete|reveal <item>"
    }
}

$crypto destroy
db close