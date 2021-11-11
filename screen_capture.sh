#!/usr/bin/env bash

# Acknowledgement
# Thanks to [@FriendlyTester](https://gist.github.com/FriendlyTester) for his well documented script to capture Android: https://gist.github.com/FriendlyTester/67c7ad26ab62849aea91
# Thanks to [@Alexander Klimetschek](https://unix.stackexchange.com/users/219724/alexander-klimetschek) for his super cool option selection script: https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu/415155

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
function select_option {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function select_opt {
    select_option "$@" 1>&2
    local result=$?
    echo $result
    return $result
}

function select_opt {
    select_option "$@" 1>&2
    local result=$?
    echo $result
    return $result
}

function capture_android_video {
	# Start recording
	adb shell screenrecord /sdcard/android_demo.mp4 & 

	# Get its PID
	PID=$!

	# Upon a key press
	read -p "Press [Enter] to stop recording..."

	# Kill the recording process
	kill $PID

	# Wait for 3 seconds for the device to compile the video
	sleep 3

	# Download the video
	adb pull /sdcard/android_demo.mp4

	# Delete the video from the device
	adb shell rm /sdcard/android_demo.mp4

	# Kill background process incase kill PID fails
	trap "kill 0" SIGINT SIGTERM EXIT
}

function capture_android_screenshot {
	# Take a screenshot
	adb shell screencap /sdcard/android_demo.png 

	# Download the screenshot
	adb pull /sdcard/android_demo.png

	# Delete the video from the device
	adb shell rm /sdcard/android_demo.png
}

function capture_ios_video {
    # Start recording
    xcrun simctl io booted recordVideo ios_demo.mp4 -f & 

    # Get its PID
    PID=$!

    # Wait for 1 second for the recording to start
    sleep 1

    # Upon a key press
    read -p "Press [Enter] to stop recording..."

    # Kill the recording process
    kill -2 $PID

    # Wait for 3 seconds for the device to compile the video
    sleep 3

    # Kill background process incase kill PID fails
    trap "kill 0" SIGINT SIGTERM EXIT
}

function capture_ios_screenshot {
    # Take a screenshot
    xcrun simctl io booted screenshot ios_demo.png
}

echo "Select platform"
isAndroid=false
case `select_opt "Android" "iOS"` in
    0) isAndroid=true;;
    1) isAndroid=false;;
esac

echo "Select action"
isVideo=false
case `select_opt "Video" "Screenshot"` in
    0) isVideo=true;;
    1) isVideo=false;;
esac

if $isVideo
then
	if $isAndroid
	then
		capture_android_video
	else
		capture_ios_video
	fi
	echo "Capture video completed"
else
	if $isAndroid
	then
		capture_android_screenshot
	else
		capture_ios_screenshot
	fi
	echo "Capture screenshot completed"
fi
