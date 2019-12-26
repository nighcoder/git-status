#!/bin/env bash

rem_missing=
rem_sync=🔁️
rem_ahead=⏪️
rem_behind=⏩️
rem_diverged=🔀️
prebranch="🌿"
postbranch=
prestaged="🗃️ #[fg=colour46 bold]"
preunstaged="🚧️#[fg=colour124 bold]"
premerge="💥️#[fg=colour52 bold]"
prestashed="📦️#[fg=colour183 bold]"
clr=✅️

# formatstr = remote_status + pre_branch_str + branch_name + post_branch_str + work_tree_status
formatstr="%s$prebranch%s$postbranch%s"
cd "$1"
values=$(git status --porcelain -b 2>&1) || exit $?

branch=$(echo "$values" | sed -n 's|^## \(.\+\)$|\1| p' | sed 's|\.\.\..\+$||g; s|No commits yet on||g')

remote_status () {
	local rem_dir
	if [[ "$1" =~ "..." ]]; then
		if [[ "$1" =~ \[.+\] ]]; then
			# Catch the text inside the [ ] 
			rem_dir=$(echo "$1" | sed 's|.\+\s\[\(.\+\)\]$|\1|')
			if [[ "$rem_dir" =~ ahead ]]; then
				if [[ "$rem_dir" =~ behind ]]; then
					echo "$rem_diverged"
				else
					echo "$rem_ahead"
				fi
			elif [[ "$rem_dir" =~ behind ]]; then
				echo "$rem_behind"
			else
				return 1
			fi
		else
			echo "$rem_sync"
		fi
	else
		echo "$rem_missing"
	fi
}

work_status () {
	local istaged
	local iunstaged
	local imerge
	local istashed
	imerge=$(echo "$1" | grep "^AA\|^DD\|^U[DAU]\|^[DAU]U" | wc -l)
	istaged=$(echo "$1" | grep "^[MADRC] " | wc -l)
	iunstaged=$(echo "$1" | grep -v "^AA\|^DD" | grep "^??\|^[ MADRC][MADRC]" | wc -l)
	istashed=$(git stash list | wc -l)
	(( "$istaged" )) && echo -n "$prestaged$istaged"
	(( "$iunstaged" )) && echo -n "$preunstaged$iunstaged"
	(( "$imerge" )) && echo -n "$premerge$imerge"
	(( "$istashed" )) && echo -n "$prestashed$istashed"
	(( "$istaged$iunstaged$imerge$istashed" )) || echo -n "$clr"
	echo
}


printf "$formatstr" "$(remote_status "$(echo "$values" | head -n1)")" "$branch" "$(work_status "$(echo "$values" | sed -n "2,$ p")")"
