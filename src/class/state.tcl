oo::class create State {
    variable Input Output Notice
    
    constructor {args} {
        set Input {}
        set Output {}
        set Notice {}
    }
    
    method var {name} {
        return [my varname $name]
    }
    
    method get {name} {
        return [set $name]
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