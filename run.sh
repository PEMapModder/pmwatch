#!/bin/bash

printDate(){
	echo -n `date +'[%d/%m/%y %H:%M:%S] '`
}

while true; do
	mkdir -p artifacts/pr 2>/dev/null
	printDate; echo Checking for updates...
	COMMITS=$(wget -O - --header="Authorization: bearer $(cat /GITHUB_TOKEN)" --header="User-Agent: PocketMine-MP-Compiler pmt.mcpe.me" https://api.github.com/repos/PocketMine/PocketMine-MP/events 2>/dev/null | php scanBranches.php)
	while IFS= read -r line; do
		if [ -z "$line" ]; then
			break
		fi
		BRANCH=$(echo $line | tr ":" "\n" | head -n 1)
		if [ "$BRANCH" == "pr" ]; then
			PR_ID=$(echo $line | tr ":" "\n" | sed '2!d')
			REMOTE=$(echo $line | tr ":" "\n" | sed '3!d' | tr ";" ":")
			SHA=$(echo $line | tr ":" "\n" | sed '4!d')
			printDate; echo Building pull request...
			echo "==="
			echo "Pull Request: #$PR_ID"
			echo "Remote:       $REMOTE"
			echo "SHA:          $SHA"
			rm -rf clone 2>/dev/null
			mkdir clone
			cd clone
			printDate; echo Cloning...
			(git clone "$REMOTE" . && git submodule update --init --recursive) 2>/dev/null >/dev/null
			printDate; echo Checking out this version...
			((git checkout "$SHA" && git submodule update) 3>&1 1>&2- 2>&3-) | tail -n 1
			printDate; echo Preprocessing...
			php /PreProcessor/PreProcessor.php --path . --multisize | tr "\n" "\r"
			printDate; echo Optimizing...
			php /PreProcessor/CodeOptimizer.php --path . | tr "\n" "\r"
			printDate; echo Compiling...
			PHAR_OUT=$(php ../compile.php --out "../artifacts/pr/$PR_ID".phar --from "./")
			printDate; echo $PHAR_OUT
			cd ..
			continue
		fi
		SHA=$(echo $line | tr ":" "\n" | tail -n 1)
		printDate; echo Creating new version...
		echo "==="
		echo "Branch: $BRANCH"
		echo "SHA:    $SHA"
		rm -rf clone 2>/dev/null
		mkdir clone
		cd clone
		printDate; echo Cloning...
		(git clone https://github.com/PocketMine/PocketMine-MP.git . && git submodule update --init --recursive) 2>/dev/null >/dev/null
		printDate; echo Checking out this version...
		((git checkout "$SHA" && git submodule update) >/dev/null 2>&1) | tail -n 1
		printDate; echo Preprocessing...
		php /PreProcessor/PreProcessor.php --path . --multisize | tr "\n" "\r"
		printDate; echo Optimizing...
		php /PreProcessor/CodeOptimizer.php --path . | tr "\n" "\r"
		printDate; echo Compiling...
		PHAR_OUT=$(php ../compile.php --out "../artifacts/$BRANCH".phar --from "./")
		printDate; echo $PHAR_OUT
		cd ..
	done <<< "$COMMITS"
	printDate; echo Next check will be continued 5 minutes later
	sleep 300
done

