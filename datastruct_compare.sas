/*******************************************************************************************************
** Program Name         :  datastruct_compare.sas             	  	          									**
** Creation Date        :  1/8/2015					                                								**
** Analyst              :  Jordan Moak								   				 									**
** Program Version      :  1.0.0.X					     							         							**
********************************************************************************************************
** Description          : Compares the structure of two datasets.													** 
********************************************************************************************************
**                      C H A N G E  H I S T O R Y                                     					**
********************************************************************************************************
** Analyst              :  Jordan Moak											   				 						**
** Program Version      :  1.0.0.0					     							          							**
**	Date						:	1/8/2015																							**
**	Notes						:  • Initial Code																					**
*******************************************************************************************************/

%macro datastruct_compare(ds1, ds2, components=name type length label format formatl formatd informat informl informd
								 , prefix=DSC, compareoutfile="C:\Users\Public\Documents\datastruct_compare.rtf", compareds=, printoutput=TRUE);

	/*checking if there's a libname, if so, grabbing only the dataset name*/
	%if %index(&ds1, .) > 0 %then %let ds1dsname = %scan(&ds1, 2, '.');
	%if %index(&ds2, .) > 0 %then %let ds2dsname = %scan(&ds2, 2, '.');
	%if &ds1dsname = &ds2dsname %then %do;
		%put WARNING: Datastruct Compare input datasets have the same dataset name. Dataset input second will have 2 appended to the name.;
		%let ds2dsname = &ds2dsname.2;
	%end;

	/*running proc contents on both datasets, keeping only the &components to be compared*/
	proc contents data=&ds1.
					  out=&ds1dsname.struct (keep=&components.)  
					  noprint; 
	run;
	proc contents data=&ds2. 
					  out=&ds2dsname.struct (keep=&components.) 
					  noprint; 
	run;

	/*upcasing the variable names*/
	data &ds1dsname.struct &ds2dsname.struct;
		set &ds1dsname.struct (in=a) &ds2dsname.struct (in=b);
		name=upcase(name);

		if a then output &ds1dsname.struct;
		if b then output &ds2dsname.struct;
	run;

	proc sort data=&ds1dsname.struct; by name;
	proc sort data=&ds2dsname.struct; by name;
	run;

	/*running a proc compare on the two datastruct datasets*/
	%if &printoutput = TRUE %then %do; ods rtf file=&compareoutfile.; %end;
		proc compare base=&ds1dsname.struct compare=&ds2dsname.struct 
			%if &compareds ne  %then %do; out=&compareds outnoequal %end;
			%if &printoutput ne TRUE %then %do; noprint; %end;
			;
		run;
	%if &printoutput = TRUE %then %do; ods rtf close; %end;

	/*outputting information datasets to the work directory*/
	data &prefix._both;
		merge &ds1dsname.struct (in=a) &ds2dsname.struct (in=b keep=name);
			by name;
			if a and b;
	run;

	data &prefix._&ds1dsname.ONLY;
		merge &ds1dsname.struct (in=a) &ds2dsname.struct (in=b keep=name);
			by name;
			if a and not b;
	run;

	data &prefix._&ds2dsname.ONLY;
		merge &ds1dsname.struct (in=a keep=name) &ds2dsname.struct (in=b);
			by name;
			if b and not a;
	run;
%mend datastruct_compare;

