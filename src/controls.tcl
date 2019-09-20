oo::class create Controls {
    variable Container ColorName ColorIndex Visibility ColorSelector TypeLabel DisplayInfo VisibilitySwitch AddCredential
    
    constructor {parent name color} {
        lassign $color ColorName ColorIndex
        set Visibility          true
        set Container           [::ttk::frame ${parent}.controls_$name]
        set ColorSelector       [CFrame new ${Container}.color {puts click} 0]
        set TypeLabel           [::ttk::label ${Container}.label]
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
        
        foreach {img original} {
            ::img::gray_info ::img::info
            ::img::gray_show ::img::show
            ::img::gray_hide ::img::hide
            ::img::gray_add ::img::add
        } {
            if {$img ni [image names]} {
                image create photo $img
                $img put [$original data -grayscale -format png]
            }
        }
        
        $color_label configure -text " 0 " -font "icon"
        $TypeLabel configure -text " $name " -font "regular" -background "white"
        $info_label configure -image ::img::gray_info -anchor center
        $visibility_label configure -image ::img::gray_show -anchor center
        $add_label configure -image ::img::gray_add -anchor center
        
        pack $color_button -side left -anchor w -fill y
        pack $add_button -side right -anchor e -fill y
        pack $visibility_button -side right -anchor e -fill y
        pack $info_button -side right -anchor e -fill y
        pack $color_label -fill y -expand 1
        pack $TypeLabel -fill both -expand 1 -ipadx 2p
        pack $info_label -fill y -expand 1 -ipadx 2p
        pack $visibility_label -fill y -expand 1 -ipadx 2p
        pack $add_label -fill y -expand 1 -ipadx 2p
        
        bind $info_button       <Enter> +[list [self] toggle_image $DisplayInfo]
        bind $info_button       <Leave> +[list [self] toggle_image $DisplayInfo]
        bind $visibility_button <Enter> +[list [self] toggle_image $VisibilitySwitch]
        bind $visibility_button <Leave> +[list [self] toggle_image $VisibilitySwitch]
        bind $add_button        <Enter> +[list [self] toggle_image $AddCredential]
        bind $add_button        <Leave> +[list [self] toggle_image $AddCredential]
    }
    
    method get_container {} {
        return $Container
    }
    
    method toggle_image {cframe} {
        set label           [lindex [$cframe get_labels] 0]
        set current_image   [lindex [$label configure -image] end]
        
        if [string match ::img::gray_* $current_image] {
            set first [string length "::img::gray_"]
            set new_prefix "::img::"
        } else {
            set first [string length "::img::"]
            set new_prefix "::img::gray_"
        }
        
        set new_name [string range $current_image $first end]
        set new_image "${new_prefix}${new_name}"
        $label configure -image $new_image
    }
}