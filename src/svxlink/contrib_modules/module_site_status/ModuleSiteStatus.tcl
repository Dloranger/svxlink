namespace eval SiteStatus {
	proc printInfo {msg} {
		variable module_name
		puts "$module_name: $msg"
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
			puts [subst $$current]
			printInfo "Digital Sensor $i is enabled"
		} else {
			#set DIGITAL_ENABLE_$i "DISABLED"
			printInfo "Digital Sensor $i is not configured"
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
}
	#
	# Executed when this module is being deactivated.
	#