###############################################################################
#  SVXlink Site Status Module Coded by Dan Loranger (KG7PAR)
#  
#  This module enables the user to configure sensors to monitor the health and
#  wellbeing of a remote site.  The module runs in the background and on a 
#  regular interval (once per second) checks the inputs and will announce over 
#  the air, any configured messages as to alert the site manager/monitors 
#  that an event of interest has occurred.
#
###############################################################################
#
# This is the namespace in which all functions and variables below will exist. 
# The name must match the configuration variable "NAME" in the [ModuleTcl] 
# section in the configuration file. The name may be changed but it must be 
# changed in both places.
#
###############################################################################
namespace eval TxFan {
	# Check if this module is loaded in the current logic core
	#
	if {![info exists CFG_ID]} {
		return;
	}
	#
	# Extract the module name from the current namespace
	#
	set module_name [namespace tail [namespace current]]
	
	
	# A convenience function for printing out info prefixed by the module name
	#
	#   msg - The message to print
	#
	proc printInfo {msg} {
		variable module_name
		puts "$module_name: $msg"
	}
	 
	proc activateInit {} {
		
	}
	
	proc main {} {
		variable CFG_PTT_PATH_1
		variable CFG_PTT_PATH_2
		variable CFG_FAN_GPIO
		if {[exec cat $CFG_PTT_PATH_1] | [exec cat $CFG_PTT_PATH_2]}  { 
			#printInfo "Fan Enabled"
			set fp [open $CFG_FAN_GPIO w]
			puts $fp "1"
			close $fp
		} else {
			#printInfo "Fan disabled"
			set fp [open $CFG_FAN_GPIO w]
			puts $fp "0"
			close $fp
		}
	}
	
	
	
	# Executed when this module is being deactivated.
	#
	proc deactivateCleanup {} {
		printInfo "Module deactivated"
	}
	
	# check for new events
	proc check_for_alerts {} {
		main
	}
	
	append func $module_name "::check_for_alerts";
	Logic::addTimerTickSubscriberSeconds $func;
	
	# end of namespace
}
#
# This file has not been truncated
#
