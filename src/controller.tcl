oo::class create Controller {
    variable Operation Mode Vault Ui Target Logo

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
            set Ui [Cli new $Vault $Operation $Target [self]]
        } else {
            set Ui [Gui new $Vault $Operation $Target [self]]
        }

        if {$Operation == "help"} {
            $Ui help
        } else {
            $Ui open_vault
        }
    }

    destructor {
        $Ui destroy
        $Vault destroy
    }
}
