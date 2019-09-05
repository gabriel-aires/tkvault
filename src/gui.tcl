oo::class create Gui {
    variable Root Vault Operation Target Logo Controller Theme
    
    constructor {vault operation target controller} {
        package require Tk
        package require ttk::theme::Arc
        package require ttk::theme::black
        package require ttk::theme::waldorf
        package require menubar
        set Vault $vault
        set Operation $operation
        set Target $target
        set Controller $controller
        set Theme [expr {$::tcl_platform(os) == "Linux" ? "waldorf" : "default"}]
        set Logo [image create photo -file [file join $::conf::img_path "logo.png"]]        
        set Root [Window new "."]
        my update_theme
    }
    
    method bind_method {origin event method} {
		bind $origin $event "if {{%W} eq {$origin}} {[self] $method}"
	}
    
    method check_passwd {state auth_container help} {
        set master_pw [$state get Input]
        set success [$Vault open $master_pw $state]
        if $success {
            $help configure -foreground #2bdb64
            after 1000 "destroy $auth_container; $state destroy; [self] main"
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
        $help configure -textvariable [$state var Notice]
        $submit configure -text "Unlock" -command "[self] check_passwd $state $container $help"
        my bind_method $input <Key-Return> "check_passwd $state $container $help"
        
        pack $container -expand 1 -fill both -pady 2p -padx 2p
        grid $left $right -sticky ew -pady 4p -ipady 4p -padx 4p -ipadx 4p
        pack $logo
        pack $prompt -pady 3p
        pack $input -pady 3p
        pack $submit -pady 3p
        pack $help -pady 3p
        
        $Root focus
        focus $input
    }

    method quit {_} {
        $Controller destroy
    }

    method set_theme {_ _ name} {
        set Theme $name
        my update_theme
    }
     
    method update_theme {} {
        ::ttk::style theme use $Theme
    }
    
    method main {} {
        set menubar [::menubar new]
        
        $menubar define {
            File M:file {
                Quit        C       quit
            }
            View M:view {
                Theme       S       separator1
                default     R       theme_selector
                Arc         R       theme_selector
                black       R       theme_selector
                waldorf     R       theme_selector
            }
            Help M:help {
                About       C       about
            }
        }
        
        $menubar install "." {
            $menubar menu.configure -command [list \
                quit                "[self] quit" \
                theme_selector      "[self] set_theme" \
                about               "[self] about" \
            ] -bind {
                quit                {0 Ctrl+Q Control-Key-q}
            }
        }

        set main_state [State new]
        set container [::ttk::frame .main]
        set sidebar [::ttk::frame .main.sidebar]
        set side_top [::ttk::frame .main.sidebar.top]
        set side_content [::ttk::frame .main.sidebar.content]       
        set accounts [::ttk::frame .main.accounts]
        set status [::ttk::frame .main.status]    
        set logo [::ttk::label .main.sidebar.top.logo]
        set message [::ttk::label .main.status.message]
        
        $sidebar configure -width 300
        $status configure -relief groove
        $logo configure -image $Logo
        $message configure -textvariable [$main_state var Notice]
        
        pack $container -expand 1 -fill both
        pack $sidebar -side left
        pack $side_top -side top
        pack $side_content
        pack $accounts -expand 1
        pack $status -side bottom -fill x
        pack $logo -padx 4p -pady 4p
        pack $message -padx 4p -pady 4p
        
        $Root maximize
    }
    
    destructor {
        destroy "."
    }
}