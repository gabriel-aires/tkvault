oo::class create Gui {
    variable Root Vault Operation Target Logo Controller Theme
    
    constructor {vault operation target controller} {
        package require Tk
        package require menubar
        set Vault $vault
        set Operation $operation
        set Target $target
        set Controller $controller
        set Theme [expr {$::tcl_platform(platform) == "unix" ? "clam" : "vista"}]
        set ScrolledFrame {}
        set Logo [image create photo -file [file join $::conf::img_path "logo.png"]]        
        set Root [Window new "."]
        font create "mono" -family "Courier" -weight "bold" -size 21
        my update_theme
    }
    
    method bind_method {origin event method} {
		bind $origin $event "if {{%W} eq {$origin}} {[self] $method}"
	}
    
    method check_passwd {state auth_container help} {
        set master_pw [$state get Input]
        set success [$Vault open $master_pw $state]
        if $success {
            $help configure -foreground "blue"
            $state set Notice "Welcome!"
            after 1000 "destroy $auth_container; $state destroy; [self] main"
        } else {
            $help configure -foreground "red"
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
        pack $left $right -side left -fill both -expand 1 -pady 4p -ipady 4p -padx 4p -ipadx 4p
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
    
    method menubar {} {
        set menubar [::menubar new]
        
        $menubar define {
            File M:file {
                Quit        C       quit
            }
            Help M:help {
                About       C       about
            }
        }
        
        $menubar install "." {
            $menubar menu.configure -command [list \
                quit                "[self] quit" \
                about               "[self] about" \
            ] -bind {
                quit                {0 Ctrl+Q Control-Key-q}
            }
        }
    }
    
    method side_content {frame} {
        set state   [State new]
        set msg     [::ttk::label ${frame}.msg]
        set count   [::ttk::label ${frame}.count]
        $state set Output [$Vault count_credentials]
        $msg configure -text "Stored Credentials: "
        $count configure -textvariable [$state var Output]
        pack $msg $count -side left -padx 20p -pady 20p
    }
    
    method accounts_list {parent_frame} {
        set state   [State new]
        $Vault show_credentials $state
        set raw_credentials [$state get Output]
        set sframe [SFrame new ${parent_frame}.sframe]
        set root [$sframe root]
        set content [$sframe content]
        set credentials {}
        
        foreach {name id _} $raw_credentials {
            dict set credentials $name $id
        }
        
        foreach name [lsort [dict keys $credentials]] {
            set id      [dict get $credentials $name]
            set cframe  [CFrame new ${content}.button_$name {puts click} 1]
            set button  [$cframe root]
            set left    [$cframe add_label [$cframe content].icon gray 30 azure 3]
            set right   [::ttk::frame [$cframe content].info]
            set top     [$cframe add_label ${right}.name gray 30 azure 3]
            set bottom  [$cframe add_label ${right}.id gray 100 gray 40]
            set capital [string toupper [string index $name 0]]
            $left configure -text " $capital " -font "mono"
            $top configure -text " Name: $name " -anchor nw
            $bottom configure -text " Identity: $id "
            pack $left -side left -fill both
            pack $right -side left -fill both -expand 1
            pack $top $bottom -side top -fill both -expand 1 -anchor nw
            pack $button -fill both -expand 1
        }
        
        pack $root -side left -fill y -anchor nw
    }
    
    method main {} {
        my menubar

        set main_state [State new]
        set container [::ttk::frame .main]
        set sidebar [::ttk::frame .main.sidebar]
        set side_top [::ttk::frame .main.sidebar.top]
        set side_content [::ttk::frame .main.sidebar.content]       
        set accounts [::ttk::frame .main.accounts]
        set status [::ttk::frame .main.status]    
        set logo [::ttk::label .main.sidebar.top.logo]
        set message [::ttk::label .main.status.message]
        
        $status configure -relief groove
        $logo configure -image $Logo
        $message configure -textvariable [$main_state var Notice]
        
        pack $container -expand 1 -fill both
        pack $status -side bottom -fill x
        pack $sidebar -side left -anchor n
        pack $side_top -side top -anchor n
        pack $side_content -side top -anchor n
        pack $accounts -side left -anchor nw -fill y -pady 10p
        pack $logo -padx 20p -pady 10p -side top -anchor n
        pack $message -padx 4p -pady 4p
        
        my side_content $side_content
        my accounts_list $accounts
        $Root maximize
    }
    
    destructor {
        destroy "."
    }
}