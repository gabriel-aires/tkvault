# Clickabe Frame

oo::class create CFrame {
    variable Container Frame Label BgColor FgColor Command

    constructor {path bgcolor fgcolor cmd} {
        set BgColor $bgcolor
        set FgColor $fgcolor
        set Command $cmd
        set Container [::ttk::frame $path -relief raised]
        set Label [::ttk::label ${Container}.text -background $BgColor -foreground $FgColor]
        my bind_method <Enter> hover_in
        my bind_method <Leave> hover_out
        my bind_method <ButtonPress-1> press
        my bind_method <ButtonRelease-1> release
        pack $Label -fill both -expand 1 -padx 2p -pady 2p
    }

    method container {} {
        return $Container
    }

    method label {} {
        return $Label
    }
    
    method hover_in {} {
        $Label configure -background $FgColor -foreground $BgColor
    }
    
    method hover_out {} {
        $Label configure -background $BgColor -foreground $FgColor
    }
    
    method press {} {
        $Container configure -relief sunken
    }
    
    method release {} {
        $Container configure -relief raised
        {*}$Command
    }
    
    method bind_method {event method} {
        bind $Container $event "[self] $method"
        bind $Label $event "[self] $method"
    }
}