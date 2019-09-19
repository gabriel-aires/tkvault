oo::class create Controls {
    variable Container ColorName ColorIndex Visibility ColorSelector TypeLabel DisplayInfo VisibilitySwitch AddCredential
    
    constructor {parent name color} {
        lassign $color ColorName ColorIndex
        set Visibility          true
        set Container           [::ttk::frame ${parent}.controls_$name]
        set ColorSelector       [CFrame new ${Container}.color {puts click} 0]
        set TypeLabel           [::ttk::label ${Container}.label -text " $name " -font "large" -background "white"]
        set DisplayInfo         [CFrame new ${Container}.display {puts click} 0]
        set VisibilitySwitch    [CFrame new ${Container}.visibility {puts click} 0]
        set AddCredential       [CFrame new ${Container}.add {puts click} 0]
        set color_button        [$ColorSelector root]
        set color_label         [$ColorSelector add_label [$ColorSelector content].selector $ColorName $ColorIndex gray 100]
        set info_button         [$DisplayInfo root]
        set info_label          [$DisplayInfo add_label [$DisplayInfo content].info gray 100 gray 100]        
        set visibility_button   [$VisibilitySwitch root]
        set visibility_label    [$VisibilitySwitch add_label [$VisibilitySwitch content].switch gray 100 gray 100]
        set add_button          [$AddCredential root]
        set add_label           [$AddCredential add_label [$AddCredential content].credential gray 100 gray 100]
        set ref_height          [winfo reqheight $TypeLabel]
        
        foreach {img original} {
            ::img::c_info ::img::info
            ::img::c_show ::img::show
            ::img::c_hide ::img::hide
            ::img::c_add ::img::add
        } {
            if {$img ni [image names]} {
                set original_width  [image width $original]
                set original_height [image height $original]
                set size_ratio_f    [/ [double $original_height] [double $ref_height]]
                set size_ratio_i    [int [ceil $size_ratio_f]]
                set aspect_ratio    [/ $original_width $original_height]
                set img_width       [int [ceil [* $aspect_ratio $ref_height]]]
                set img_height      [int [ceil [/ $img_width $aspect_ratio]]]
                image create photo $img
                $img copy $original -to 0 0 $img_width $img_height -subsample $size_ratio_i
            }
        }
        
        $Container configure -relief groove -borderwidth 1
        $color_label configure -text " " -font "icon"
        $info_label configure -image ::img::c_info
        $visibility_label configure -image ::img::c_show
        $add_label configure -image ::img::c_add
        
        pack $color_button -side left -anchor w -fill y
        pack $add_button -side right -anchor e -fill y
        pack $visibility_button -side right -anchor e -fill y
        pack $info_button -side right -anchor e -fill y
        pack $TypeLabel -fill both -expand 1
        pack $color_label -anchor w -fill y -expand 1
        pack $info_label -anchor w -fill y -expand 1
        pack $visibility_label -anchor w -fill y -expand 1
        pack $add_label -anchor w -fill y -expand 1
    }
    
    method get_container {} {
        return $Container
    }
}