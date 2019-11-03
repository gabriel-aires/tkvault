oo::class create Gui {
    variable Root Vault Operation Target Controller Theme Accounts \
        ScreenWidth ScreenHeight ScreenSize PixelDensity FontsAvailable \
        RegularFont MonospaceFont
    
    constructor {vault operation target controller} {
        set Vault $vault
        set Operation $operation
        set Target $target
        set Controller $controller
        set Root [Window new "."]
        set ScreenWidth [winfo screenwidth "."]
        set ScreenHeight [winfo screenheight "."]
        set ScreenSize [/ [sqrt [+ [** [winfo screenmmwidth "."] 2] [** [winfo screenmmheight "."] 2]]] 25.4]
        set PixelDensity [/ [sqrt [+ [** $ScreenWidth 2] [** $ScreenHeight 2]]] $ScreenSize]
        set Theme [expr {$::tcl_platform(platform) == "unix" ? "Breeze" : "vista"}]
        set FontsAvailable [font families]
        set RegularFont {}
        set MonospaceFont {}
        my discover_fonts
        my update_theme
        
        # responsive layout
        if [<= $PixelDensity 130.0] {
            my create_icons "small"
            my create_fonts 20 14 9
        } elseif [<= $PixelDensity 260.0] {
            my create_icons "medium"
            my create_fonts 24 18 11
        } else {
            my create_icons "large"
            my create_fonts 28 22 13
        }
    }
    
    method discover_fonts {} {
        foreach font {
			"Droid Sans"
			"Segoe UI"
			"Lucida Sans Unicode"
			"Calibri"
			"Trebuchet MS"
			"Century Gothic"
			"Tahoma"
			"Verdana"
			"Arial"
			"Georgia"
			"Helvetica"
			"Liberation Sans"
			"DejaVu Sans"
			"Bitstream Vera Sans"
			"clean"
            "newspaper"
		} {
			lappend regular_fonts $font [string tolower $font]
		}

		foreach font {
			"Droid Sans Mono"
			"Consolas"
			"Hack"
			"Inconsolata"
			"Lucida Console"
			"Liberation Mono"
			"DejaVu Sans Mono"
			"Bitstream Vera Sans Mono"
            "Courier 10 Pitch"
			"Courier New"
            "Courier"
			"System"
			"Terminal"
			"fixed"
		} {
			lappend monospace_fonts $font [string tolower $font]
		}
        
        my select_font "regular" $regular_fonts
        my select_font "monospace" $monospace_fonts
    }
    
    method select_font {type families} {
        foreach family $families {
			if [in $family $FontsAvailable] {
                if [== type "regular"] {
                    set RegularFont $family
                } else {
                    set MonospaceFont $family
                }
				break
			}
		}
    }
    
    method create_fonts {icon_size large_size regular_size} {
        font create "icon" -family $MonospaceFont -weight "bold" -size $icon_size
        font create "large" -family $RegularFont -size $large_size
        font create "regular" -family $RegularFont -size $regular_size
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
            favorites
            archive
            basket
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
        set buttons {}
        
        foreach {name id _} $raw_credentials {
            dict set credentials $name $id
        }
        
        foreach name [lsort [dict keys $credentials]] {
            set id      [dict get $credentials $name]
            set cframe  [CFrame new ${content}.button_$name {puts click} 2]
            set left    [$cframe add_label [$cframe content].icon gray 30 gray 97]
            set right   [::ttk::frame [$cframe content].info]
            set top     [$cframe add_label ${right}.name gray 97 gray 30]
            set bottom  [$cframe add_label ${right}.id gray 30 gray 97]
            set capital [string toupper [string index $name 0]]
            $left configure -text " $capital " -font "icon"
            $top configure -text " $name " -anchor nw -font "large"
            $bottom configure -text " login: $id " -font "regular"
            pack $left -side left -fill both
            pack $right -side left -fill both -expand 1
            pack $top $bottom -side top -fill both -expand 1 -anchor nw
            lappend buttons [$cframe root]
        }
        
        foreach {a b c d e f} $buttons {
            set buttons [string trimright [join [list $a $b $c $d $e $f] " "]]
            grid {*}$buttons -sticky news -padx 12p -pady 8p
        }
        
        grid columnconfigure $content "all" -uniform "buttons"
        pack $root -side left -fill both -expand 1 -pady 10p -padx 10p
    }
    
    method left_content {frame} {
        set container   [::ttk::frame ${frame}.container]
        set login_controls   [Controls new $container "Login" {gray 15}]
        set card_controls    [Controls new $container "Card" {HotPink 4}]
        set doc_controls     [Controls new $container "Document" {DodgerBlue 4}]
        set note_controls    [Controls new $container "Note" {goldenrod 3}]
        set income_controls  [Controls new $container "Income" {cyan 4}]
        set expense_controls [Controls new $container "Expense" {firebrick 3}]
        pack $container -pady 2p
        pack [$login_controls get_container] -pady 1p -ipady 5p -fill x
        pack [$card_controls get_container] -pady 1p -ipady 5p -fill x
        pack [$doc_controls get_container] -pady 1p -ipady 5p -fill x
        pack [$note_controls get_container] -pady 1p -ipady 5p -fill x
        pack [$income_controls get_container] -pady 1p -ipady 5p -fill x
        pack [$expense_controls get_container] -pady 1p -ipady 5p -fill x        
    }

    method right_content {frame width} {
        set container   [::ttk::frame ${frame}.container -width $width]
        set favorites_folder    [Folder new $container "Favorites" ::img::favorites {firebrick 3}]
        set archive_folder      [Folder new $container "Archive" ::img::archive {bisque 4}]
        set recycle_folder      [Folder new $container "Recycle Bin" ::img::basket {cyan 4}]
        pack $container -pady 2p -fill y -expand 1
        pack [$favorites_folder get_container] -pady 1p -ipady 5p -fill both -expand 1
        pack [$archive_folder get_container] -pady 1p -ipady 5p -fill both -expand 1
        pack [$recycle_folder get_container] -pady 1p -ipady 5p -fill both -expand 1
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

        set body    [::ttk::frame .body]
        set left    [::ttk::frame .body.side_controls]
        set right   [::ttk::frame .body.side_folders]
        set main    [::ttk::frame .body.main]
        set footer  [::ttk::frame .body.footer -relief groove]        
        
        pack $body -fill both -expand 1
        pack $footer -side bottom -fill x
        pack $left -side left -fill y
        pack $right -side right -fill y
        pack $main -fill both -expand 1 -padx 2p -pady 2p
        
        my left_content $left
        my right_content $right [winfo reqwidth $left]
        my main_content $main
        my footer_content $footer
        
        $Root maximize
    }
    
    destructor {
        destroy "."
    }
}