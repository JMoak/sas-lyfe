/* Jordan Moak - SAS Sample Code*/

/*All the code included in this program is from my personal knowledge of the SAS programming language, and the only reference I used was SAS documentation
found online. None of the work I have done professionally was used as a reference in the creation of this program.

 This program was written in Notepad, because I do not have any of the available SAS programming environments on my home computers (they're too expensive!).
 This program has never been run through a SAS compiler and no debugging has taken place.*/

/*This example includes two parts.  The first is a series of answers to a SAS exercise I recently completed.  The second is code I wrote to expand on the test
  to better exemplify my abilities in SAS.  The second part uses the somewhat arbitrary datasets created in the first part (in the exercise) to create tables to be
  output containing statistical information about the data.  The table is formatted similar to tables I have created professionally, but this program includes
  no reference to any of my professional work and was not even written from referencing any code from my professional work.*/

/**********************************************************/
/* Part I - SAS Exercise Answers
02/25/14 � Started at 10:00 AM, finished at 11:00 AM */
/*********************************************************/

* Question 1:;

libname testdat �C:\Users\Jordan Moak\Desktop\SAS Test\Data�;

data subjinfo;
length race agegroup $10. multrace;
 set testdat.subjinfo;
   if race1 = 1 then RACE = 'Asian';
   if race2 = 1 then RACE = 'Black';
   if race3 = 1 then RACE = 'NHOPI';
   if race4 = 1 then RACE = 'White';

  MULTRACE = race1 + race2 + race3 + race4;
  if multrace > 1 then do;
	RACE = 'Multiple';
	multrace = 1;
  end;
  else multrace = 0;

   if age < 35 then AGEGROUP = '<35';
    else if age > 55 then AGEGROUP = '>55';
      else age = '35 � 55';
run;


* Question 2:;

proc sort data=subjinfo; by patient_no; run;
proc sort data=testdat.sampleinfo out=sampleinfo (rename=(patient_number = patient_no));
 by patient_number;
run;

data subsamp;
length gender$5.;
 merge subjinfo sampleinfo;
   by patient_no;

 	if upcase(sex) in ('M', 'MALE') then gender = 'M';
	else if upcase(sex) in ('F', 'FEMALE') then gender = 'F';
	else gender = '';

	barcode = upcase(barcode);
run;


* Question 3:;

* NOTE: Attached Excel file did not contain variable SampleIdNo, but contained Sample Barcode;
* Instructions said to use the variable SampleIdNo, and I assumed this was the variable name for the column labelled Sample Barcode;

proc sort data=subsamp; by barcode; run;

proc sort data=testdat.lab_data out=lab (rename=(sampleidno = barcode));
 by sampleidno;
run;

data final;
 merge subsamp lab;
 by barcode;
  if parent_barcode = "" then parent_barcode = barcode;
run;


*Question 4:;

proc sgplot data=final;
 scatter x=resultstat1 y=resultstat2 / group=site_no;
run;


*Question 5:;

%macro sumstats(indat,var,outdat,by=);
proc means data=&indat;
 var &var;

 %if &by ne  %then %do;
 	by &by;
 %end;

output out=&outdat n=n mean=mean std=stdev min=min max=max;
run;
%mend sumstats;

%sumstats(final, resultstat1, sumstats1, by=site_no);
%sumstats(final, resultstat2, sumstats2, by=site_no);


*Question 6:;

/* Creating a basic RTF output of the datasets*/
ods rtf file="C:\Users\Jordan Moak\Desktop\SAS Test\Ouput\Dataset output.rtf";

proc print data=subjinfo; run;
proc print data=subsamp; run;
proc print data=final; run;
proc print data=sumstats1; run;
proc print data=sumstats2; run;

ods rtf close;

/****************************************************************/
/************* END OF TEST, finished at 11:00 AM ***********/
/****************************************************************/


/**********************************************************************/
/* Part II - Extension of the test show more in-depth knowledge of SAS
    Written on March 7, 2014 */
/**********************************************************************/

/* Creating tables using the test data
	Tables specifically consists of summary statistics for the given resultstatistic
	split up by male and female for each race and overall(rows consist of male and female
	summary stats, and columns consist of race subsets and overall)*/

/*tablecol macro to create specifically formatted columns for the PROC REPORT from the final dataset.
	creates unique datasets for most subsets for checking purposes*/
