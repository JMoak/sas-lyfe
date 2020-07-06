/*******************************************************************************************************
** Program Name         :  varsexist_macro.sas	             	  	          									**
** Creation Date        :  1/9/2015					                                								**
** Analyst              :  Jordan Moak								   				 									**
** Program Version      :  1.0.0.X					     							         							**
********************************************************************************************************
** Description          :  Macro to check if a set of variables (all) exist in a dataset.					** 
********************************************************************************************************
**                      C H A N G E  H I S T O R Y                                     					**
********************************************************************************************************
** Analyst              :  Jordan Moak											   				 						**
** Program Version      :  1.0.0.0					     							          							**
**	Notes						:  • Initial Code																					**
*******************************************************************************************************/

%macro varsexist( ds, vars);
	%let dsid = %sysfunc(open(&ds.));

	%if (&dsid) %then %do;
		
		%let existcount = 0;
		%let varcount = %sysfunc(countw(&vars.));

		%do vn=1 %to &varcount.;
			%let currvn = %scan(&vars., &vn, ' ');
			%if %sysfunc(varnum(&dsid., &currvn.)) %then %let existcount = %eval(&existcount + 1);
		%end;

		%let rc = %sysfunc(close(&dsid.));

		%if %eval(&existcount - &varcount) = 0 %then 1;
		%else 0;

	%end;
	%else 0;
%mend varsexist;

/**----- EXAMPLE USE -------------------
	%if %varsexist(datasetin, var1 var2 var3) = 0 %then %do;
			//whatever you'd like to do when the variables don't all exist in the dataset.
	%end;
	%else %do;
		//whatever you'd like to do when the variables do all exist in the dataset.
	%end;

	---OR----

	%if %varsexist(datasetin, var1 var2) > 0 %then %do;
		//whatever you'd like to do when the variables do all exist in the dataset.
	%end;
**/
