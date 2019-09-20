oo::class create Gui {
    variable Root Vault Operation Target Controller Theme Accounts ScreenWidth
    
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
            font create "icon" -family "Courier" -weight "bold" -size 20
            font create "large" -family "Helvetica" -size 14
            font create "regular" -family "Helvetica" -size 11
        } elseif [<= $ScreenWidth 1920] {
            my create_icons "medium"
            font create "icon" -family "Courier" -weight "bold" -size 24
            font create "large" -family "Helvetica" -size 18
            font create "regular" -family "Helvetica" -size 13
        } else {
            my create_icons "large"
            font create "icon" -family "Courier" -weight "bold" -size 28
            font create "large" -family "Helvetica" -size 22
            font create "regular" -family "Helvetica" -size 15
        }
    }
    
    method create_photo {name size} {
        image create photo ::img::$name -file [file join $::conf::img_path "${name}_${size}.png"]    
    }
    
    method create_icons {size} {
        foreach item {
            logo
            watermark
            login
            card
            document
            note
            show
            hide
            info
            add
        } {
            my create_photo $item $size
        }
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
            after 1000 "destroy $auth_container; $state destroy; [self] layout"
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
        $logo configure -image ::img::logo
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
    
    method side_content {frame} {
        set container   [::ttk::frame ${frame}.container]
        set login_controls   [Controls new $container "Login" {OliveDrab 2}]
        set card_controls    [Controls new $container "Card" {firebrick 3}]
        set doc_controls     [Controls new $container "Document" {gold 2}]
        set note_controls    [Controls new $container "Note" {cyan 4}]
        pack $container -pady 2p
        pack [$login_controls get_container] -pady 1p -ipady 5p -fill x
        pack [$card_controls get_container] -pady 1p -ipady 5p -fill x
        pack [$doc_controls get_container] -pady 1p -ipady 5p -fill x
        pack [$note_controls get_container] -pady 1p -ipady 5p -fill x
    }
    
    method main_content {frame} {
        if [eq [$Vault count_credentials] 0] {
            set logo [::ttk::label ${frame}.logo]
            $logo configure -image ::img::watermark
            pack $logo -fill y -expand 1 -pady 5p
        } else {
            my accounts_list $frame
        }
    }
    
    method footer_content {frame} {
        set state [State new]
        set container [::ttk::frame ${frame}.section]
        set message [::ttk::label ${container}.message]
        set info [::ttk::label ${container}.info]
        $message configure -text "Vault Items: " -font "regular"
        $info configure -textvariable [$state var Notice] -font "regular"
        $state set Notice [$Vault count_credentials]
        pack $message $info -side left -pady 4p
        pack $container -pady 1p
    }
    
    method layout {} {
        my menubar

        set body [::ttk::frame .body]
        set sidebar [::ttk::frame .body.sidebar]   
        set main [::ttk::frame .body.main]
        set footer [::ttk::frame .body.footer -relief groove]        
        
        pack $body -fill both -expand 1
        pack $footer -side bottom -fill x
        pack $sidebar -side left -fill y
        pack $main -side right -fill both -expand 1 -padx 2p -pady 2p
        
        my side_content $sidebar
        my main_content $main
        my footer_content $footer
        
        $Root maximize
    }
    
    destructor {
        destroy "."
    }
}