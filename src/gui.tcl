oo::class create Gui {
    variable Root Vault Operation Target Controller Theme Img IconNote ScreenWidth
    
    constructor {vault operation target controller} {
        package require Tk
        package require menubar
        package require ttk::theme::Arc
        set Vault $vault
        set Operation $operation
        set Target $target
        set Controller $controller
        set Img {}
        set Root [Window new "."]
        set ScreenWidth [winfo screenwidth "."]
        set Theme [expr {$::tcl_platform(platform) == "unix" ? "Arc" : "vista"}]
        my update_theme
        
        # responsive layout
        if [<= $ScreenWidth 1366] {
            my create_icons "small"
            font create "icon" -family "Courier" -weight "bold" -size 24
            font create "large" -family "Helvetica" -weight "bold" -size 14
            font create "regular" -family "Helvetica" -size 10
        } elseif [<= $ScreenWidth 1920] {
            my create_icons "small"
            font create "icon" -family "Courier" -weight "bold" -size 32
            font create "large" -family "Helvetica" -weight "bold" -size 16
            font create "regular" -family "Helvetica" -size 11
        } else {
            my create_icons "medium"
            font create "icon" -family "Courier" -weight "bold" -size 48
            font create "large" -family "Helvetica" -weight "bold" -size 18
            font create "regular" -family "Helvetica" -size 12
        }
    }
    
    method create_icons {size} {
        dict set Img logo         [image create photo -file [file join $::conf::img_path "logo_$size.png"]]
        dict set Img watermark    [image create photo -file [file join $::conf::img_path "watermark_$size.png"]]
        dict set Img login        [image create photo -file [file join $::conf::img_path "login_$size.png"]]
        dict set Img card         [image create photo -file [file join $::conf::img_path "card_$size.png"]]
        dict set Img document     [image create photo -file [file join $::conf::img_path "document_$size.png"]]
        dict set Img note         [image create photo -file [file join $::conf::img_path "note_$size.png"]]
        #dict set Img back         [image create photo -file [file join $::conf::img_path "back_$size.png"]]
        #dict set Img delete       [image create photo -file [file join $::conf::img_path "delete_$size.png"]]
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
        set top [::ttk::frame .auth.logo]
        set logo [::ttk::label .auth.logo.img]
        set bottom [::ttk::frame .auth.form]
        set prompt [::ttk::label .auth.form.passwd_label]
        set input [::ttk::entry .auth.form.passwd_entry]
        set submit [::ttk::button .auth.form.submit]
        set help [::ttk::label .auth.form.help]
        
        $container configure -text "Authentication"
        $logo configure -image [dict get $Img watermark]
        $prompt configure -text "Enter Master Password" -font "regular"
        $input configure -show * -textvariable [$state var Input] -takefocus 1 -width 30 -font "regular"
        $help configure -textvariable [$state var Notice] -font "regular"
        $submit configure -text "Unlock" -command "[self] check_passwd $state $container $help"
        my bind_method $input <Key-Return> "check_passwd $state $container $help"
        
        pack $container -expand 1 -fill both -ipadx 15p -ipady 15p
        pack $top $bottom -side top -fill both -expand 1
        pack $logo -side bottom -anchor s -pady 5p
        pack $prompt -pady 5p
        pack $input -pady 5p
        pack $submit -pady 5p
        pack $help -pady 5p
        
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
        $msg configure -text "Stored Credentials: "  -font "regular"
        $count configure -textvariable [$state var Output] -font "regular"
        pack $msg $count -side left -padx 20p -fill x -expand 1
    }
    
    method form_content {frame} {
        set state       [State new]
        set add_login   [::ttk::button ${frame}.add_login -text "New Login" -image [dict get $Img login] -compound top -width 40]
        set add_card    [::ttk::button ${frame}.add_card -text "New Card" -image [dict get $Img card] -compound top -width 40]
        set add_doc     [::ttk::button ${frame}.add_doc -text "New Document" -image [dict get $Img document] -compound top -width 40]
        set add_note    [::ttk::button ${frame}.add_note -text "New Note" -image [dict get $Img note] -compound top -width 40]
        grid $add_login $add_card -padx 5p -pady 5p -ipadx 5p -ipady 5p -sticky news
        grid $add_doc $add_note -padx 5p -pady 5p -ipadx 5p -ipady 5p -sticky news
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
            set left    [$cframe add_label [$cframe content].icon IndianRed 4 gray 97]
            set right   [::ttk::frame [$cframe content].info]
            set top     [$cframe add_label ${right}.name gray 97 IndianRed 4]
            set bottom  [$cframe add_label ${right}.id IndianRed 4 gray 97]
            set capital [string toupper [string index $name 0]]
            $left configure -text " $capital " -font "icon"
            $top configure -text " $name " -anchor nw -font "large"
            $bottom configure -text " login: $id " -font "regular"
            pack $left -side left -fill both
            pack $right -side left -fill both -expand 1
            pack $top $bottom -side top -fill both -expand 1 -anchor nw
            pack $button -fill both -expand 1
        }
        
        $root configure -borderwidth 2 -relief groove
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
        set form_footer [::ttk::frame .main.form.footer]
        set form_body [::ttk::frame .main.form.body]
        set form_left [::ttk::frame .main.form.body.left]
        set form_right [::ttk::frame .main.form.body.right]
        set form_content [::ttk::frame .main.form.body.content]
        set logo [::ttk::label .main.sidebar.logo]
        set status [::ttk::frame .main.status]    
        set message [::ttk::label .main.status.message]
        
        $status configure -relief groove
        $logo configure -image [dict get $Img logo]
        $message configure -textvariable [$main_state var Notice] -font "regular"
        
        pack $container -expand 1 -fill both
        pack $status -side bottom -fill x
        pack $sidebar -side left -anchor n -padx 20p -pady 20p -ipadx 10p -ipady 20p
        pack $accounts -side left -fill y -pady 10p
        pack $form -fill both -expand 1 -padx 20p -pady 20p
        pack $form_header -side top -fill both -expand 1
        pack $form_footer -side bottom -fill both -expand 1
        pack $form_left -side left -fill both -expand 1
        pack $form_right -side right -fill both -expand 1
        pack $form_content
        pack $form_body
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