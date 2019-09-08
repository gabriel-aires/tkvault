oo::class create Vault {
    variable FirstAccess Db DbPath DbSql Crypto DataSize

    constructor {db_path db_sql data_size} {
        set Db {}
        set DbPath $db_path
        set DbSql $db_sql
        set FirstAccess [! [file exists $DbPath]]
        set Crypto {}
        set DataSize $data_size
    }

    #authentication / database setup
    method open {master_pw state} {
        set master_sha1 [::sha1::sha1 $master_pw]
        set success true
        set msg {}
        set Db "db"
        sqlite3 $Db $DbPath

        if $FirstAccess {
            set db_schema   [open $DbSql]
            set db_create   [read $db_schema]
            close $db_schema
            $Db transaction {
                $Db eval $db_create
                $Db eval { INSERT INTO login VALUES ($master_sha1); }
            }            
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
        set index {}
        set records [$Db eval {SELECT oid, name, name_key FROM credential;}]
        foreach {oid name used_vector} $records {
            set testname [$Crypto get_ciphertext $oid $raw_name $used_vector]
            if {$name == $testname} {
                set index $oid
                break
            }
        }
        return $index
    }

    method credential_exists {raw_name} {
        set index [my credential_index $raw_name]
        set exists [expr {$index != "" ? true : false}]
        return $exists
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
        $state set Notice "Stored credentials: [my count_credentials]"
    }

    method add_credential {raw_name raw_id raw_passwd state} {
        set name_key   [$Crypto get_vector]
        set name       [$Crypto get_ciphertext {} $raw_name {}]
        set name_time  [clock milliseconds]
        
        lassign [my Set_credential_details $raw_id $raw_passwd] \
            id \
            id_key \
            id_time \
            passwd \
            passwd_key \
            passwd_time
        
        $Db eval {
            INSERT INTO credential
            VALUES(
                $name
                , $name_key
                , $name_time
                , $id
                , $id_key
                , $id_time
                , $passwd
                , $passwd_key
                , $passwd_time
            )
        }
        
        my Update_cache $raw_name $raw_id $raw_passwd [list \
            $name \
            $name_key \
            $name_time \
            $id \
            $id_key \
            $id_time \
            $passwd \
            $passwd_key \
            $passwd_time \
        ]
        
        $state set Notice "Added credential for '$raw_name'."
    }

    method update_credential {raw_name raw_id raw_passwd state} {
        set index [my credential_index $raw_name]
        lassign [$Db eval {
            SELECT name, name_key, name_time
            FROM credential
            WHERE oid = $index;
        }] name name_key name_time
        
        lassign [my Set_credential_details $raw_id $raw_passwd] \
            id \
            id_key \
            id_time \
            passwd \
            passwd_key \
            passwd_time
        
        $Db eval {
            UPDATE credential
            SET
                name_key = $name_key
                , name_time = $name_time
                , identity = $id
                , identity_key = $id_key
                , identity_time = $id_time
                , password = $passwd
                , password_key = $passwd_key
                , password_time = $passwd_time
            WHERE NAME = $name;
        }
        
        my Update_cache $raw_name $raw_id $raw_passwd [list \
            $name \
            $name_key \
            $name_time \
            $id \
            $id_key \
            $id_time \
            $passwd \
            $passwd_key \
            $passwd_time \
        ]
        
        $state set Notice "Updated credential for '$raw_name'."
    }

    method Set_credential_details {raw_id raw_passwd} {
        set id_key      [$Crypto get_vector]
        set id          [$Crypto get_ciphertext {} $raw_id {}]
        set id_time     [clock milliseconds]
        set passwd_key	[$Crypto get_vector]
        set passwd  	[$Crypto get_ciphertext {} $raw_passwd {}]
        set passwd_time [clock milliseconds]
        return [list $id $id_key $id_time $passwd $passwd_key $passwd_time]
    }

    method Update_cache {raw_name raw_id raw_passwd credential} {
        lassign $credential \
            name \
            name_key \
            name_time \
            id \
            id_key \
            id_time \
            passwd \
            passwd_key \
            passwd_time

        set index [$Db eval {SELECT oid FROM credential WHERE name = $name}]
        
        foreach {item raw_item item_key} [list \
            $name $raw_name $name_key \
            $id $raw_id $id_key \
            $passwd $raw_passwd $passwd_key \
        ] {
            $Crypto set_cache $index $item [list $raw_item $item_key]
            $Crypto set_cache $index $raw_item [list $item $item_key]
        }
    }

    method delete_credential {raw_name state} {
        set index [my credential_index $raw_name]
        $Db eval {DELETE FROM credential WHERE oid = $index;}
        $state set Notice "Removed credential for '$raw_name'."
    }

    method reveal_credential {raw_name state} {
        set index [my credential_index $raw_name]
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
        my output_credential $credential $state
    }

    destructor {
        if {$Crypto != ""} {
            $Crypto destroy
        }
        if {$Db != ""} {
            $Db close         
        }
    }
}
