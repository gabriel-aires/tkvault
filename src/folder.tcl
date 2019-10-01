oo::class create Folder {
    variable Container Label Image Quantity ColorName ColorIndex
    
    constructor {parent label image color} {
        lassign $color ColorName ColorIndex
        set Label $label
        set Image $image
        set Quantity 0
        set name [join $Label _]
        set cframe       [CFrame new ${parent}.folder_$name {puts click} 0]
        set Container           [$cframe root]
        set top                 [::ttk::frame [$cframe content].top]
        set bottom              [::ttk::frame [$cframe content].bottom]
        set title               [$cframe add_label ${top}.title gray 3 $ColorName $ColorIndex]
        set quantity            [$cframe add_label ${top}.quantity gray 3 $ColorName $ColorIndex]
        set image               [$cframe add_label ${bottom}.image $ColorName $ColorIndex gray 20]
        
        $title configure -text $Label -font "large"
        $quantity configure -text $Quantity -font "large"
        $image configure -image $Image -anchor center
        
        pack $Container -fill both
        pack $top -fill both
        pack $bottom -fill both -expand 1
        pack $title -side left -fill both -expand 1 -ipadx 2p
        pack $quantity -side right -fill both -ipadx 2p
        pack $image -fill both -expand 1 -ipadx 20p -ipady 20p
    }
    
    method get_container {} {
        return $Container
    }
}