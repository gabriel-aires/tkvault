oo::class create Window {
	variable Path

	constructor {path} {
		set Path $path

		if {$Path ne {.}} {
			toplevel $Path
		}

		wm protocol $Path WM_DELETE_WINDOW [list [self] destroy]
	}

	method id {} {
		return $Path
	}

	method title {title} {
		wm title $Path $title
	}

	method focus {} {
		my center
		grab $Path
		focus $Path
		wm deiconify $Path
		wm attributes $Path -topmost 1
	}

	method unfocus {} {
		grab release $Path
		wm attributes $Path -topmost 0
	}

	method center {} {
		update
		set x [/ [- [winfo screenwidth .] [winfo width $Path]] 2]
		set y [/ [- [winfo screenheight .] [winfo height $Path]] 2]
		wm geometry $Path +$x+$y
	}

	method maximize {} {
		if {$::tcl_platform(platform) eq "unix"} {
			wm attributes $Path -zoomed 1
		} else {
			wm state $Path zoomed
		}
	}

	method configure {options} {
		$Path configure {*}$options
	}

	destructor {
		my unfocus
		destroy $Path
	}
}
