oo::class create Colors {
    
    method palette_range {} {
        return [list 1 4]
    }
    
    method palette_group {} {
        return {
            AntiqueWhite
            aquamarine
            azure
            bisque
            blue
            brown
            burlywood
            CadetBlue
            chartreuse
            chocolate
            coral
            cornsilk
            cyan
            DarkGoldenrod
            DarkOliveGreen
            DarkOrange
            DarkOrchid
            DarkSeaGreen
            DarkSlateGray
            DeepPink
            DeepSkyBlue
            DodgerBlue
            firebrick
            gold
            goldenrod
            green
            honeydew
            HotPink
            IndianRed
            ivory
            khaki
            LavenderBlush
            LemonChiffon
            LightBlue
            LightCyan
            LightGoldenrod
            LightPink
            LightSalmon
            LightSkyBlue
            LightSteelBlue
            LightYellow
            magenta
            maroon
            MediumOrchid
            MediumPurple
            MistyRose
            NavajoWhite
            OliveDrab
            orange
            OrangeRed
            orchid
            PaleGreen
            PaleTurquoise
            PaleVioletRed
            PeachPuff
            pink
            plum
            purple
            red
            RosyBrown
            RoyalBlue
            salmon
            SeaGreen
            seashell
            sienna
            SkyBlue
            SlateBlue
            SlateGray
            snow
            SpringGreen
            SteelBlue
            tan
            thistle
            tomato
            turquoise
            VioletRed
            wheat
            yellow         
        }
    }
    
    method gray_range {} {
        return [list 0 100]
    }
    
    method gray_scale {} {
        return [list grey gray]
    }
    
    method color_exists {name index} {
        lassign [my palette_range] color_min color_max
        lassign [my gray_range] gray_min gray_max
        if {$name in [my palette_group]} {
            return [expr {$index >= $color_min && $index <= $color_max}]
        } elseif {$name in [my gray_scale]} {
            return [expr {$index >= $gray_min && $index <= $gray_max}]            
        }
        return false
    }
    
    method check_color {name index} {
        if [! [my color_exists $name $index]] {
            error "Invalid color '$name$index'."
        }
    }
}