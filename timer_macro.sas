/*******************************************************************************************************
** Program Name         : 	timer_macro.sas   				     	  	          									**
** Creation Date        :  12/22/2014				                                								**
** Analyst              :  Jordan Moak								   				 									**
** Program Version      :  1.0.0.X					     							         							**
********************************************************************************************************
** Description          :  Will output a dataset and notes to the log pertaining to the time spent		**
**									for the program to run.																		** 
********************************************************************************************************
********************************************************************************************************
**                      C H A N G E  H I S T O R Y                                     					**
********************************************************************************************************
** Analyst              :  Jordan Moak											   				 						**
** Program Version      :  1.0.0.0					     							          							**
** Date						: 	12/22/2014																						**
**	Notes						:  • Initial Code																					**
*******************************************************************************************************/

%macro timer( startstop, outds=programtimer, timername=Program , timerinstance=);
	
	/*upcasing the start/stop parameter*/
	%let startstop = %sysfunc(upcase(&startstop));

	/*starting the timer*/
	%if &startstop = START %then %do;

		%global timerstart&timername&timerinstance.;
		%let timerstart&timername&timerinstance. = %sysfunc(datetime());
		%put NOTE: &timername. START TIMER &timerinstance. : %sysfunc(datetime(), datetime14.);

		data timertemp;
			length timertext timerinstance $50.;
			timertext = "&timername.";
			timerinstance = "&timerinstance.";
			starttime = &&timerstart&timername&timerinstance.*1;
		run;

		data &outds.;
			set
			%if %sysfunc(exist(&outds.)) %then %do;
				&outds.
			%end;
				timertemp;
				by timertext timerinstance;
				if last.timerinstance;
		label timertext='Timer Name' timerinstance='Timer Instance' starttime='Start Time';
		format starttime datetime14.;
		run;
	%end;

	/*ending the timer*/
	%if &startstop = STOP %then %do;
		%let timerend&timername&timerinstance. = %sysfunc(datetime());
		%put NOTE: &timername. END TIMER &timerinstance.: %sysfunc(datetime(), datetime14.);
		%put NOTE: &timername. &timerinstance. TIME TAKEN: %sysfunc(putn(%sysevalf(&&timerend&timername&timerinstance.-&&timerstart&timername&timerinstance.), mmss.)) (mm:ss);

		data timertemp;
			length timertext timerinstance $50.;
			timertext = "&timername.";
			timerinstance = "&timerinstance.";
			endtime = &&timerend&timername&timerinstance.*1;
			timetaken = (&&timerend&timername&timerinstance.-&&timerstart&timername&timerinstance.)*1;
		run;

		proc sort data=&outds.;*nodupkey; 
			by timertext timerinstance;
		run;

		data &outds.;
			%if %sysfunc(exist(&outds.)) %then %do;
				merge &outds. timertemp;
					by timertext timerinstance;
			%end;
			%else %put ERROR: THE TIMER (&timertext. &timerinstance.) WAS NEVER STARTED;
		label timertext='Timer Name' timerinstance='Timer Instance' endtime='End Time' timetaken='Time Taken (MM:SS)';
		format endtime datetime14. timetaken mmss.;
		run;
	%end;

%mend timer;












