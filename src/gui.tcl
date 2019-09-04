oo::class create Gui {
    variable Root Vault Operation Target
    
    constructor {vault operation target} {
        package require Tk
        package require ttk::theme::Arc
        package require ttk::theme::black
        package require ttk::theme::waldorf
        package require menubar
        namespace import -force ::ttk::*
        set Vault $vault
        set Operation $operation
        set Target $target
        set Logo [image create photo -file [file join $::conf::img_path "logo.png"]]        
        set Root [Window new "."]
        if {$::tcl_platform(os) == "Linux"} {
            ::ttk::style theme use waldorf
        }
    }
    
    method open_vault {} {
        $Root focus  
    }
}