#!/usr/bin/env bash

#################################################################################
# https://github.com/claymfischer/ontogeny
# ontogeny_columns.sh
#################################################################################

#################################################################################
# Purpose, usage and limitations						#
#################################################################################
# Purpose
# 	This will color tab-separated columns making them easier to read.
#
# 	For columns < 7, there are hand-picked high-contrast colors. 
# 	For n > 6 and n < 14, the color scheme is extended with more hand-picked colors.
# 	For n > 13, the base 13 colors are used, then random colors. There may be close overlap in color due to random chance.
#
# Usage
# 	$ colorColumns.sh file.txt
#
# Limitations
#	currently does not accept stdin (will add shortly)
# 	Seems to have trouble if columns don't have content in every cell... perhaps pipe through a simple sed 's/\t\t/\t\.\t/g' or more elegant solution
#	Needs expanded usage statement
#	Currently uses tab as delimiter, could easily add a -d flag for user override.

#################################################################################
# Config									#
#################################################################################
color25=$(echo -en "\e[38;5;25m"); 
color202=$(echo -en "\e[38;5;202m"); 
color240=$(echo -en "\e[38;5;240m"); 
bg25=$(echo -en "\e[48;5;25m"); 
bg196=$(echo -en "\e[48;5;196m"); 
reset=$(echo -en "\033[0m")

#################################################################################
# Handle input from file vs. stdin (this isn't super reliable)			#
#################################################################################
if [ -t 0 ]; then
	FILE=$1
	if [ -a "$FILE" ]; then
		printf ""
	else
        	printf "\n\n"
        	echo " ╔════════════════════════════════════════════════════════════════════════════════╗"
        	echo "   The file ${color202}$FILE$reset doesn't appear to exist."
        	echo ""

                	caseSensitive=$(shopt nocaseglob)
                	if [ "$caseSensitive" = "nocaseglob     	off" ]; then
                        	shopt -s nocaseglob; { sleep 3 && shopt -u nocaseglob & };
                	fi

                	similarfiles=$( ls -d ${FILE:0:1}* | sort | wc -l )
                	echo "	Perhaps you intended to look at one of the following $bg25$similarfiles$reset files? "
			echo "	(setting case insensitive for an instant)" 
                	echo ""
                	echo "                $ ls -d ${FILE:0:1}*$color25"
                	# some directories have a ton fo files that may match, like srr*, so let's split this up to avoid a flood.
                	if [ "$similarfiles" -lt 20 ]; then
                        	ls -d ${FILE:0:1}* | sort | sed "s/^/                /"
                	else
                        	ls -d ${FILE:0:1}* | sort | sed "s/^/                /" | head -15
                        	echo ""
                        	echo "                $white[ ... ]$color25"
                        	echo ""
                        	ls -d ${FILE:0:1}* | sort | sed "s/^/                /" | tail -15
                	fi
                	echo ""
                	echo "$reset"

        	echo " ╚════════════════════════════════════════════════════════════════════════════════╝"
        	printf "\n\n"
        	exit 0
	fi	
else
	FILE=stdin
fi

#################################################################################
# Usage statement								#
#################################################################################
if [ -z "$FILE" ]; then
	echo "
    PURPOSE: 

	Colors tab-separated (columnar) text, making it easier to read.

    USAGE:

	$ columns file.txt

	$ cat file.txt | columns
"
	exit 0
fi

if [ "$FILE" != "stdin" ]; then
	COLS=$(awk -F'\t' '{print NF}' $FILE | sort -nu | tail -n 1) # in case there are varying column counts, let's grab the top
	MINCOLS=$(awk -F'\t' '{print NF}' $FILE | sort -rnu | tail -n 1) # in case there are varying column counts, we may want to exit
fi

#################################################################################
# Main output									#
#################################################################################

	#########################################################################
	# shuffle our colors. 
	#########################################################################
	# Let's start with very different colors to maintain contrast between matches
	BASECOLORS="117 202 106 196 25 201"
	#EXTENDEDCOLORS="240 99 22 210 81 203 105"
	EXTENDEDCOLORS="240 99 64 214 86 210 67"
	# This will extend the colors. This way we avoid colors too similar if only a few search terms, but have a lot of color variety with many search terms
	if [ "$COLS" -lt "7" ]; then
		array=( $(echo "$BASECOLORS" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )
	elif [ "$COLS" -lt "14" ] && [ "$COLS" -gt "6" ]; then
		array=( $(echo "$BASECOLORS $EXTENDEDCOLORS" | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )
	else
		NEEDEDCOLORS=$((COLS-12))
		FULLCOLORS=$(shuf -i 17-240 -n $NEEDEDCOLORS)
		array=( $(printf "$BASECOLORS $EXTENDEDCOLORS " | tr '\n' ' ' | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " "; echo " $FULLCOLORS" | tr '\n' ' ' | sed -r 's/(.[^;]*;)/ \1 /g' | tr " " "\n" | shuf | tr -d " " ) )
	fi
	# Implication here is that the high-contrast colors will appear on the far right, not at left. Could pass to tail and -R...
	#########################################################################
	# initialize stuff for a loop						#
	#########################################################################
	i=1 # Set to 1 if you want first column colored
	COL=1
	COUNTER=$COLS
	COMMAND=""
	#########################################################################
	# a very simple way to color is with grep, and it's fast, so scalable!	#
	#########################################################################
	while [ "$COUNTER" -gt "1" ]; do
		color=${array[i]}
		COMMAND="GREP_COLOR='00;38;5;$color' grep --color=always \$'\(\t[^\t]*\)\{$COL\}\$' | $COMMAND "
		((COUNTER--))
		((COL++))
		((i++))
	done	
	#########################################################################
	# Set up our command loop						#
	#########################################################################
	color=${array[i]} 
	# This is here in case we want the first column colored
	# COMMAND="cat $FILE | $COMMAND GREP_COLOR='00;38;5;$color' grep --color=always '.*' | sed 's/^//g'"
	# COMMAND="cat $FILE | $COMMAND sed 's/^//g'"
	COMMAND="cat $FILE | $COMMAND GREP_COLOR='00;38;5;$color' grep --color=always '.*' | sed 's/^//g'"

	#########################################################################
	# Format and execute							#
	#########################################################################
#	if [ "$COLS" == "$MINCOLS" ]; then
		# Print out column numbers with header, just in case someone cares...
		echo "$color240"
		cat $FILE | awk -F'\t' ' { for (i=1; i <=NF; ++i) printf "%s [" i "]\t", $i; exit }'
		echo "$reset"
		# Execute the simple grep loop from above
		echo 
		eval $COMMAND
		echo
		echo $reset
#	else
#		echo 
#		echo "$bg196 Error with file $reset"
#		echo
#		echo "The file $FILE does not appear to have a consistent number of columns in each row." 
#		echo "The max number of columns we found is $COLS and the minimum number of columns is $MINCOLS."
#		echo
#	fi

