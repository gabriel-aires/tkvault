oo::class create State {
    
    constructor {args} {
        set variables {Output Notice}
        lappend variables {*}$args
        variable {*}$variables
        foreach var $variables {
            set $var {}
        }
    }
    
    method var {name} {
        return [my varname $name]
    }
    
    method get {name} {
        set value {}
        catch {set value [set $name]}
        return $value
    }
    
    method clear {name} {
        set $name {}
    }
    
    method set {name args} {
        set $name {*}$args
    }
    
    method append {name args} {
        lappend $name {*}$args
    }
}