oo::class create Cli {
    variable State Vault Operation Target Controller
    
    constructor {vault operation target controller} {
        set State [State new]
        set Vault $vault
        set Operation $operation
        set Target $target
        set Controller $controller
    }
    
    method hide_input {script} {
        catch {exec stty -echo}
        uplevel 1 $script
        catch {exec stty echo}
        puts ""
    }
    
    method prompt {message} {
        puts -nonewline "$message "
        flush stdout
    }
    
    method info {} {
        set notice [$State get Notice]
        if {$notice != ""} {
            puts $notice            
        }
    }
    
    method open_vault {} {
        my prompt "Enter vault password:"
        my hide_input [list gets stdin master_pw]
        set success [$Vault open $master_pw $State]
        my info
        if $success {
            my $Operation
        }
    }


    method add_credential {} {
        if [! [$Vault credential_exists $Target]] {
            my upsert_credential
        } else {
            puts "A credential already exists for '$Target'. Did you mean 'update'?"
        }
    }

    method update_credential {} {
        if [$Vault credential_exists $Target] {
            my upsert_credential
        } else {
            puts "Credential for '$Target' not found. Did you mean 'add'?"
        }
    }

    method upsert_credential {} {
        my prompt "Enter identity:"
        gets stdin raw_id
        my prompt "Enter password:"
        my hide_input [list gets stdin raw_passwd]
        $Vault $Operation $Target $raw_id $raw_passwd $State
        my info
    }

    method delete_credential {} {
        if [$Vault credential_exists $Target] {
            $Vault $Operation $Target $State
            my info
        } else {
            puts "Credential for '$Target' not found."
        }
    }

    method reveal_credential {} {
        if [$Vault credential_exists $Target] {
            $Vault $Operation $Target $State
            set credential [$State get Output]
            if {$credential != ""} {
                lassign $credential name id passwd
                puts "Name: $name"
                puts "Identity: $id"
                puts "Password: $passwd"
            }
        } else {
            puts "Credential for '$Target' not found."
        }
    }

    method show_credentials {} {
        $Vault $Operation $State
        my info
        set credentials [$State get Output]
        foreach {name id passwd_hash} $credentials {
            puts ""
            puts "Name: $name"
            puts "Identity: $id"
            puts "Password: $passwd_hash"
        }
    }

    method help {} {
        puts "options: list|insert|update|delete|reveal <item>"
    }
}