* These commands ensure that there is no previous log file open and clear memory
clear
set more off 
capture log close

*** FILL IN THE GLOBAL ROOT COMMAND WITH THE FILE PATH OF YOUR FOLDER 
global root "C:\Users\12246\Downloads\thesisData"

* Point Stata to the subfolders of the folder
global logs "$root/logs"
global output "$root/output"
global temp "$root/temp"
global scripts "$root/scripts"
global input "$root/input"

* Start a log file that records all commands and output from this script
log using "$logs/thesisData.log", replace

*******************
*** Import data ***
*******************

** Opening and Cleaning Datasets **

** Begin by cleaning coaches **

import delimited "$input\coaches2023.csv", clear
drop ties losses preseasonrank postseasonrank srs spoverall spoffense spdefense
rename school home_market
duplicates tag home_market, generate(dup_tag)

gen fullseason = 1
replace fullseason = 0 if dup_tag == 1
gen games_start = 0 if fullseason == 1
gen games_end = 18 if fullseason == 1
replace games_start = 0 if fullseason == 0 & !missing(hiredate)
replace games_end = games if fullseason == 0 & !missing(hiredate)
sort home_market (games_start)
replace games_start = games_end[_n-1] + 1 if fullseason == 0 & missing(hiredate) & _n < _N
replace games_end = 18 if fullseason == 0 & missing(hiredate)
gen expand_count = games_end - games_start + 2
*replace expand_count = games + 1 if fullseason == 0 & missing(hiredate)
replace expand_count = expand_count - 1 if firstname == "Mel" & lastname == "Tucker"
expand expand_count
drop if _n <= 143

gen week = 1

replace week = week[_n-1] + 1 if home_market == home_market[_n-1]
drop if home_market == "Boise State" & week == 8
drop if home_market == "Duke" & week == 6
drop if home_market == "James Madison" & week == 6
drop if home_market == "Michigan State" & week == 6
drop if home_market == "Mississippi State" & week == 7
drop if home_market == "Oregon State" & week == 8
drop if home_market == "Syracuse" & week == 8
drop if home_market == "Texas A&M" & week == 8
drop if home_market == "Troy" & week == 8
drop if home_market == "Tulane" & week == 6
drop dup_tag fullseason games_start games_end expand_count
save "$temp\coaches2023home", replace

rename home_market away_market
save "$temp\coaches2023away", replace

import delimited "$input\2023spreads", clear
drop formattedspread
gen match = away_market + "@" + home_market
collapse (median) spread, by(match)
duplicates tag match, generate(dup_tag)
save "$temp\2023spreads_clean", replace


** Continue by merging coaches into PBP ** 

import delimited "$input\PBP Data Pull 2023 Full Season.csv", clear
drop broadcast_network temperature condition humidity wind_speed wind_direction player_name jersey height weight player_start_status type def_tackle def_ast

gen score_diff = home_pts - away_pts

gen colon_pos = strpos(start_clock, ":")  
gen minutes = real(substr(start_clock, 1, colon_pos - 1))  
gen seconds = real(substr(start_clock, colon_pos + 1, .))  
gen sec_remaining = minutes * 60 + seconds + (4 - quarter) * 15 * 60
drop colon_pos minutes seconds

sort home_market week sec_remaining
egen game_id = group(year week home_market away_market), label
gen outcome = 0
replace outcome = 1 if home_pts > away_pts & _n == 1
replace outcome = 1 if home_pts > away_pts & game_id[_n-1] != game_id & _n > 1
replace outcome = 0.5 if home_pts == away_pts & game_id[_n-1] != game_id & _n > 1
replace outcome = outcome[_n-1] if _n > 1 & game_id[_n-1] == game_id
drop game_id

gen yds_to_goal = start_yard_line if start_team != start_side
replace yds_to_goal = 100 - start_yard_line if start_team == start_side

gen has_penalty = strpos(summary, "PENALTY on ")
gen penalty_info = substr(summary, has_penalty + 11, .) if has_penalty > 0
gen dash_pos = strpos(penalty_info, "-") if has_penalty > 0
gen penalty_responsible = substr(penalty_info, 1, dash_pos - 1) if dash_pos > 0
drop has_penalty penalty_info dash_pos

unab allvars: _all
local allvars : list allvars - play_id
ds `allvars', has(type numeric)
local numvars `r(varlist)'
ds `allvars', has(type string)
local strvars `r(varlist)'
egen play_id = group(year week home_market away_market start_clock quarter)
collapse (max) `numvars' (first) `strvars', by(play_id)

gen match = away_market + "@" + home_market
merge m:1 match using "$temp\2023spreads_clean"
keep if _merge == 3
drop _merge dup_tag

sort home_market week
merge m:1 home_market week using "$temp\coaches2023home"
keep if _merge == 3
drop  _merge hiredate bye
rename firstname hcfirstname
rename lastname hclastname
rename games hcgamescoached
rename wins hcgameswon
sort away_market week
merge m:1 away_market week using "$temp\coaches2023away"
rename firstname acfirstname
rename lastname aclastname
rename games acgamescoached
rename wins acgameswon
keep if _merge == 3
drop  _merge hiredate bye

replace outcome = 0 if match == "Buffalo@Akron"
replace outcome = 0 if match == "Houston@Baylor"
replace outcome = 0 if match == "Northern Illinois@Boston College"
replace outcome = 0 if match == "Miami (OH)@Cincinnati"
replace outcome = 0 if match == "Florida State@Clemson"
replace outcome = 1 if match == "Colorado State@Colorado"
replace outcome = 0 if match == "Stanford@Colorado"
replace outcome = 1 if match == "Akron@Eastern Michigan"
replace outcome = 0 if match == "Arkansas@Florida"
replace outcome = 1 if match == "Akron@Eastern Michigan"
replace outcome = 0 if match == "Jacksonville State@Louisiana"
replace outcome = 0 if match == "Southern Miss@Louisiana"
replace outcome = 1 if match == "Alabama@Michigan"
replace outcome = 1 if match == "Arizona@Mississippi State"
replace outcome = 0 if match == "Utah State@New Mexico"
replace outcome = 1 if match == "Duke@North Carolina"
replace outcome = 1 if match == "Minnesota@Northwestern"
replace outcome = 1 if match == "BYU@Oklahoma State"
replace outcome = 0 if match == "Western Kentucky@Old Dominion"
replace outcome = 1 if match == "Houston@Rice"
replace outcome = 0 if match == "Utah State@San Diego State"
replace outcome = 1 if match == "Kansas State@Texas"
replace outcome = 0 if match == "Charlotte@Tulsa"
replace outcome = 1 if match == "Arizona@USC"
replace outcome = 1 if match == "Nebraska@Wisconsin"
replace outcome = 1 if match == "Texas Tech@Wyoming"
replace outcome = 1 if match == "Akron@Indiana"
replace outcome = 1 if match == "Boise State@Colorado State"
replace outcome = 1 if match == "Indiana@Illinois"
replace outcome = 0 if match == "Memphis@Charlotte"





export delimited using "C:\Users\12246\Downloads\thesisPython\2023PBP.csv", replace


* Close the log file
log close

*** end of file ***