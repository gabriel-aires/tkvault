oo::class create Gui {
    variable Root Vault Operation Target Logo Controller Theme
    
    constructor {vault operation target controller} {
        package require Tk
        package require menubar
        package require ttk::theme::waldorf
        set Vault $vault
        set Operation $operation
        set Target $target
        set Controller $controller
        set Theme [expr {$::tcl_platform(platform) == "unix" ? "waldorf" : "vista"}]
        set ScrolledFrame {}
        set Logo [image create photo -file [file join $::conf::img_path "logo.png"]]        
        set Root [Window new "."]
        font create "icon" -family "Courier" -weight "bold" -size 24
        font create "large" -family "Helvetica" -weight "bold" -size 16
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
        pack $msg $count -side left -padx 20p -fill x -expand 1
    }
    
    method form_content {frame} {
        set state       [State new]
        set add_login   [::ttk::button ${frame}.add_login -text "New Login" -width 20]
        set add_card    [::ttk::button ${frame}.add_card -text "New Card" -width 20]
        set add_doc     [::ttk::button ${frame}.add_doc -text "New Document" -width 20]
        set add_note    [::ttk::button ${frame}.add_note -text "New Note" -width 20]
        pack $add_login $add_card $add_doc $add_note -pady 5p -ipady 5p
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
            set cframe  [CFrame new ${content}.button_$name {puts click} 0]
            set button  [$cframe root]
            set left    [$cframe add_label [$cframe content].icon IndianRed 3 gray 30]
            set right   [::ttk::frame [$cframe content].info]
            set top     [$cframe add_label ${right}.name IndianRed 3 gray 100]
            set bottom  [$cframe add_label ${right}.id gray 100 gray 40]
            set capital [string toupper [string index $name 0]]
            $left configure -text " $capital " -font "icon"
            $top configure -text " $name " -anchor nw -font "large"
            $bottom configure -text " login: $id "
            pack $left -side left -fill both
            pack $right -side left -fill both -expand 1
            pack $top $bottom -side top -fill both -expand 1 -anchor nw
            pack $button -fill both -expand 1
        }
        
        pack $root -side left -fill both -expand 1 -pady 10p
    }
    
    method main {} {
        my menubar

        set main_state [State new]
        set container [::ttk::frame .main]
        set sidebar [::ttk::frame .main.sidebar -relief groove -borderwidth 2]   
        set accounts [::ttk::frame .main.accounts]
        set form [::ttk::frame .main.form -relief groove -borderwidth 2]
        set form_header [::ttk::frame .main.form.header]
        set form_content [::ttk::frame .main.form.conent]
        set form_footer [::ttk::frame .main.form.footer]
        set logo [::ttk::label .main.sidebar.logo]
        set status [::ttk::frame .main.status]    
        set message [::ttk::label .main.status.message]
        
        $status configure -relief groove
        $logo configure -image $Logo
        $message configure -textvariable [$main_state var Notice]
        
        pack $container -expand 1 -fill both
        pack $status -side bottom -fill x
        pack $sidebar -side left -anchor n -padx 20p -pady 20p -ipadx 10p -ipady 20p
        pack $accounts -side left -fill y -pady 10p
        pack $form -fill both -expand 1 -padx 20p -pady 20p
        pack $form_header $form_content $form_footer -fill both -expand 1 -pady 20p
        pack $logo -padx 20p -pady 20p
        pack $message
        
        my side_content $sidebar
        my form_content $form_content
        my accounts_list $accounts
        $Root maximize
    }
    
    destructor {
        destroy "."
    }
}