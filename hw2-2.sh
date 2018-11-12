
#test if timetable exists, if not then download it
test -e courses.json&&echo "exist" ||  curl 'https://timetable.nctu.edu.tw/?r=main/get_cos_list' --data 'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crs name=**&m_teaname=**&m_cos_id=**&m_cos_code=**&m_crstime=**&m_crsoutline=**&m_costype=**' >> courses.json 

test -e cosTimeName.txt&&echo "txt exists" || (cat courses.json  | grep -o '\"cos_time\":\"[^\"]*\"\|\"cos_ename\":\"[^\"]*\"' | tr "\n" " " | grep -o '\"cos_time\":\"[^\"]*\" "cos_ename\":\"[^\"]*\"' | tr ":" " " | tr -d "\"" | sed -e 's/ cos_ename /-/' -e 's/cos_time //' | tr -d " " > cosTimeName.txt)


# Define the dialog exit status code
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

# Define the number of classes
: ${M=2}
: ${N=3}
: ${A=4}
: ${B=5}
: ${C=6}
: ${D=7}
: ${X=8}
: ${E=9}
: ${F=10}
: ${G=11}
: ${H=12}
: ${Y=13}
: ${I=14}
: ${J=15}
: ${K=16}
: ${L=17}

#trap "rm $OUTPUT; exit" SIGHUP SIGINT SIGTERM

#tmp file for add courses / option
test -d tmp || mkdir tmp
ADDED="Added"
NOTADD="tmp/Notadd.txt"
ADD="tmp/Add"
OPTION="Option"
CHOSEN="Chosen.txt"
TIME="tmp/Time"
TMP="tmp.txt"
CREATETABLE="tmp/Createtable"
TMP2="tmp/tmp.txt"
B4CHOSEN="tmp/BChosen.txt"
SHOW="tmp/show.txt"



trap "rm -r tmp" EXIT




createTable(){
	test -e $CHOSEN || printf "x 1____ 2____ 3____ 4____ 5____ 6____ 7____\nM _____ _____ _____ _____ _____ _____ _____ \nN _____ _____ _____ _____ _____ _____ _____\nA _____ _____ _____ _____ _____ _____ _____\nB _____ _____ _____ _____ _____ _____ _____\nC _____ _____ _____ _____ _____ _____ _____\nD _____ _____ _____ _____ _____ _____ _____\nX _____ _____ _____ _____ _____ _____ _____\nE _____ _____ _____ _____ _____ _____ _____\nF _____ _____ _____ _____ _____ _____ _____\nG _____ _____ _____ _____ _____ _____ _____\nH _____ _____ _____ _____ _____ _____ _____\nY _____ _____ _____ _____ _____ _____ _____\nI _____ _____ _____ _____ _____ _____ _____\nJ _____ _____ _____ _____ _____ _____ _____\nK _____ _____ _____ _____ _____ _____ _____\nL _____ _____ _____ _____ _____ _____ _____\n" | column -t >$CHOSEN
	cat $CHOSEN > $SHOW
	while read line; do
		if [ $line == "op1" ] ;	then
			OP1=0

		elif [ $line == "op2" ] ; then
			OP2=0
		fi
	done <$OPTION

	if [ $OP1 -eq 0 ];	then
		sed -r -e 's/([0-9][A-Z]+)+-//g' $CHOSEN | sed -r -e 's/-[^ ]+//g' > $CREATETABLE
	else
		sed -r -e 's/(([0-9]*[A-Z]*,*)+-)+//g' $CHOSEN > $CREATETABLE
	fi

	if [ $OP2 -eq 0 ];	then
		#delete the extra columns and rows
		awk '{
			if(NR!=2 && NR!=3 && NR!=8 && NR!=13){
				printf $1 " " $2 " " $3 " " $4 " " $5 " " $6 "\n"
			}
	}' $CREATETABLE | column -t | awk '{print $0 "\n\n\n"}' > $SHOW
	else
		column -t $CREATETABLE | awk '{print $0 "\n\n\n"}' > $SHOW
	fi
}


