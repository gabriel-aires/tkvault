# Adapted from Paul Walton's implementation at https://wiki.tcl-lang.org/page/A+scrolled+frame

oo::class create SFrame {
    variable Root Window Canvas Container Content ScrollBar

    constructor {path} {
        
        set bg [::ttk::style lookup TFrame -background]
        set Parent [join [lrange [split $path .] 0 end-1] .]
        set Root [::ttk::frame $path]
        set Window [winfo toplevel $Root]
        set Canvas [canvas ${Root}.canvas -bg $bg -bd 0 -highlightthickness 0 -yscrollcommand [list ${Root}.scroll set]]
        set ScrollBar [::ttk::scrollbar ${Root}.scroll -orient vertical -command [list $Canvas yview]]
        set Container [::ttk::frame ${Canvas}.container]
        pack propagate $Container 0
        set Content [::ttk::frame ${Container}.content]
        pack $Content -anchor nw
        $Canvas create window 0 0 -window $Container -anchor nw
        
        # Grid only the scrollable canvas (without scrollbars).
        grid $Canvas -row 0 -column 0 -sticky nsew
        grid rowconfigure    $Root 0 -weight 1
        grid columnconfigure $Root 0 -weight 1
        
        # Auto adjusts when the sframe is resized or the contents change size.
        bind $Canvas <Expose> [list [self] resize]
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
            grid $ScrollBar -row 0 -column 1 -sticky ns
        } else {
            grid forget $ScrollBar
        }
    }
}

