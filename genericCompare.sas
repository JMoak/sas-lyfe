/* Written by Jordan Moak*/

/*This macro is to compare two datasets which are supposed to be exactly equal, written for the case where data sets are double
   programmed to ensure accuracy.

	The optional inputs are for controlled subsetting, sorting, and otherwise controlling the datasets sent to the compare.
	The optional inputs are optional and will not affect anything unless they are intentionally included in calling the macro.

	It is to essentially save the time it takes to write two datasteps in order to compare two datasets, or two compare two specific
	parts of the given datasets.  It can be very helpful to determining which aspects of the given datasets may not be exactly equal
	and what underlying problems may be the cause, for example if the datasets are equal but simpy sorted differently.

	Examples of the execution of the macro are included at the bottom.*/

%macro genericCompare ( inpdat, intdat, where=, extmacro=, keep=, drop=, sort=, outnam=COMPARE OUTPUT, outloc="C:\&outnam..rtf");
	data dataset1;
	set &inpdat;

	%if &where ne  %then %do;
		where &where;
	%end;

		%if &extmacro ne  %then %do;
		&extmacro;
		%end;

		%if &drop ne  %then %do;
		drop &drop;
		%end;

		%if &keep ne  %then %do;
		keep &keep;
		%end;
	run;

	%if &sort ne  %then %do;
		proc sort data=dataset1; by &sort; run;
	%end;

	data dataset2;
	set &intdat;

	%if &where ne  %then %do;
		where &where;
	%end;

		%if &extmacro ne  %then %do;
		&extmacro;
		%end;

		%if &drop ne  %then %do;
		drop &drop;
		%end;

		%if &keep ne  %then %do;
		keep &keep;
		%end;
	run;

	%if &sort ne  %then %do;
		proc sort data=dataset2; by &sort; run;
	%end;

	ods rtf file=&outloc.;
	proc compare base=dataset2 compare=dataset1;
	run;
	proc contents data=dataset2;
	proc contents data=dataset1; run;
	ods rtf close;
%mend genericCompare;

/*%genericCompare ( inpdat, intdat, where=, extmacro=, keep=, drop=, sort=, outnam=COMPARE OUTPUT, outloc=C:\&outnam..rtf);*/

/*%genericCompare(lib1.data_set1, lib2.data_set2, where=var1=:'ABC', drop= matchedvar1 matchedvar2, sort=sortvar1 sortvar2 sortvar3 sortvar4);*/
%genericCompare(lib1.data_set3, lib2.data_set4);
