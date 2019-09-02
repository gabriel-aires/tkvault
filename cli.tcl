oo::class create Cli {
    variable State
    
    constructor {args} {
        set State [State new {*}$args]
    }
    
    method get_state {} {
        return $State
    }
    
    #hide password input
    method hide_input {script} {
        catch {exec stty -echo}
        uplevel 1 $script
        catch {exec stty echo}
        puts "\n"
    }
    
    method prompt {message} {
        puts -nonewline "$message "
        flush stdout
    }
    
    method info {} {
        set notice [$state get Notice]
        puts $notice
    }
}