# An HTML templating DSL for Jim Tcl.
# Copyright (C) 2014 Danyil Bohdan.
# License: MIT

# HTML entities processing code based on http://wiki.tcl.tk/26403.
source entities.tcl

set html::entitiesInverse [lreverse $html::entities]

proc html::escape text {
    global html::entities
    string map $html::entities $text
}

proc html::unescape text {
    global html::entitiesInverse
    string map $html::entitiesInverse $text
}

proc html::tag {tag args} {
    # If there's only argument given treat it as tag content. If there is more
    # than one argument treat the first one as a tag attribute dict and the
    # rest as content.
    set attribs {}
    if {[llength $args] > 1} {
        set attribs [lindex $args 0]
        set args [lrange $args 1 end]
    }

    set attribText {}
    foreach {name value} $attribs {
        append attribText " $name=\"$value\""
    }
    return "<$tag$attribText>[join $args ""]</$tag>"
}

proc html::tag-no-content {tag {attribs {}}} {
    set attribText {}
    foreach {name value} $attribs {
        append attribText " $name=\"$value\""
    }
    return "<$tag$attribText>"
}

# Zip together (transpose) lists.
proc html::zip args {
    set columns $args
    set nColumns [llength $columns]
    set loopArgument {}

    # Generate loop command argument in the form of v0 list0 v1 list1, etc.
    set variables [lmap i [range $nColumns] { list v$i }]
    foreach i [range $nColumns] column $columns {
        lappend loopArgument v$i [lindex $args $i]
    }

    set result {}
    foreach {*}$loopArgument {
        lappend result [lmap var $variables { set $var }]
    }
    puts $result
    return $result
}

# Here we actually create the tags. Proc static variables are not use for the
# sake of Tcl compatibility.
set tags {html body table td tr a div pre form textarea h1}
set tagsWithoutContent {input submit br hr}

foreach tag $tags {
    proc $tag args [
        format {html::tag %s {*}$args} $tag
    ]
}
foreach tag $tagsWithoutContent {
    proc $tag args [
        format {html::tag-no-content %s {*}$args} $tag
    ]
}

proc html::make-table-row args {
    tr "" {*}[lmap cell $args { td $cell }]
}

# Return an HTML table. Each argument is converted to a table row.
proc html::make-table args {
    table {} {*}[
        lmap row [html::zip {*}$args] {
            html::make-table-row {*}$row
        }
    ]
}
