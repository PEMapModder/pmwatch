#!/bin/bash

printDate(){
	echo -n `date +'[%d/%m/%y %H:%M:%S] '`
}

while true; do
	mkdir artifacts 2>/dev/null
	rm -rf clone
	printDate; echo Checking for updates...
	COMMITS=$(wget -O - --header="Authorization: bearer $(cat /GITHUB_TOKEN)" --header="User-Agent: PocketMine-MP-Compiler pmt.mcpe.me" https://api.github.com/repos/PocketMine/PocketMine-MP/events 2>/dev/null | php scanBranches.php)
	while IFS= read -r line; do
		if [ -z "$line" ]; then
			break
		fi
		BRANCH=$(echo $line | tr ":" "\n" | head -n 1)
		SHA=$(echo $line | tr ":" "\n" | tail -n 1)
		printDate; echo Creating new version...
		echo "==="
		echo "Branch: $BRANCH"
		echo "SHA:    $SHA"
		mkdir clone
		cd clone
		printDate; echo Cloning...
		(git clone https://github.com/PocketMine/PocketMine-MP.git . && git submodule update --init --recursive) 2>/dev/null >/dev/null
		printDate; echo Checking out this version...
		((git checkout "$SHA" && git submodule update )3>&1 1>&2- 2>&3-) | tail -n 1
		printDate; echo Compiling...
		PHAR_OUT=$(php ../compile.php --out "../artifacts/$BRANCH".phar --from "./")
		printDate; echo $PHAR_OUT
		cd ..
		rm -rf clone
	done <<< "$COMMITS"
	printDate; echo Next check will be continued 5 minutes later
	sleep 300
done

