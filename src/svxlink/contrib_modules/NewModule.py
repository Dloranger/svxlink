# This script is used to create the basic framework need for building new modules
# for the SVXlink application.  This implementation is tuned for OpenRepeater Paths by default

import os
import time 


###### SETUP VARIABLE FIELDS #######################
OpenRepeater = 0

ModuleName = "HelloWorld1" #update to whatever you want your module called
DTMFCODE="100"  #define what DTMF code will activate the module

#STEP1 VARIABLES
if OpenRepeater:
	OldConfigPath="/etc/openrepeater/svxlink/svxlink.conf"
	NewConfigPath="/etc/openrepeater/svxlink/svxlink.new"
else:
	OldConfigPath="/etc/svxlink/svxlink.conf"
	NewConfigPath="/etc/svxlink/svxlink.new"
#STEP2 VARIABLES
TIMEOUT = "300" #seconds unitl module times out automatically
if OpenRepeater:
	confPath= "/etc/openrepeater/svxlink/svxlink.d/Module"
else:
	confPath= "/etc/svxlink/svxlink.d/Module"
#STEP3 VARIABLES
ModuleExamplePath="/usr/share/svxlink/modules.d/ModuleTcl.tcl.example"
ModuleConfPath="/usr/share/svxlink/modules.d/"

#STEP4 VARIABLES
tclExamplePath="/usr/share/svxlink/events.d/Tcl.tcl.example"
tclDestinationPath="/usr/share/svxlink/events.d/"
#---------------------------------------------------
print ("#Step 1 - Add new Module to the svxlink.conf modules to load")

OldConfig =open(OldConfigPath,'r')
OldConfigContent=OldConfig.read()
#now that its read in, lets rename the config file for safety
OldConfig.close
os.rename(OldConfigPath, OldConfigPath[:-4]+"backup")
NewConfig =open(NewConfigPath,'w+')
loc=OldConfigContent.index('RepeaterLogic') #Find the repeater logic section
loc=OldConfigContent.find('MODULES',loc)   #Find the modules line
loc=OldConfigContent.find(chr(10),loc)          #Find the newline location

#lets build the new config file
NewConfig.write(OldConfigContent[:loc]) # get everything up to the new line character
if OldConfigContent.find(ModuleName) == -1: # only add if not preexisting
	NewConfig.write(',Module'+ModuleName) # add the new module name
	print("	Module:" +ModuleName+" added to svxlink.conf file")
else:
	print("	Module:"+ModuleName+" already exists in the config file")
NewConfig.write(OldConfigContent[loc:]) #add the remainder of the old file
NewConfig.close
os.rename(NewConfigPath, NewConfigPath[:-4]+".conf")

#---------------------------------------------------
print ("#Step 2 - Create module conf file")
#open the file for writing
conf=open(confPath+ModuleName+".conf","w+")
conf.write("[Module"+ModuleName+"]"+chr(10))
conf.write("NAME="+ModuleName+chr(10))
conf.write("PLUGIN_NAME=Tcl"+chr(10))
conf.write("ID="+DTMFCODE+chr(10))
conf.write("TIMEOUT="+TIMEOUT+chr(10))
#Close the file
conf.close
#---------------------------------------------------
print ("#Step 3 - Create modules.d tcl file")
source=open(ModuleExamplePath,"r")
copy=open(ModuleConfPath+"Module"+ModuleName+".tcl","w+")
data=source.read()
loc=data.find('namespace eval Tcl') # find the text to change
copy.write(data[:loc])  #write the first section we want to keep
copy.write("namespace eval "+ModuleName +" {") # write the updated content
loc=data.index(chr(10),loc)          #Find the newline location
copy.write(data[loc:])  # write the last part we want to keep
copy.close
source.close
#---------------------------------------------------
print ("#Step 4 - Create events.d TCL script")
example=open(tclExamplePath,"r")
data=example.read()
target=open(tclDestinationPath+ModuleName+".tcl","w+")

loc=data.find('namespace eval Tcl') # find the text to change
target.write(data[:loc])  #write the first section we want to keep
target.write("namespace eval "+ModuleName+" {") # write the updated content
loc=data.index(chr(10),loc)          #Find the newline location
target.write(data[loc:])  # write the last part we want to keep

example.close
target.close



