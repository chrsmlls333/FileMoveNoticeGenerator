global rootPath
on processProperties()
	tell application "Finder" to set rootPath to (container of (path to me)) as alias --get container folder
end processProperties

-- =================================

property actuallyCopy : false

on run
	processProperties()
	
	-- DEBUG
	--set f to {"paths"}
	--open (convertPathstoAliases(f))
	-- END DEBUG
	
	display dialog "This droplet will process files dragged onto its icon, then ask you where these files are going." & linefeed & linefeed & "A simple logfile will be created next to the origin." & linefeed & "Actual copying for you is not yet implemented." & linefeed & "Checksum validation would be nice too." & linefeed & linefeed & "This is a very exciting app." & linefeed & tab & "--Chris Mills, Artpace 2021" buttons {"Select Files", "Done"} default button 2 with title "Create Notice for Moved Files"
	if the button returned of the result is "Select Files" then
		set input to choose file with prompt "Please select some files to relocate:" with multiple selections allowed
		set output to choose folder with prompt "Please select an output folder:"
		set logDest to ""
		
		tell application "Finder"
			repeat with i from 1 to the count of input
				set this_item to item i of input
				if actuallyCopy then copy file this_item to folder output
			end repeat
			set logDest to (container of item 1 of input) as alias
		end tell
		
		log {input, output, logDest}
		
	else
		return "done"
	end if
end run

-- This droplet processes files dropped onto the applet 
on open these_items
	processProperties()
	
	set fileList to {}
	set logDest to rootPath -- default
	
	repeat with i from 1 to the count of these_items
		set this_item to item i of these_items
		set item_info to info for this_item
		set this_name to the name of the item_info
		if (folder of the item_info is true) then
			
			tell application "Finder"
				set f to entire contents of this_item
			end tell
			
			set fileList to fileList & f
		else
			set end of fileList to this_item
		end if
		tell application "Finder" to set logDest to (container of this_item) as alias
	end repeat
	
	set output to choose folder with prompt "Please select an output folder:"
	
	log {fileList, output, logDest}
	
end open





on log {fileList, destinationFolder, logFolder}
	
	-- Variables
	set appPath to the POSIX path of rootPath
	set destinationPath to POSIX path of destinationFolder
	set logPath to POSIX path of alias logFolder
	set theDate to current date
	set computerName to computer name of (system info)
	set userName to long user name of (system info)
	
	-- Collect Paths and Sort
	set pathList to {}
	repeat with thisFile in fileList
		set end of pathList to POSIX path of (thisFile as alias)
	end repeat
	set pathList to simple_sort(pathList)
	
	-- Shorten Paths (if possible)
	if (count of pathList) is greater than 1 then
		set commPath to commonPath(pathList)
		set pathList to findAndReplaceInTextList(pathList, commPath, "./")
	end if
	
	
	-- Log Text
	set txt to "Date: " & (theDate as text) & return & "Computer: " & computerName & return & "User: " & userName & return & return
	if (count of pathList) is greater than 1 then
		set txt to txt & "Source: " & return & tab & commPath & return & return
	end if
	set txt to (txt & "Contents: " & return)
	repeat with thisPath in pathList
		set txt to txt & tab & thisPath & return
	end repeat
	set txt to txt & return & "Destination: " & return & tab & destinationPath & return & return
	
	if actuallyCopy is false then set txt to txt & "The creation of this log did not copy the noted files." & return & "That should have been ensured by the user noted above."
	
	-- Escape Chars (might not be necessary using the quoted form of txt below)
	set txt to findAndReplaceInText(txt, "(", "\\(")
	set txt to findAndReplaceInText(txt, ")", "\\)")
	
	-- Create Text File
	do shell script "echo " & quoted form of txt & " > " & quoted form of (logPath & "Files Moved Notice.txt")
	
	(*
	tell application "TextEdit"
		activate
		make new document
		set theDate to current date
		set text of document 1 to txt
		save document 1 in (appPath & "File Moved.txt")
	end tell
	*)
end log



on simple_sort(my_list)
	set the index_list to {}
	set the sorted_list to {}
	repeat (the number of items in my_list) times
		set the low_item to ""
		repeat with i from 1 to (number of items in my_list)
			if i is not in the index_list then
				set this_item to item i of my_list as text
				if the low_item is "" then
					set the low_item to this_item
					set the low_item_index to i
				else if this_item comes before the low_item then
					set the low_item to this_item
					set the low_item_index to i
				end if
			end if
		end repeat
		set the end of sorted_list to the low_item
		set the end of the index_list to the low_item_index
	end repeat
	return the sorted_list
end simple_sort

on convertPathToAlias(thePath)
	tell application "System Events"
		try
			return (path of disk item (thePath as string)) as alias
		on error
			return (path of disk item (path of thePath) as string) as alias
		end try
	end tell
end convertPathToAlias

on convertPathstoAliases(thePaths)
	set output to {}
	repeat with thePath in thePaths
		set end of output to convertPathToAlias(thePath)
	end repeat
	return output
end convertPathstoAliases

to intersection of listA against listB
	local newList, a
	set newList to {}
	repeat with a in listA
		set a to contents of a -- dereference implicit loop reference
		if {a} is in listB then set end of newList to a
	end repeat
	newList
end intersection

on commonPath(pathList)
	set compareList to pathToList(item 1 of pathList)
	repeat with i from 2 to count of pathList
		set thisPath to pathToList(item i of pathList)
		set compareList to intersection of thisPath against compareList
	end repeat
	return listToPath(compareList)
end commonPath

on pathToList(p)
	set AppleScript's text item delimiters to "/"
	set theTextItems to every text item of p
	set AppleScript's text item delimiters to ""
	return theTextItems
end pathToList

on listToPath(l)
	set AppleScript's text item delimiters to "/"
	set theText to l as string
	set AppleScript's text item delimiters to ""
	set theText to theText & "/"
	return theText
end listToPath

on findAndReplaceInText(theText, theSearchString, theReplacementString)
	set AppleScript's text item delimiters to theSearchString
	set theTextItems to every text item of theText
	set AppleScript's text item delimiters to theReplacementString
	set theText to theTextItems as string
	set AppleScript's text item delimiters to ""
	return theText
end findAndReplaceInText

on findAndReplaceInTextList(theTextList, theSearchString, theReplacementString)
	set outputList to {}
	repeat with theText in theTextList
		set end of outputList to findAndReplaceInText(theText, theSearchString, theReplacementString)
	end repeat
	return outputList
end findAndReplaceInTextList



