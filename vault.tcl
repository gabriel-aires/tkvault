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
    method open {master_pw state} {
        set master_sha1 [::sha1::sha1 $master_pw]
        set success true
        set msg {}
    
        if $FirstAccess {
            $Db eval { INSERT INTO login VALUES ($master_sha1); }
            set msg "Vault created at '[clock format [clock seconds]]'."
        } elseif {$master_sha1 != [$Db eval {SELECT master_sha1 FROM login;}]} {
            set msg "Access denied."
            set success false
        }
        
        if $success {
            set Crypto [Crypto new $master_pw $DataSize]
        }
        
        $state set Notice $msg
        return $success
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
    
    method output_credential {credential state args} {
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
        set name_out [dict get $raw_data name]
        set id_out [dict get $raw_data id]
        set passwd_out [expr {$mask_flag ? $passwd_digest : $raw_passwd}]
        $state append Output $name_out $id_out $passwd_out
    }
    
    method show_credentials {state} {
        set msg "Stored credentials: [my count_credentials]"
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
        foreach {index name name_key id id_key passwd passwd_key} $credentials {
            set credential [list $index $name $name_key $id $id_key $passwd $passwd_key]
            my output_credential $credential $state -mask
        }
        $state set Notice $msg
    }
    
    method upsert_credential {raw_name raw_id raw_passwd state} {
        lassign [my credential_index $raw_name] found index
        if $found {
            set msg "Updated credential for '$raw_name'..."
            set encrypt_data [$Db eval {
                SELECT name, name_key, name_time
                FROM credential
                WHERE oid = $index;
            }]
            lassign $encrypt_data name name_key name_time
        } else {
            set msg "Added credential for '$raw_name'..."
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
    
        $state set Notice $msg
        return $found
    }
    
    method delete_credential {raw_name state} {
        lassign [my credential_index $raw_name] found index
        if $found {
            $Db eval {DELETE FROM credential WHERE oid = $index;}
            set msg "Removed credential for '$raw_name'."
        } else {
            set msg "No credential assigned to '$raw_name'."
        }
        
        $state set Notice $msg
        return $found
    }
    
    method reveal_credential {raw_name state} {
        lassign [my credential_index $raw_name] found index
        set msg {}
        set output {}
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
            set output [my output_credential $credential $state]
        } else {
            set msg "Credential '$raw_name' not found."
        }
        
        $state set Output $output
        $state set Notice $msg
        return $found
    }
    
    destructor {
        if {$Crypto != ""} {
            $Crypto destroy    
        }
        $Db close
    }
}