#to see if there is collision
testCollision(){
	while read line
	do	
		case $line in
			[0-9])
				colNum=`expr "$line" + 1`
				;;

			[A-Z])
				eval rowNum=\$$line
				ENABLE=$(awk -v col=$colNum -v row=$rowNum 'NR==row{if($col=="_____") {printf 0} else {printf 1}}' $CHOSEN)
				if [ $ENABLE -ne $DIALOG_OK ] ; then
					break
				fi
				;;

			*)
				;;

		esac

	done <$TIME

}

addCoursesToTable(){
		while read line
		do	
			
			case $line in
				[0-9])
					colNum=`expr "$line" + 1`
					;;

				[A-Z])
					eval rowNum=\$$line
				
					awk -v col=$colNum -v row=$rowNum -v add=$1 '{if(NR!=row) {printf $0 "\n"} else {$col=add;printf $0 "\n"}}' $CHOSEN > $TMP && mv $TMP $CHOSEN
					;;
	
				*)
					;;

			esac
	
		done <$TIME
}

createNotadd(){
	cat cosTimeName.txt > $NOTADD

	while read line
	do
		cat $NOTADD | sed '/'"${line}"'/d' > $TMP2 && mv $TMP2 $NOTADD
	done < $ADDED
}


addCourses(){
	
	createNotadd


	dialog	--buildlist "Add courses." 100 100 100 \
		$(awk '{printf $1 " " $1 " off" "\n"}' $NOTADD) $(awk '{printf $1 " " $1 " on" "\n"}' $ADDED)  2>$ADD
	
	result=$?
	grep -oE "[^ \"]+" $ADD > $TMP2 && mv $TMP2 $ADD

	if [ $result -eq $DIALOG_OK ] ; then
		cat $CHOSEN > $B4CHOSEN
		printf "x 1____ 2____ 3____ 4____ 5____ 6____ 7____\nM _____ _____ _____ _____ _____ _____ _____ \nN _____ _____ _____ _____ _____ _____ _____\nA _____ _____ _____ _____ _____ _____ _____\nB _____ _____ _____ _____ _____ _____ _____\nC _____ _____ _____ _____ _____ _____ _____\nD _____ _____ _____ _____ _____ _____ _____\nX _____ _____ _____ _____ _____ _____ _____\nE _____ _____ _____ _____ _____ _____ _____\nF _____ _____ _____ _____ _____ _____ _____\nG _____ _____ _____ _____ _____ _____ _____\nH _____ _____ _____ _____ _____ _____ _____\nY _____ _____ _____ _____ _____ _____ _____\nI _____ _____ _____ _____ _____ _____ _____\nJ _____ _____ _____ _____ _____ _____ _____\nK _____ _____ _____ _____ _____ _____ _____\nL _____ _____ _____ _____ _____ _____ _____\n" | column -t >$CHOSEN

		while read addline;	do
			echo $addline | grep -oE "[0-9][A-Z]+" | grep -oE "[A-Z|[0-9]" > $TIME
			testCollision 
			if [ $ENABLE -eq 0 ] ; then
				addCoursesToTable $addline
			else
				cat $B4CHOSEN > $CHOSEN
				dialog	--msgbox \
					"Collision happened!"  10 50 
				break
			fi

		done <$ADD
		if [ $ENABLE -eq 0 ]; then
			cat $ADD | tr -d "\\" > $ADDED
		else
			cat $ADD | tr -d "\\" > $ADDED
			addCourses
		fi
	fi
	
	timeTable
	
}

