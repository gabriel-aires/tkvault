oo::class create Controller {
    variable Operation Mode Vault Ui
    
    constructor {cmd tgt vault} {
        set Vault $vault
        set Mode "cli"
        set Operation {}
        
        switch $cmd {
            insert  -
            add     {set Operation [list add_credential $tgt]}
            update  -
            modify  {set Operation [list update_credential $tgt]}
            delete  -
            remove  {set Operation [list delete_credential $tgt]}
            reveal  {set Operation [list reveal_credential $tgt]}
            list    -
            inspect {set Operation "show_credentials"}
            help    -
            --help  -
            -h      {set Operation "help"}
            default {set Mode "gui"}
        }
        
        if {$Mode == "cli"} {
            set Ui [Cli new]
        } else {
            #load tk gui
        }
        
        if {$Operation == "help"} {
            my help
        } else {
            my open_vault
        }
    }
    
    method open_vault {} {
        if {$Mode == "cli"} {
            set state [$Ui get_state]
            $Ui prompt "Enter vault password:"
            $Ui hide_input [list gets stdin master_pw]
            set success [$Vault open $master_pw $state]
            $Ui info
            if $success {
                set cmd [lindex $Operation 0]
                my $cmd
            }            
        } else {
            #load tk gui
        }
    }
   
    method add_credential {} {
	my Upsert_credential
    }

    method update_credential {} {
	my Upsert_credential
    }
    
    method Upsert_credential {} {
        if {$Mode == "cli"} {
            set state [$Ui get_state]
            $Ui prompt "Enter identity:"
            gets stdin raw_id
            $Ui prompt "Enter password:"
            $Ui hide_input [list gets stdin raw_passwd]
            lappend Operation $raw_id $raw_passwd $state
            $Vault {*}$Operation
            $Ui info
        } else {
            #load tk gui
        }
    }
    
    method delete_credential {} {
        if {$Mode == "cli"} {
            set state [$Ui get_state]
            lappend Operation $state
            $Vault {*}$Operation
            $Ui info
        } else {
            #load tk gui
        }
    }
    
    method reveal_credential {} {
        if {$Mode == "cli"} {
            set state [$Ui get_state]
            lappend Operation $state
            $Vault {*}$Operation
            $Ui info
            set credential [$state get Output]
            if {$credential != ""} {
            lassign $credential name id passwd
                puts "Name: $name"
                puts "Identity: $id"
                puts "Password: $passwd"
            }
        } else {
            #load tk gui
        }
    }
    
    method show_credentials {} {
        if {$Mode == "cli"} {
            set state [$Ui get_state]
            lappend Operation $state
            $Vault {*}$Operation
            $Ui info
            set credentials [$state get Output]
            foreach {name id passwd_hash} $credentials {
                puts ""
                puts "Name: $name"
                puts "Identity: $id"
                puts "Password: $passwd_hash"
            }
        } else {
            #load tk gui
        }
    }
    
    method help {} {
        puts "options: list|insert|update|delete|reveal <item>"
    }
    
    destructor {
        $Vault destroy
    }
}
