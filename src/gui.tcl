oo::class create Gui {
    variable Root Vault Operation Target Logo
    
    constructor {vault operation target} {
        package require Tk
        package require ttk::theme::Arc
        package require ttk::theme::black
        package require ttk::theme::waldorf
        package require menubar
        set Vault $vault
        set Operation $operation
        set Target $target
        set Logo [image create photo -file [file join $::conf::img_path "logo.png"]]        
        set Root [Window new "."]
        if {$::tcl_platform(os) == "Linux"} {
            ::ttk::style theme use waldorf
        }
    }
    
    method check_passwd {state auth_container help} {
        set master_pw [$state get Input]
        set success [$Vault open $master_pw $state]
        if $success {
            $help configure -foreground #2bdb64
            after 1000 "destroy $auth_container; $state destroy; [self] destroy"
        } else {
            $help configure -foreground #c3063c
        }
    }
    
    method open_vault {} {
        $Root title "ThunderVault"
        
        set state [State new]
        set container [::ttk::labelframe .auth]
        set left [::ttk::frame .auth.logo]
        set logo [::ttk::label .auth.logo.img]
        set right [::ttk::frame .auth.form]
        set prompt [::ttk::label .auth.form.passwd_label]
        set input [::ttk::entry .auth.form.passwd_entry]
        set submit [::ttk::button .auth.form.submit]
        set help [::ttk::label .auth.form.help]
        
        $container configure -text "Authentication"
        $logo configure -image $Logo
        $prompt configure -text "Enter Master Password"
        $input configure -show * -textvariable [$state var Input] -takefocus 1 -width 30
        $submit configure -text "Unlock" -command "[self] check_passwd $state $container $help"
        $help configure -textvariable [$state var Notice]
        
        pack $container -expand 1 -fill both -pady 2p -padx 2p
        grid $left $right -sticky ew -pady 4p -ipady 4p -padx 4p -ipadx 4p
        pack $logo
        pack $prompt -pady 3p
        pack $input -pady 3p
        pack $submit -pady 3p
        pack $help -pady 3p
        $Root focus
    }
}