spareTime(){

	createNotadd

	while read addline; do
		echo $addline | grep -oE "[0-9][A-Z]+" | grep -oE "[A-Z|[0-9]" > $TIME

		while read line; do
			case $line in
				[0-9])
					colNum=`expr "$line" + 1`
					;;

				[A-Z])
					eval rowNum=\$$line
					ENABLE=$(awk -v col=$colNum -v row=$rowNum 'NR==row{if($col=="_____") {printf 0} else {printf 1}}' $CHOSEN)
					if [ $ENABLE -ne $DIALOG_OK ] ; then
						break
					fi
					;;

				*)
					;;

			esac
		done < $TIME
		
		if [ $ENABLE -eq $DIALOG_OK  ] ; then
			echo $addline >> $TMP2
		fi

	done < $NOTADD

	mv $TMP2 $NOTADD

	dialog	--buildlist "Add courses." 100 100 100 \
		$(awk '{printf $1 " " $1 " off" "\n"}' $NOTADD) $(awk '{printf $1 " " $1 " on" "\n"}' $ADDED)  2>$ADD
	
	result=$?
	grep -oE "[^ \"]+" $ADD > $TMP2 && mv $TMP2 $ADD

	if [ $result -eq $DIALOG_OK ] ; then
		cat $CHOSEN > $B4CHOSEN
		printf "x 1____ 2____ 3____ 4____ 5____ 6____ 7____\nM _____ _____ _____ _____ _____ _____ _____ \nN _____ _____ _____ _____ _____ _____ _____\nA _____ _____ _____ _____ _____ _____ _____\nB _____ _____ _____ _____ _____ _____ _____\nC _____ _____ _____ _____ _____ _____ _____\nD _____ _____ _____ _____ _____ _____ _____\nX _____ _____ _____ _____ _____ _____ _____\nE _____ _____ _____ _____ _____ _____ _____\nF _____ _____ _____ _____ _____ _____ _____\nG _____ _____ _____ _____ _____ _____ _____\nH _____ _____ _____ _____ _____ _____ _____\nY _____ _____ _____ _____ _____ _____ _____\nI _____ _____ _____ _____ _____ _____ _____\nJ _____ _____ _____ _____ _____ _____ _____\nK _____ _____ _____ _____ _____ _____ _____\nL _____ _____ _____ _____ _____ _____ _____\n" | column -t >$CHOSEN

		while read addline;	do
			echo $addline | grep -oE "[0-9][A-Z]+" | grep -oE "[A-Z|[0-9]" > $TIME
			testCollision 
			if [ $ENABLE -eq 0 ] ; then
				addCoursesToTable $addline
			else
				cat $B4CHOSEN > $CHOSEN
				dialog	--msgbox \
					"Collision happened!"  10 50 
				break
			fi

		done <$ADD
		if [ $ENABLE -eq 0 ]; then
			cat $ADD | tr -d "\\" > $ADDED
		else
			cat $ADD | tr -d "\\" > $ADDED
			spareTime
		fi
	fi
	
	timeTable
	
}

inputBox(){
	dialog --inputbox "Please enter the course name." 10 50 2>$TMP

	string=$(cat $TMP)
	rm $TMP

	searchName

}

