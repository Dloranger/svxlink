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
	 
	proc activateInit {} {
		
	}
	
	# Define variables for the sensors here
	variable CFG_DIGITAL_GPIO_PATH
	for {set i 0} {$i < $CFG_DIGITAL_SENSORS_COUNT} {incr i} {
		set CFG_DIGITAL_$i
		variable CFG_DIGITAL_TYPE_$i
		variable CURRENT_STATE_$i
		variable NEW_STATE_$i
		variable DIGITAL_ENABLE_$i
	}
		
	# capture the initial values on the sensors and enable them if the settings are all defined 
	# capture the initial values on the sensor and enable if the settings are all defined 
	# (validity of the sensor is not enforced)
	for {set i 0} {$i < $CFG_DIGITAL_SENSORS_COUNT} {incr i} {
		variable CFG_DIGITAL_$i
		if {[info exists CFG_DIGITAL_$i]} {
			set PATH $CFG_DIGITAL_GPIO_PATH
			set GPIO "CFG_DIGITAL_$i"
			set GPIO [subst $$GPIO]
			set value [exec cat $PATH$GPIO/value]
			set CURRENT_STATE_$i $value
			set current "CURRENT_STATE_$i"
			#printInfo "Initial Logic State-[subst $$current]"
			printInfo "Digital Sensor $i is enabled"
			set DIGITAL_ENABLE_$i "ENABLED"
		} else {
			set DIGITAL_ENABLE_$i "DISABLED"
			#printInfo "Digital Sensor $i is not configured"
		}
	}

	proc main_every_second {} {
		variable CFG_DIGITAL_GPIO_PATH
		variable CFG_DIGITAL_SENSORS_COUNT
		for {set i 0} {$i < $CFG_DIGITAL_SENSORS_COUNT} {incr i} {
			variable DIGITAL_ENABLE_$i
			set ENABLE "DIGITAL_ENABLE_$i"
			set ENABLE [subst $$ENABLE]
			if {$ENABLE == "ENABLED"} {
				variable CURRENT_STATE_$i
				variable CFG_DIGITAL_$i
				set CFG_DIGITAL "CFG_DIGITAL_$i"
				set CFG_DIGITAL [subst $$CFG_DIGITAL]
				set PATH $CFG_DIGITAL_GPIO_PATH$CFG_DIGITAL/value
				# Read the state of the sensor and compare against the old state alerts should only 
				# go out when the sensor changes state
				set NEW_STATE [exec cat $PATH]
				set CURRENT_STATE_PTR "CURRENT_STATE_$i"
				set CURRENT_STATE [subst $$CURRENT_STATE_PTR]
				if {$CURRENT_STATE != $NEW_STATE} {
					#update the current state for next time the value is tested
					set CURRENT_STATE_$i $NEW_STATE
					printInfo "Digital Sensor $i has changed state"
					variable CFG_DIGITAL_TYPE_$i
					set TYPE "CFG_DIGITAL_TYPE_$i"
					set TYPE [subst $$TYPE]
					switch $TYPE {
						DOOR_ACTIVE_HIGH {
							DOORSENSOR_ANNOUNCE $i $NEW_STATE
						}
						DOOR_ACTIVE_LOW {
							DOORSENSOR_ANNOUNCE $i !$NEW_STATE
						}
						FUEL_ACTIVE_HIGH {
							FUELSENSOR_ANNOUNCE $i $NEW_STATE
						}
						FUEL_ACTIVE_LOW {
							FUELSENSOR_ANNOUNCE $i !$NEW_STATE
						}
						default {
							printInfo "SENSOR $i is of unknown type -$TYPE"
						}
					}
				}
			}
		}		
	}
	#basic function to announce the door sensor changing status
	proc DOORSENSOR_ANNOUNCE {sensor value} {
		if {$value == 1} {
			playMsg "site_door_open"
			printInfo "Door Sensor Number $sensor indicates the door is now open"
		} else {
			printInfo "Door Sensor Number $sensor indicates the door is now closed"
		}
	}
	
	#basic function to announce the door sensor changing status
	proc FUELSENSOR_ANNOUNCE {sensor value} {
		if {$value == 1} {
			playMsg "fuel_low"
			printInfo "Fuel Sensor Number $sensor indicates the fuel is now low"
		} else {
			playMsg "fuel_restored"
			printInfo "fuel Sensor Number $sensor indicates the fuel is now filled"
		}
	}
	
	#basic function to announce the temp sensor changing status
	proc TEMPSENSOR_ANNOUNCE {sensor value} {
	}

	# Executed when this module is being deactivated.
	#
	proc deactivateCleanup {} {
		printInfo "Module deactivated"
	}
	
	# check for new events
	proc check_for_alerts {} {
		main_every_second
	}
	
	append func $module_name "::check_for_alerts";
	Logic::addTimerTickSubscriberSeconds $func;
	
	# end of namespace
}
#
# This file has not been truncated
#
