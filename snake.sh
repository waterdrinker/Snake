#!/bin/bash

# user set
wall="[X]"
head="[\033[1;33m@\033[0m]"
body="[\033[1mo\033[0m]"
goal="<\033[1mo\033[0m>"
#goal="\033[33m<o>"

# speed range: 0-9, the smaller the faster
speed=4

# screen size
width=$(tput cols)
height=$(tput lines)
((width=width/3))
((height=height-2)) # border 

# default snake head position
((hx=width/2))
((hy=height/2))

# signal
SigLeft=20
SigDown=21
SigUp=22
SigRight=23
SpeedDown=24
SpeedUp=25
sig=0

# calculate the X position (3 charactors for 1 unit)
CalX() { echo $((${1}*3-2)); }

RegisterSignal()
{
	trap "sig=$SigLeft;" $SigLeft
	trap "sig=$SigDown;" $SigDown
	trap "sig=$SigUp;"   $SigUp
	trap "sig=$SigRight;" $SigRight
	trap "sig=$SpeedDown;" $SpeedDown
	trap "sig=$SpeedUp;" $SpeedUp

}

RandomGoal()
{                             
	local x y v
	while true
	do
		((x=RANDOM%(width-2)+2))
		((y=RANDOM%(height-2)+2))
		v=${coords[$(Coord2Key $x $y)]}
		if [[ $v -eq 0 ]];then
         	coords[$(Coord2Key $x $y)]=2
			x=$(CalX $x)
         	echo -ne "\033[$y;${x}H${goal}\033[0m"
    	    break
		fi
   done
}

DrawBox()
{
	local i x
	for((i=1;i<=width;i+=1))  
	do
		x=$(CalX $i) # 1, 4, 7, ... width*3-2
		echo -ne "\033[1;${x}H\033[45m$wall\033[0m"
		echo -ne "\033[$height;${x}H\033[45m$wall\033[0m"
	done
	
	#x=$(CalX $width)
	for((i=2;i<height;i+=1))
	do
		echo -ne "\033[$i;1H\033[45m$wall\033[0m"
		echo -ne "\033[$i;${x}H\033[45m$wall\033[0m"
	done
}	

GameOver()
{
	echo -en "\033[$((height/2));$((width/2*3-3))H\033[1mGame Over\033[0m"
	kill $PPID
	echo -en "\033[$((height+1));36H\033[0m"
	exit 0
}

Coord2Key()
{
   local x y max
   max=100
   x=$1
   y=$2
   ((x+=max))
   ((y+=max))
   echo $x$y
}

InitCoordinate()
{
	local i j
	for((i=2;i<width;i++))
	do
		for((j=2;j<height;j++))
		do
			coords[$(Coord2Key $i $j)]=0
		done
	done
}
# score=n: @ 1 2 ... n-1 n
TheSnake() 
{
	local i
	case "$1" in
		eat)
			((score++))  # trick: the one's xy value will be add in "TheSnake move" 
			TheSnake move
			;;
		getx)
			echo ${snakex[$2]}
			;;
		move)
			for((i=score;i>0;i--))
			do
				snakex[i]=${snakex[i-1]}
				snakey[i]=${snakey[i-1]}
			done
			snakex[0]=$hx
			snakey[0]=$hy
			;;
		p)
			for((i=1;i!=score+1;i++))
			do
				echo -ne "\033[${snakey[$i]};$(CalX ${snakex[$i]})H${body}\033[0m" 
			done
			echo -ne "\033[$hy;$(CalX $hx)H$head\033[0m"
			;;
		erase)
			;;
	esac
}

Coord2Key()
{
   local x y max
   max=100
   x=$1
   y=$2
   ((x+=max))
   ((y+=max))
   echo $x$y
}

MoveOneStep()
{
	lastmove=${1}
	v=${coords[$(Coord2Key $hx $hy)]}
	if test $v -eq 0; then 
		echo -en "\033[${snakey[score]};$(CalX ${snakex[score]})H   \033[0m" #erase the last cube
		coords[$(Coord2Key ${snakex[score]} ${snakey[score]})]=0
		coords[$(Coord2Key $hx $hy)]=1
		TheSnake move
	elif test $v -eq 1; then 
		GameOver
	elif test $v -eq 2; then # snake eat	
		TheSnake eat
		RandomGoal
	echo -e "\033[$((height+1));2H [ Score: $score ] [ Speed: $speed ]\033[0m"
	fi
	TheSnake p	
}

Init()
{
	score=0
	DrawBox
	InitCoordinate
	coords[$(Coord2Key $hx $hy)]=1
	echo -ne "\033[$hy;$(CalX $hx)H$head\033[0m"
	lastmove=0

	# eat the head
	snakex[score]=$hx
	snakey[score]=$hy

	RandomGoal
	RandomGoal
	RandomGoal
	echo -e "\033[$((height+1));2H [ Score: $score ] [ Speed: $speed ]\033[0m"
}

ReciveSignal()
{
	local i=0
	Init
	RegisterSignal
    echo -ne "\033[?25l"   
	while true
	do
		if [[ $sig -eq $((43-$lastmove)) && $score -ne 0 ]]; then  #
			sig=$lastmove   # Bugfix. Go on the formal direction
		fi
		case "$sig" in
			"$SigLeft")
				[[ $((--hx)) -eq 1 ]] && GameOver
				MoveOneStep $sig
				sig=0
				;;
			"$SigDown")
				[[ $((++hy)) -eq $height ]] && GameOver
				MoveOneStep $sig
				sig=0
				;;
			"$SigUp")
				[[ $((--hy)) -eq 1 ]] && GameOver
				MoveOneStep $sig
				sig=0
				;;
			"$SigRight")
				[[ $((++hx)) -eq $width ]] && GameOver
				MoveOneStep $sig
				sig=0
				;;
			"$SpeedUp")
				((speed= speed<9 ?speed+1:speed))
				sig=0
				i=0
				echo -e "\033[$((height+1));2H [ Score: $score ] [ Speed: $speed ]\033[0m"
				;;
			"$SpeedDown")
				((speed= speed>0 ?speed-1:speed))
				sig=0
				i=0
				echo -e "\033[$((height+1));2H [ Score: $score ] [ Speed: $speed ]\033[0m"
				;;
		esac
		if test $i -eq $speed; then # speed control
			sig=$lastmove   # snake auto moving. At first lastmove is 0 need trigger.
			((i=0))
		fi
		((i++))
		sleep 0.05  # avoid 100% CPU use
	done
}

KillSignal()
{
	local key
	while true
	do
		read -s -n 1 key
		case $key in
			H|h)
				kill -$SigLeft $1	
				;;
			J|j)
				kill -$SigDown $1
				;;
			k|k)
				kill -$SigUp $1
				;;
			L|l)
				kill -$SigRight $1
				;;
			"[")
				kill -24 $1
				;;
			"]")
				kill -25 $1
				;;
			Q|q)
				kill -9 $1
				exit 0
				;;
		esac
	done
}

clear

if [[ "$1" = "--show" ]]; then
	ReciveSignal
else
	bash $0 --show &
	KillSignal $!
fi

