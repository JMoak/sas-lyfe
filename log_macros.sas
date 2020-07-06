/*******************************************************************************************************
** Program Name         : 	log_macros.sas   					     	  	          									**
** Creation Date        :  03/25/2015				                                								**
** Analyst              :  Jordan Moak								   				 									**
** Program Version      :  1.0.0.X					     							         							**
********************************************************************************************************
** Description          : Set of macros to output and scan logs.													** 
********************************************************************************************************
********************************************************************************************************
**                      C H A N G E  H I S T O R Y                                     					**
********************************************************************************************************
** Analyst              :  Jordan Moak											   				 						**
** Program Version      :  1.0.0.0					     							          							**
** Date						: 	03/25/2015																						**
**	Notes						:  • Initial Code																					**
*******************************************************************************************************/

/***********************************************/
/* Macro to scan the log for ERRORS/WARNINGS ***/

%macro log_scan(log_in, out_log);

	/*scanning the inlog*/
	data full_log;
	length inline $4000.;
		infile &log_in. missover dsd;
		input inline;
		lineno=_N_ - 1;
	run;

	data full_log;
	length Log_Text $4000.;
		set full_log;
		where index(inline, "ERROR")>0 
			or index(inline, "WARNING")>0 
			or index(upcase(inline), "UNINITIALIZED")>0
			or index(upcase(inline), "MERGE")>0
			;

		if index(inline, "_ERROR_")>0 then delete;

		Log_Text = "|"||strip(lineno)||"|	"||inline;
	keep Log_Text;
	label Log_Text=" ";
	run;

	dm log 'clear;';

	/*for sanity - creating the new log file*/
	data _null_;	file &out_log.; run;

	ods listing;

	proc printto print=&out_log. new;
	run;

	proc print data=full_log noobs label;
	run;

	proc printto; run;
	ods listing close;

	proc datasets lib=work nolist;
		delete full_log;
	run; quit;

	dm log 'clear;';

%mend log_scan;

/*example*/
/* %log_scan("C:\test\testlog_25MAR15_16.18.50.log", "C:\test\testscan.log"); */


/***************************************************************/
/* Macro to print external log and clear the log window in SAS */

%macro log_printto(outloc, start_stop, append_datetime=TRUE);

	%let trues = TRUE T YES Y;
	%let append_datetime = %upcase(&append_datetime.);

	%if %index(&trues., &append_datetime.)>0 %then %do;
		%let current_dt=%sysfunc(datetime(), datetime.);
		%let current_dt = %substr(&current_dt., 1, 7)_%scan(&current_dt., 2, ":").%scan(&current_dt., 3, ":").%scan(&current_dt., 4, ":");
		%let outloc = &outloc._&current_dt.;
	%end;

	%let start_stop = %upcase(&start_stop.);
	%let start_words = START BEGIN 0;
	%let stop_words = STOP END 1;

	%if %index(&start_words., &start_stop.)>0 %then %do;
		dm log 'clear;';

		/*for sanity - creating the new log file*/
		data _null_;	file "&outloc..log"; run;

		ods listing;

		proc printto log="&outloc..log" new;
		run;
	%end;

	%if %index(&stop_words., &start_stop.)>0 %then %do;
		proc printto; run;
		ods listing close;

		dm log 'clear;';
	%end;

%mend log_printto;


/*EXAMPLE*/
/*
%log_printto(C:\test\testlog, start);
	%put procedure code will go here;

	data asdfs;
		set asdfak as;
		where a = b;
	run;

	%put end of test;
%log_printto(C:\test\testlog, stop);
*/
