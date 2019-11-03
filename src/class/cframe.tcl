# Clickabe Frame

oo::class create CFrame {
    variable Root Content Frame Padding Labels Command ResetColor HoverColor PressColor
    mixin Colors

    constructor {path cmd padding} {
        set ResetColor 0
        set HoverColor -0.4
        set PressColor -1.1
        set Padding $padding
        set Labels {}
        set Command $cmd
        set Root [ttk::frame $path -relief groove]
        set Content [ttk::frame ${Root}.content]
        my bind_method $Root <Enter> colorize_labels $HoverColor
        my bind_method $Root <Leave> colorize_labels $ResetColor
        my bind_method $Root <ButtonPress-1> press $PressColor
        my bind_method $Root <ButtonRelease-1> release $HoverColor
        $Root configure -borderwidth 0 -cursor hand2
        pack $Content -padx ${Padding}p -pady ${Padding}p -fill both -expand 1
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
        ttk::label $path -background "$bgcolor$bgnum" -foreground "$fgcolor$fgnum"
        my bind_method $path <ButtonPress-1> press $PressColor
        my bind_method $path <ButtonRelease-1> release $HoverColor
        return $path
    }
    
    method get_labels {} {
        return $Labels
    }

    method change_color {name index multiplier} {
        lassign [my palette_range] color_min color_max
        lassign [my gray_range] gray_min gray_max
        set isgray [in $name [my gray_scale]]
        set gray_delta [int [floor [* 10 $multiplier]]]
        set color_delta [int [floor $multiplier]]
        set delta [expr {$isgray ? $gray_delta : $color_delta}]
        set max [expr {$isgray ? $gray_max : $color_max}]
        set min [expr {$isgray ? $gray_min : $color_min}]
        set range [+ [- $max $min] 1]
        set index [- $index $min]
        set new_index [+ [% [+ [% $delta $range] $index] $range] $min]
        return "$name$new_index"
    }
    
    method colorize_labels {multiplier} {
        foreach {label bgcolor bgnum fgcolor fgnum} $Labels {
            $label configure -background [my change_color $bgcolor $bgnum $multiplier]
            $label configure -foreground [my change_color $fgcolor $fgnum $multiplier]    
        }
    }
    
    method press {multiplier} {
        $Root configure -relief flat
        my colorize_labels $multiplier
    }
    
    method release {multiplier} {
        $Root configure -relief groove
        my colorize_labels $multiplier
        {*}$Command
    }
    
    method bind_method {origin event method args} {
        bind $origin $event +[list [self] $method $args]
    }
    
    destructor {
        catch {destroy $Root}
    }
}