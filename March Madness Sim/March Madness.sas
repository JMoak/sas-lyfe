/*where to throw the datasets of winners*/
libname out "C:\zUseful Things\March Madness Sim\Datasets";

%let type = smart;
%let prScaler = 0.2; /* scales into winning odds (prScaler = +- 1% win chance) */

%macro Main;

	%ReadData;

	%let divisions = SOUTH WEST EAST MIDWEST;

	data Round2;run;

	/*********** ROUND 1 ****************/
	%do divno = 1 %to 4;
		%let division = %scan(&divisions., &divno., " ");
		%let newmatch = 1;

		%do match=1 %to 8;
			%firstmatch(&match., &division., &newMatch.);

			%if %sysfunc(mod(&match., 2)) = 0 %then %let newmatch=%eval(&newmatch. + 1);
		%end;

		data round2 out.round2;
			set round2 &division.1-&division.8;
			if division='' then delete;
		run;

		proc datasets lib=work nolist;
			delete &division.1-&division.8;
		run; quit;
	%end;


	/* ROUND 2-4 */
	%let rounds = round3 round4 round5;
	%let prevRound = round2 round3 round4;
	%let matchcount = 4 2 1;

	%do r=1 %to 3;
		%let currRound = %scan(&rounds., &r., ' ');
		%let currpRound = %scan(&prevRound., &r., ' ');
		%let currMC = %scan(&matchCount., &r., ' ');

		data &currRound.; run;

		%do divno = 1 %to 4;
			%let division = %scan(&divisions., &divno., " ");
			%let newmatch = 1;

			%do match=1 %to &currMC.;
				%match(&match., &division., &newMatch., &currpRound.);

				%if %sysfunc(mod(&match., 2)) = 0 %then %let newMatch=%eval(&newMatch. + 1);
			%end;

			data &currRound. out.&currRound.;
				set &currRound. &division.1-&division.&currMC.;
				if division='' then delete;
			run;

			proc datasets lib=work nolist;
				delete &division.1-&division.&currMC.;
			run; quit;
		%end;
	%end;


	/**** FINAL FOUR ******/
	data round5 out.round5;
		set round5;
		
		if division in ("MIDWEST", "SOUTH") then match=2;
		division = "FINALFOUR";
	run;

	%match(1, FINALFOUR, 1, round5);
	%match(2, FINALFOUR, 1, round5);

	data round6 out.round6;
		set FINALFOUR1 FINALFOUR2;
	run;

	%match(1, FINALFOUR, 1, round6);

	data round7 out.round7;
		set FINALFOUR1;
	run;


	/******** FINAL DATASET *****************/
	data all_teams_final;
		set allteams;
			team = strip(team) || " (" || strip(rank) || ")";
	keep division team match powerrating;
	run;

	data all_teams_final;
		set all_teams_final;
	rename team=ROUND1;
	run;

	proc sort data=all_teams_final;
		by division match;
	run;

	%do r=2 %to 7;
		data round&r.;
			set round&r.;
			%if &r. > 4 %then %do;
				division = "EAST";
			%end;
		keep division team match powerrating;
		run;

		data round&r.;
			set round&r.;
		rename team=ROUND&R.;
		run;

		proc sort data=round&r; by division match;
		run;

		data all_teams_final;
			merge all_teams_final round&r.;
				by division match;
		run;
	%end;

	data out.BRACKET;
	retain match division powerrating ROUND1-ROUND7;
		set all_teams_final;
	run;


%mend Main;



%macro ReadData;
	data allteams;
	length team match division rank match1odds powerrating $100;
		infile "C:\zUseful Things\March Madness Sim\FF Bracket.csv"	firstobs=2 missover dsd;
	input team match division rank match1odds powerrating;
		division = upcase(division);
	run;

	data allteams;
		set allteams;
		match_n = match*1;
		match1odds_n = match1odds*1;
		powerrating_n = powerrating*1;
	drop match match1odds powerrating;
	rename match_n=match match1odds_n=match1odds powerrating_n=powerrating;
	run;

	/*keeping a record of the initial dataset*/
	data out.all_teams_orig;
		set allteams;
	run;
%mend ReadData;


%macro firstmatch(no, div, newmatchno);

	proc sql noprint;
		select team into :teams separated by "::" from allteams where match=&no. and division="&div.";
		select match1odds into :mo separated by "::" from allteams where match=&no. and division="&div.";
		select powerrating into :pr separated by "::" from allteams where match=&no. and division="&div.";
	quit;

	%genRand;
	
	%if &rand. < %scan(&mo., 1, "::") %then %let winner=1;
	%else %let winner=2;

	%let team = %scan(&teams., &winner., "::");
	%let prr = %scan(&pr., &winner., "::");

	data &div.&no.;
	length division team teams match1odds $100.;
		division = "&div.";
		match = &newmatchno.;
		team = "&team.";
		powerrating = &prr.;
		winner = &winner.;
		teams = "&teams.";
		match1odds = "&mo.";
	run;


%mend firstmatch;



%macro match(no, div, newmatchno, indata);
	proc sql noprint;
		select team into :teams separated by "::" from &inData. where match=&no. and division="&div.";
		select powerrating into :pr separated by "::" from &inData. where match=&no. and division="&div.";
	quit;

	%genRand;

	%let pr1 = %scan(&pr., 1, "::");
	%let pr2 = %scan(&pr., 2, "::");

	data _null_;
		t1_win_chance = 50 + ((&pr1. - &pr2.)/&prScaler.);

		if t1_win_chance > 95 then t1_win_chance = 95;
		if t1_win_chance < 5 then t1_win_chance = 5;

		call symput('t1_win_chance_final', round(t1_win_chance, 1));
	run;

	%if &rand. < &t1_win_chance_final. %then %let winner=1;
	%else %let winner=2;

	%let team = %scan(&teams., &winner., "::");
	%let prr = %scan(&pr., &winner., "::");	

	data &div.&no.;
	length division team teams pr $100.;
		division = "&div.";
		match = &newmatchno.;
		team = "&team.";
		powerrating = &prr.;
		t1_win_chance = &t1_win_chance_final.;

		/*for testing*/
		winner = &winner.;
		teams = "&teams.";
		pr = "&pr.";
		prdiff = &pr1. - &pr2.;
	run;

%mend match;

	%macro genRand;
		%global rand;
		data _null_;
			a = round(rand("Uniform")*100, 1);
			call symput('rand', strip(a));
		run;
	%mend genRand;


%Main;
