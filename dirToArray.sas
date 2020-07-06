/* dirToArray.sas
	Written by: Jordan Moak
	Date: 12/1/2015
*/

/* macro to put the contents of a directory into an array */
%macro dirToArray(dir, arrayName);

	/* opening the directory and getting the dir ID */
	%let rc = %sysfunc(filename(dirRef, &dir.));
	%let did = %sysfunc(dopen(&dirRef.));

	/*initializing the array to be output*/
	%let &arrayName. = ;

	/* looping over the dir to get all file and folder names*/
	%do i=1 %to %sysfunc(dnum(&did.));
		%let item = %qsysfunc(dread(&did., &i.));
		%let &arrayName. = &&&arrayName.. &item.;
	%end;

	/* closing the directory and clearing the dirRef */
	%let rc = %sysfunc(dclose(&did.));
	%let rc = %sysfunc(filename(dirRef));

%mend dirToArray;
