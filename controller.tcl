oo::class create Controller {
    variable Operation Mode Vault Ui Target

    constructor {cmd tgt vault} {
        set Target $tgt
        set Vault $vault
        set Mode "CLI"
        set Operation {}

        switch $cmd {
            insert  -
            add     {set Operation "add_credential"}
            update  -
            modify  {set Operation "update_credential"}
            delete  -
            remove  {set Operation "delete_credential"}
            reveal  {set Operation "reveal_credential"}
            list    -
            inspect {set Operation "show_credentials"}
            help    -
            --help  -
            -h      {set Operation "help"}
            default {set Mode "GUI"}
        }

        if {$Mode == "CLI"} {
            set Ui [Cli new]
        } else {
            #load tk gui
        }

        if {$Operation == "help"} {
            my dispatch "help"
        } else {
            my dispatch "open_vault"
        }
    }

    method dispatch {method} {
        my "${Mode}_${method}"
    }

    method CLI_open_vault {} {
        set state [$Ui get_state]
        $Ui prompt "Enter vault password:"
        $Ui hide_input [list gets stdin master_pw]
        set success [$Vault open $master_pw $state]
        $Ui info
        if $success {
            my dispatch $Operation
        }
    }

    method CLI_add_credential {} {
        if [! [$Vault credential_exists $Target]] {
            my CLI_upsert_credential
        } else {
            puts "A credential already exists for '$Target'. Did you mean 'update'?"
        }
    }

    method CLI_update_credential {} {
        if [$Vault credential_exists $Target] {
            my CLI_upsert_credential
        } else {
            puts "Credential for '$Target' not found. Did you mean 'add'?"
        }
    }

    method CLI_upsert_credential {} {
        $Ui prompt "Enter identity:"
        gets stdin raw_id
        $Ui prompt "Enter password:"
        $Ui hide_input [list gets stdin raw_passwd]
        $Vault $Operation $Target $raw_id $raw_passwd [$Ui get_state]
        $Ui info
    }

    method CLI_delete_credential {} {
        if [$Vault credential_exists $Target] {
            $Vault $Operation $Target [$Ui get_state]
            $Ui info
        } else {
            puts "Credential for '$Target' not found."
        }
    }

    method CLI_reveal_credential {} {
        if [$Vault credential_exists $Target] {
            set state [$Ui get_state]
            $Vault $Operation $Target $state
            set credential [$state get Output]
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

    method CLI_show_credentials {} {
        set state [$Ui get_state]
        $Vault $Operation $state
        $Ui info
        set credentials [$state get Output]
        foreach {name id passwd_hash} $credentials {
            puts ""
            puts "Name: $name"
            puts "Identity: $id"
            puts "Password: $passwd_hash"
        }
    }

    method CLI_help {} {
        puts "options: list|insert|update|delete|reveal <item>"
    }

    destructor {
        $Vault destroy
    }
}
