oo::class create Vault {
    variable FirstAccess Db DbPath DbSchema Crypto DataSize

    constructor {db_path db_sql data_size} {
        set Db "db"
        set DbPath $db_path
        set DbSql $db_sql
        set FirstAccess [! [file exists $DbPath]]
        set Crypto {}
        set DataSize $data_size
        sqlite3 db $DbPath
        
        if $FirstAccess {
            set db_schema   [open $DbSql]
            set db_create   [read $db_schema]
            close $db_schema
            db transaction {db eval $db_create}
        }
    }
     
    #authentication
    method open {} {
        my prompt "Enter vault password:"
        my hide_input [list gets stdin master_pw]
        set master_sha1 [::sha1::sha1 $master_pw]
    
        if $FirstAccess {
            $Db eval { INSERT INTO login VALUES ($master_sha1); }
            puts "Vault created at '[clock format [clock seconds]]'."
        } elseif {$master_sha1 != [$Db eval {SELECT master_sha1 FROM login;}]} {
            puts "access denied."
            exit
        }
        
        set Crypto [Crypto new $master_pw $DataSize]
    }    
    
    #hide password input
    method hide_input {script} {
        catch {exec stty -echo}
        uplevel 1 $script
        catch {exec stty echo}
        puts "\n"
    }
    
    method prompt {message} {
        puts -nonewline "$message "
        flush stdout
    }
    
    #manage credentials
    method credential_index {raw_name} {
        set found false
        set index {}
        set records [$Db eval {SELECT oid, name, name_key FROM credential;}]
        foreach {index name used_vector} $records {
            set testname [$Crypto get_ciphertext $index $raw_name $used_vector]
            if {$name == $testname} {
                set found true
                break
            }
        }
        return [list $found $index]
    }
    
    method count_credentials {} {
        return [$Db eval {SELECT COUNT(name) FROM credential;}]
    }
    
    method output_credential {credential args} {
        lassign $credential index name name_key id id_key passwd passwd_key
        set items [list \
            "name" $name $name_key \
            "id" $id $id_key \
            "passwd" $passwd $passwd_key \
        ]
        set raw_data {}
        foreach {type ciphertext used_vector} $items {
            set plaintext [$Crypto get_plaintext $index $ciphertext $used_vector]
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
    
    method show_credentials {} {
        set credentials [$Db eval {
            SELECT oid
                , name
                , name_key
                , identity
                , identity_key
                , password
                , password_key
            FROM credential;
        }]
        puts "Stored credentials: [my count_credentials]"
        foreach {index name name_key id id_key passwd passwd_key} $credentials {
            set credential [list $index $name $name_key $id $id_key $passwd $passwd_key]
            my output_credential $credential -mask
        }
    }
    
    method upsert_credential {raw_name} {
        my prompt "Enter identity:"
        gets stdin raw_id
        my prompt "Enter password:"
        my hide_input  [list gets stdin raw_passwd]
        lassign [my credential_index $raw_name] found index
        
        if $found {
            puts "Updating credential for '$raw_name'..."
            set encrypt_data [$Db eval {
                SELECT name, name_key, name_time
                FROM credential
                WHERE oid = $index;
            }]
            lassign $encrypt_data name name_key name_time
        } else {
            puts "Adding credential for '$raw_name'..."
            set name_key	[$Crypto get_vector]
            set name    	[$Crypto get_ciphertext {} $raw_name {}]
            set name_time   [clock milliseconds]
        }
        
        set id_key		[$Crypto get_vector]
        set id      	[$Crypto get_ciphertext {} $raw_id {}]
        set id_time     [clock milliseconds]
        set passwd_key	[$Crypto get_vector]
        set passwd  	[$Crypto get_ciphertext {} $raw_passwd {}]
        set passwd_time [clock milliseconds]
        
        $Db eval {
            INSERT INTO credential
                VALUES($name, $name_key, $name_time, $id, $id_key, $id_time, $passwd, $passwd_key, $passwd_time)
            ON CONFLICT(name)
            DO UPDATE SET
                name_key 		= excluded.name_key,
                name_time       = excluded.name_time,
                identity 		= excluded.identity,
                identity_key 	= excluded.identity_key,
                identity_time   = excluded.identity_time,
                password 		= excluded.password,
                password_key	= excluded.password_key,
                password_time   = excluded.password_time
            WHERE name = excluded.name;
        }
        
        set index [$Db eval {SELECT oid FROM credential WHERE name = $name}]
        foreach {item raw_item item_key} [list \
            $name $raw_name $name_key \
            $id $raw_id $id_key \
            $passwd $raw_passwd $passwd_key \
        ] {
            $Crypto set_cache $index $item [list $raw_item $item_key]
            $Crypto set_cache $index $raw_item [list $item $item_key]
        }
    
        my show_credentials
    }
    
    method delete_credential {raw_name} {
        lassign [my credential_index $raw_name] found index
        if $found {
            $Db eval {DELETE FROM credential WHERE oid = $index;}
            puts "Removed credential for '$raw_name'."
        } else {
            puts "No credential assigned to '$raw_name'."
        }
        
        my show_credentials
    }
    
    method reveal_credential {raw_name} {
        lassign [my credential_index $raw_name] found index
        if $found {
            set credential [$Db eval {
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
            my output_credential $credential
        } else {
            puts "Credential '$raw_name' not found."
        }
    }
    
    destructor {
        $Crypto destroy
        $Db close
    }
}