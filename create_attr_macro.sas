/****************************************************************************************************
**	Program		: create_attr_macro.sas																					**
**	Programmer	: Jordan Moak 																								**
**	Date		: 05/25/14																										**
*****************************************************************************************************
**	Description	: Macro which will write an attrib file (.sas) for any basic dataset						**
*****************************************************************************************************
** CHANGELOG  ***************************************************************************************
*****************************************************************************************************
**	Version		:	1.0.0.1																									**
**	Date			:	05/25/14																									**
**	Description	:	Initial Code.																							**
*****************************************************************************************************
**	Version		:	1.0.0.2																									**
**	Date			:	03/30/14																									**
**	Description	: - Added Macro to create attribs for directory of datasets, output to one file.		**
**					  - Reformatted much of the program.																**
****************************************************************************************************/

options noxwait xsync;

%let readDirectory = C:\project\analysis datasets;		/*directory containing datasets			*/
%let outDir = C:\project\Attrib;								/*name of the out directory				*/
%let outFile = attrib.sas;										/*Name of the ouput .sas file			*/
%let callAfterRun = Y;											/*Y/N to run the created attrib program	*/ 


%macro create_attr_all;

	libname for_attr "&readDirectory.";
	
	/*creating the array of dataset names to loop over*/
	proc datasets lib=for_attr nolist noprint;
		contents data=_all_ out=work.dataSets (keep=memname);
	run; quit;

	proc sql noprint;
		select distinct memname into :dsList separated by ' ' from dataSets;
		%let dsCount = &sqlobs.;
	quit;
	
	/* For output Formatting */
	%let dateTime = %sysfunc(datetime(), datetime.);

	data programHeader;
	length line $4000.;
		line="/***************************************************************"; output;
		line="** &outFile. Attribute File                                  **"; output;
		line="** Generated Date: &dateTime.                           **"; output;
		line="***************************************************************/"; output;
	run;

	data space; 
	length line $4000.;
		line=" "; output; output; 
	run;

	/*looping over all of the sas datasets in the read directory*/
	%do ds=1 %to &dsCount.;
		%let currDS = %scan(&dsList., &ds., ' ');
	
		%create_attr(for_attr.&currDS., directory=&outDir.);
		
		data &currDS.;
		length line $4000.;
			infile "&outDir.\&currDS._attrib.sas" dlm=',' missover dsd;
			input line;
			
			line=trim(left(line));
		run;
		
		data fileOut;
			set %if %sysfunc(exist(fileOut)) %then %do; fileOut space %end;
				&currDS.
			;
		label line="/*Program Start*/";
		run;
	%end;

	/*a tiny bit more formatting*/
	data fileOut;
		set programHeader space fileOut (in=main);

		line=strip(line);
		if main and index(line, "%") = 0 then line = "		"||line;
	run;
	
	options leftmargin=0in nocenter nodate nonumber;
	ods noproctitle;
	ods escapechar='^';

	ods listing file="&outDir.\&outFile.";

		proc printto print="&outDir.\&outFile." new;
		run;
		
		proc print data=fileOut noobs label;
		run;
	
		proc printto; run;

	ods listing close;
	
	/*House Keeping*/
	proc datasets lib=work nolist;
		delete &dsList. programHeader datasets space fileOut;
	run; quit;
	
	%do ds=1 %to &dsCount.;
		%let currDS = %scan(&dsList., &ds., ' ');
		x del "&outDir.\&currDS._attrib.sas";
	%end;

	libname for_attr clear;
	
	%if &callAfterRun = Y %then %do;
		%include "&outDir.\&outFile.";
	%end;
	
%mend create_attr_all;


