# Adapted from Paul Walton's implementation at https://wiki.tcl-lang.org/page/A+scrolled+frame

oo::class create SFrame {
    variable Root Canvas Container Content ScrollBar

    constructor {path} {
        
        set bg [::ttk::style lookup TFrame -background]
        set Root [::ttk::frame $path]
        set Canvas [canvas ${Root}.canvas -bg $bg -bd 0 -highlightthickness 0 -yscrollcommand [list ${Root}.scroll set]]
        set ScrollBar [::ttk::scrollbar ${Root}.scroll -orient vertical -command [list $Canvas yview]]
        set Container [::ttk::frame ${Canvas}.container]
        pack propagate $Container 0
        set Content [::ttk::frame ${Container}.content]
        pack $Content -anchor nw
        $Canvas create window 0 0 -window $Container -anchor nw
        
        # pack only the scrollable canvas (without scrollbars).
        pack $Canvas -side left -anchor nw -fill y
        
        # Auto adjusts when the sframe is resized or the contents change size.
        bind $Canvas <Expose> [list [self] resize]
        
        # MouseWheel bindings
        bind [winfo toplevel $Root] <MouseWheel> [list [self] scroll %W %D]
    }

    method root {} {
        return $Root
    }
    
    method content {} {
        return $Content
    }

    method resize {} {
        set width  [winfo width $Canvas]
        set height [winfo height $Canvas]
        
        # Use requested width/height of the content frame, if greater
        if { [winfo reqwidth $Content] > $width } {
            set width [winfo reqwidth $Content]
        }
        if { [winfo reqheight $Content] > $height } {
            set height [winfo reqheight $Content]
        }
        
        $Container configure -width $width -height $height

        # Match scroll region to the height and width of the container
        $Canvas configure -scrollregion [list 0 0 $width $height]

        # Show the scrollbar as necessary
        if { [winfo reqheight $Content] > [winfo height $Canvas] } {
            pack $ScrollBar -side left -anchor nw -fill y
        } else {
            pack forget $ScrollBar
        }
    }
    
    method scroll {window delta} {
        if [string match ${Root}\.* $window] {
            $Canvas yview scroll [expr {-$delta/120}] units
        }
    }
}

