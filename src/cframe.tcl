# Clickabe Frame

oo::class create CFrame {
    variable Root Content Frame Labels Command
    mixin Colors

    constructor {path cmd} {
        set Labels {}
        set Command $cmd
        set Root [::ttk::frame $path -relief raised]
        set Content [::ttk::frame ${Root}.content]
        my bind_method $Root <Enter> hover_in
        my bind_method $Root <Leave> hover_out
        my bind_method $Root <ButtonPress-1> press
        my bind_method $Root <ButtonRelease-1> release
        pack $Content -padx 2p -pady 2p -fill both -expand 1
    }

    method root {} {
        return $Root
    }
    
    method content {} {
        return $Content
    }
    
    method add_label {path bgcolor bgnum fgcolor fgnum} {
        my check_color $bgcolor $bgnum
        my check_color $fgcolor $fgnum
        lappend Labels $path $bgcolor $bgnum $fgcolor $fgnum
        ::ttk::label $path -background "$bgcolor$bgnum" -foreground "$fgcolor$fgnum"
        my bind_method $path <ButtonPress-1> press
        my bind_method $path <ButtonRelease-1> release
        return $path
    }    

    method hover_color {name index} {
        lassign [my palette_range] color_min color_max
        lassign [my gray_range] gray_min gray_max
        set isgray [in $name [my gray_scale]]
        set delta [expr {$isgray ? 20 : 2}]
        set max [expr {$isgray ? $gray_max : $color_max}]
        set min [expr {$isgray ? $gray_min : $color_min}]
        set range [- $max $min]
        set offset [- [+ $index $delta] $min]
        set new_index [+ [% $offset $range] $min]
        return "$name$new_index"
    }
    
    method hover_in {} {
        foreach {label bgcolor bgnum fgcolor fgnum} $Labels {
            $label configure -background [my hover_color $bgcolor $bgnum]
            $label configure -foreground [my hover_color $fgcolor $fgnum]    
        }
    }
    
    method hover_out {} {
        foreach {label bgcolor bgnum fgcolor fgnum} $Labels {
            $label configure -background "$bgcolor$bgnum"
            $label configure -foreground "$fgcolor$fgnum"
        }
    }
    
    method press {} {
        $Root configure -relief sunken
    }
    
    method release {} {
        $Root configure -relief raised
        {*}$Command
    }
    
    method bind_method {origin event method} {
        bind $origin $event "[self] $method"
    }
    
    destructor {
        catch {destroy $Root}
    }
}