searchName(){

	createNotadd

	grep -oE "[^ ]+${string}[^ ]+" $NOTADD > $TMP2 && mv $TMP2 $NOTADD


	dialog	--buildlist "Add courses." 100 100 100 \
		$(awk '{printf $1 " " $1 " off" "\n"}' $NOTADD) $(awk '{printf $1 " " $1 " on" "\n"}' $ADDED)  2>$ADD
	
	result=$?
	grep -oE "[^ \"]+" $ADD > $TMP2 && mv $TMP2 $ADD

	if [ $result -eq $DIALOG_OK ] ; then
		cat $CHOSEN > $B4CHOSEN
		printf "x 1____ 2____ 3____ 4____ 5____ 6____ 7____\nM _____ _____ _____ _____ _____ _____ _____ \nN _____ _____ _____ _____ _____ _____ _____\nA _____ _____ _____ _____ _____ _____ _____\nB _____ _____ _____ _____ _____ _____ _____\nC _____ _____ _____ _____ _____ _____ _____\nD _____ _____ _____ _____ _____ _____ _____\nX _____ _____ _____ _____ _____ _____ _____\nE _____ _____ _____ _____ _____ _____ _____\nF _____ _____ _____ _____ _____ _____ _____\nG _____ _____ _____ _____ _____ _____ _____\nH _____ _____ _____ _____ _____ _____ _____\nY _____ _____ _____ _____ _____ _____ _____\nI _____ _____ _____ _____ _____ _____ _____\nJ _____ _____ _____ _____ _____ _____ _____\nK _____ _____ _____ _____ _____ _____ _____\nL _____ _____ _____ _____ _____ _____ _____\n" | column -t >$CHOSEN

		while read addline;	do
			echo $addline | grep -oE "[0-9][A-Z]+" | grep -oE "[A-Z|[0-9]" > $TIME
			testCollision 
			if [ $ENABLE -eq 0 ] ; then
				addCoursesToTable $addline
			else
				cat $B4CHOSEN > $CHOSEN
				dialog	--msgbox \
					"Collision happened!"  10 50 
				break
			fi

		done <$ADD
		if [ $ENABLE -eq 0 ]; then
			cat $ADD | tr -d "\\" > $ADDED
		else
			cat $ADD | tr -d "\\" > $ADDED
			searchName
		fi
	fi
	
	timeTable



}



#options to display the time table
option(){
	echo "_" >> $OPTION
	
	if [ $OP1 -eq 0 ]; then
		echo "op1" >> $OPTION
	fi

	if [ $OP2 -eq 0 ]; then
		echo "op2" >> $OPTION
	fi

	dialog --checklist "Option" 10 50 30\
		op1 "Show classroom" $(awk 'BEGIN{op1=1} {if($1=="op1") op1 = 0;} END{if(op1==0) printf "on"; else printf "off"}' $OPTION) \
		op2 "Hide extra column" $(awk 'BEGIN{op2=1} {if($1=="op2") op2 = 0;} END{if(op2==0) printf "on"; else printf "off"}' $OPTION) 2>$OPTION
	
	result=$?
	grep -oE "[a-z]+[0-9]"	$OPTION > $TMP2 && mv $TMP2 $OPTION
	echo "_" >> $OPTION

	if [ $result -eq $DIALOG_OK ]; then
		OP1=1
		OP2=1
	fi

	timeTable
}

wayToChoose(){
	dialog  --menu "choose one way to add courses." 20 30 30 \
		op1	"All courses" \
		op2	"Spare Time" \
		op3	"Search course name" 2>$TMP
	result=$?

	op=$(cat $TMP)
	rm $TMP

	if [ $result -eq $DIALOG_OK ]; then
		if [ $op == "op1" ]; then
			addCourses
		elif [ $op == "op2" ]; then
		       	spareTime	
	       	elif [ $op == "op3" ]; then
			inputBox	
	        fi
	else
		timeTable
	fi
		
}



timeTable(){
	createTable



	dialog	--title "Time Table" --help-button --help-label "Exit" \
		--ok-label "Add course" --extra-button --extra-label "Options" \
      		--textbox \
		$SHOW 75 150 

	result=$?

	if [ $result -eq $DIALOG_OK ]
       	then
		wayToChoose
	elif [ $result -eq $DIALOG_EXTRA ]
	then
		option
	else
		exit 1
	fi
}

timeTable


deleteCourses(){
		grep -oE "[0-9][A-Z]+" $ADDED | grep -oE "[A-Z|[0-9]" > $TIME
			cat $CHOSEN | sed -e 's/'"${ENABLE}"'/_/' -e 's/'"${ENABLE}"'/_/' -e 's/'"${ENABLE}"'/_/' -e 's/'"${ENABLE}"'/_/' -e 's/'"${ENABLE}"'/_/' -e 's/'"${ENABLE}"'/_/' -e 's/'"${ENABLE}"'/_/'  > $TMP && mv $TMP $CHOSEN
}


       	#sed 's/\"cos_ename\":\"[^\"]*\"/&\n/'
	#find the course name'
