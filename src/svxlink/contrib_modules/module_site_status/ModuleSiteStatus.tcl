###############################################################################
#	SVXlink Site Status Module Coded by Dan Loranger (KG7PAR)
#  
#	This module enables the user to configure sensors to monitor the health and
#   wellbeing of a remote site.  The module runs in the background and on a regular interval (typically a 
#   few times a second) checks the inputs and will announce over the air, any configured messages as 
#   appropriate to alert the site manager/monitors that an event has occurred.
#
###############################################################################
#
# This is the namespace in which all functions and variables below will exist. The name must match the 
# configuration variable "NAME" in the [ModuleTcl] section in the configuration file. The name may be 
# changed but it must be changed in both places.
#
namespace eval SiteStatus {
	# Check if this module is loaded in the current logic core
	#
	if {![info exists CFG_ID]} {
		return;
	}
	#
	# Extract the module name from the current namespace
	#
	set module_name [namespace tail [namespace current]]
	
	
	# A convenience function for printing out information prefixed by the module name
	#
	#   msg - The message to print
	#
	proc printInfo {msg} {
		variable module_name
		puts "$module_name: $msg"
	}
	# Define variables for the sensors here
	variable CFG_DIGITAL_0
	variable CFG_DIGITAL_0_TYPE
	variable CURRENT_STATE_0
	variable NEW_STATE_0
	variable DIGITAL_ENABLE_0
	
	set gpioPath "/sys/class/gpio/gpio"
		
	# capture the initial values on the sensors and enable them if the settings are all defined 
	# (validity of the sensor is not enforced)
	if {[info exists CFG_DIGITAL_0]} {
		set CURRENT_STATE_0 [exec cat $gpioPath$CFG_DIGITAL_0/value]
		set CURRENT_STATE_0 0
		set DIGITAL_ENABLE_0 "ENABLED"
		printInfo "Digital Sensor 0 is enabled"
	} else {
		set DIGITAL_ENABLE_0 DISABLED
		printInfo "Digital Sensor 0 is disabled"
	}
	 
	proc activateInit {} {
		
	}
	
	proc main {} {
		variable CFG_DIGITAL_0
		variable CFG_DIGITAL_0_TYPE
		variable DIGITAL_ENABLE_0
		variable CURRENT_STATE_0
		variable NEW_STATE_0
		variable gpioPath
		# Digital Sensors
		if {$DIGITAL_ENABLE_0 == "ENABLED"} {
			# Read the state of the sensor and compare against the old state alerts should only 
			# go out when the sensor changes state
			set NEW_STATE_0 [exec cat $gpioPath$CFG_DIGITAL_0/value]
			if {$CURRENT_STATE_0 != $NEW_STATE_0} {
				set CURRENT_STATE_0 $NEW_STATE_0
				printInfo "Digital Sensor 0 has changed state"
#				printInfo "Type_0: $CFG_DIGITAL_0_TYPE"
				switch $CFG_DIGITAL_0_TYPE {
					DOORSENSOR {
						DOORSENSOR_STATUS 0 $NEW_STATE_0
					}
					#TEMPSENSOR{TEMPSENSOR_STATUS{0 $NEW_STATE_0}}
					default {
						printInfo "SENSOR 0 is of unknown type"
					}
				}
			}
		}
		
	}
	#basic function to announce the door sensor changing status
	proc DOORSENSOR_STATUS {sensor value} {
#		variable sensor
#		variable value		
		if {$value == 1} {
			playMsg "site_door_open"
			printInfo "Door Sensor Number $sensor indicates the door is now open"
		} else {
			playMsg "site_door_closed"
			printInfo "Door Sensor Number $sensor indicates the door is now closed"
		}
	}
	#
	# Executed when this module is being deactivated.
	#
	proc deactivateCleanup {} {
		printInfo "Module deactivated"
	}
	
	#
	# Executed when this module is being deactivated.
	#
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