%macro create_attr 	( datain 										/*dataset to grab the attribs from		*/
					, directory=C:\test								/*directory for output file				*/
					, outfile = &directory.\&datain._attrib.sas 	/*path specified for the output program	*/
					);

	proc contents data=&datain. out=create_attr_1 noprint;
	run;

	proc sort data=create_attr_1; by name; run;

	proc sql noprint;
		select name into :varname1-:varname&sysmaxlong from create_attr_1; 			/*variable names							*/
		select type into :vartype1-:vartype&sysmaxlong from create_attr_1; 			/*variable types							*/
		select length into :varlength1-:varlength&sysmaxlong from create_attr_1; 	/*variable lengths						*/
		select label into :varlabel1-:varlabel&sysmaxlong from create_attr_1; 		/*variable labels							*/

		select format into :varfmt1-:varfmt&sysmaxlong from create_attr_1; 			/*variable formats						*/
		select formatl into :varfmtl1-:varfmtl&sysmaxlong from create_attr_1; 		/*format lengths							*/
		select formatd into :varfmtd1-:varfmtd&sysmaxlong from create_attr_1; 		/*format decimal values					*/

		select informat into :varinfmt1-:varinfmt&sysmaxlong from create_attr_1; 	/*variable informats						*/
		select informl into :varinfmtl1-:varinfmtl&sysmaxlong from create_attr_1; 	/*variable informat lengths			*/
		select informd into :varinfmtd1-:varinfmtd&sysmaxlong from create_attr_1; 	/*variable informat decimal values	*/

		select max(varnum) into :varnum from create_attr_1; 						/*number of variables for the loop	*/
	quit;
	
	/*renaming the &datain. macro variable to remove a possible libname*/
	%if %index(&datain., .)>0 %then %let datain = %scan(&datain., 2, '.');
	%let outfile = &outfile.;

	/*writing the .sas program file*/
	data _null_;
		file "&outfile.";

		put %sysfunc(cat('%macro', " &datain._attrib;"));

		%do i=1 %to &varnum.;

		/*getting the lengths right (adding the $ if it is character variable)*/	
			%if &&vartype&i = 1 %then %do;
				%let variablelength = &&varlength&i;
			%end;
			%else %if &&vartype&i = 2 %then %do;
				%let variablelength = $&&varlength&i;
			%end;
		
		/*getting the format value put together right*/
		%if &&varfmt&i =  %then %do; /*no format for variable*/
			%let variableformat = "				";
		%end;
		%else %do;
			%if &&varfmtl&i = 0 and &&varfmtd&i = 0 %then %do; /*format with no length or decimal values*/
				%let variableformat = FORMAT=&&varfmt&i...;
			%end;
			%else %if &&varfmtl&i ne 0 and &&varfmtd&i = 0 %then %do; /*format with length but no decimal values*/
				%let variableformat = FORMAT=&&varfmt&i..&&varfmtl&i...;
			%end;
			%else %if &&varfmtl&i ne 0 and &&varfmtd&i ne 0  %then %do; /*format with length and decimal values*/
				%let variableformat = FORMAT=&&varfmt&i..&&varfmtl&i...&&varfmtd&i..;
			%end;
			%else %if &&varfmtl&i = 0 and &&varfmtd&i ne 0 %then %do; /*format with no length, but has decimal value*/
				/*this case probably doesn't exist*/
				%let variableformat = FORMAT=&&varfmt&i...&&varfmtd&i..;
			%end;
		%end;

		/*getting the informat value put together right*/
		%if &&varinfmt&i =  %then %do; /*no informat for variable*/
			%let variableinformat = "				";
		%end;
		%else %do;
			%if &&varinfmtl&i = 0 and &&varinfmtd&i = 0 %then %do; /*informat with no length or decimal values*/
				%let variableinformat = INFORMAT=&&varinfmt&i...;
			%end;
			%else %if &&varinfmtl&i ne 0 and &&varinfmtd&i = 0 %then %do; /*informat with length but no decimal values*/
				%let variableinformat = INFORMAT=&&varinfmt&i..&&varinfmtl&i...;
			%end;
			%else %if &&varinfmtl&i ne 0 and &&varinfmtd&i ne 0  %then %do; /*informat with length and decimal values*/
				%let variableinformat = INFORMAT=&&varinfmt&i..&&varinfmtl&i...&&varinfmtd&i..;
			%end;
			%else %if &&varinfmtl&i = 0 and &&varinfmtd&i ne 0 %then %do; /*informat with no length, but has decimal value*/
				/*this case probably doesn't exist*/
				%let variableinformat = INFORMAT=&&varinfmt&i...&&varinfmtd&i..;
			%end;
		%end;

		/*writing the attrib statement*/	
			put "    ATTRIB &&varname&i.. LENGTH=&variablelength. &variableformat. &variableinformat. LABEL='&&varlabel&i..';";
		%end;

		put %sysfunc(cat('%mend', " &datain._attrib;"));
	run;

	proc datasets lib=work nolist;
		delete create_attr_1;
	run;
%mend create_attr;


%create_attr_all;