%macro tablecol (race, statvar, out);

	/* splitting the data into male and female datasets*/
	data &race.male &race.female;
		set final;
			%if &race ne overall %then %do;
				where lowcase(race) = "&race.";
			%end;
				if gender = 'M' output &race.male;
				if gender = 'F' output &race.female;
	run;

	/*calculating summary stats for males and females*/
	%sumstats(&race.male, &statvar, &statvar.mss);
	%sumstats(&race.female, &statvar, &statvar.fss);

	/*creating the output dataset for males*/
	data malecolout;
	length grouprowname ssrowname $20. &race $10. sort;
		set &statvar.mss;

		grouprowname = "Male";

		ssrowname = 'N';	 &race = put(n, 6.0); sort=1; output;
		ssrowname = 'Mean';	 &race = put(mean, 6.2); sort=2; output;
		ssrowname = 'Standard Deviation'; &race = put(stdev, 6.3); sort=3; output;
		ssrowname = 'Min';	 &race =  put(min, 6.2); sort=4; output;
		ssrowname = 'Max'; 	 &race = put(max, 6.2); sort=5; output;

	keep grouprowname ssrowname &race sort;
	run;

	/*creating a blank row for aesthetic purposes*/
	data blankrow;
	length grouprowname ssrowname $20. &race $10. sort;
		grouprowname = '';
		ssrowname = '';
		&race = '';
		sort=6;
	run;

	/*creating the female output dataset*/
	data femalecolout;
	length grouprowname ssrowname $20. &race $10. sort;
		set &statvar.fss;

		grouprowname = "Female";

		ssrowname = 'N';	 &race = put(n, 6.0); sort=7; output;
		ssrowname = 'Mean';	 &race = put(mean, 6.2); sort=8; output;
		ssrowname = 'Standard Deviation'; &race = put(stdev, 6.3); sort=9; output;
		ssrowname = 'Min';	 &race =  put(min, 6.2); sort=10; output;
		ssrowname = 'Max'; 	 &race = put(max, 6.2); sort=11; output;

	keep grouprowname ssrowname &race sort;
	run;

	/*setting the output table column together*/
	data &out;
		set malecolout blank femalecolout; by sort;
	run;
%mend tablecol;


/*table macro to output rtf files of a proc report of the table output.
	creates table with filename 'Table &tablenum'*/
%macro table(tablenum, tablevar);

  /*taking the population count to be used in the table header*/
  proc sql;
  	select count (*) into :popcount from final;
  quit;

  /*calling the %tablecol macro on the given statistic to form a dataset for the table*/
  %tablecol(asian, &tablevar, col1);
  %tablecol(black, &tablevar, col2);
  %tablecol(nhopi, &tablevar, col3);
  %tablecol(white, &tablevar, col4);
  %tablecol(multiple, &tablevar, col5);
  %tablecol(overall, &tablevar, col6);

  /*merging the table columns together*/
  data tableout&tablenum.;
  	merge col1-col6;
  		by sort;
  run;

  /*assigning the table headers and footers*/
  title1 "Table &tablenum.";
  title2 "&tablevar. Summary Statistics for Males and Females by Race and Overall";
  title3 "Population (N= &popcount.)";

  footnote1 "Multiple race column includes subjects who listed more than one race.";
  footnote2 "Table Created by Jordan Moak,
  		  %left(%qsysfunc(date(),worddate18.))";


  ods rtf file="C:\Users\Jordan Moak\Desktop\SAS Test\Ouput\Table &tablenum..rtf";

  proc report data=tableout&tablenum. split='*' spacing=3;
  column grouprowname ssrowname ('Race' asian black nhopi white multiple overall);

  	define grouprowname / group ' '
  						  style(header)=[just=center cellwidth=1.2in]
  						  style(column)=[just=left cellwidth=1.2in];

  	define ssrowname / display ' '
  						  style(header)=[just=center cellwidth=1.3in]
  						  style(column)=[just=left cellwidth=1.3in];

  	define asian / display 'Asian'
  						  style(header)=[just=center cellwidth=.9in]
   						  style(column)=[just=center cellwidth=.9in];

   	define black / display 'Black or*African American'
  						  style(header)=[just=center cellwidth=.9in]
   						  style(column)=[just=center cellwidth=.9in];

  	define nhopi / display 'Native Hawaiian or*Other Pacific Islander'
  						  style(header)=[just=center cellwidth=.9in]
   						  style(column)=[just=center cellwidth=.9in];

  	define white / display 'White'
  						  style(header)=[just=center cellwidth=.9in]
   						  style(column)=[just=center cellwidth=.9in];

  	define multiple / display 'Multiple'
  						  style(header)=[just=center cellwidth=.9in]
   						  style(column)=[just=center cellwidth=.9in];

  	define overall / display 'Overall'
  						  style(header)=[just=center cellwidth=1.2in]
   						  style(column)=[just=center cellwidth=1.2in];
  run;
  quit;
  ods rtf close;

%mend table;

%table(1, Resultstat1);
%table(2, Resultstat2);
/*two tables are output as rtf files for the statistics Resultstat1 and Resultstat2 respectively*/
