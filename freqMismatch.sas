/*Written by Jordan Moak*/

/* This macro is written in order to create a dataset of subjects or some other sort of observations which have differing frequencies between two datasets.
    It is meant to be used as a tool to pinpoint the differences in a dataset where datasets are being double programmed to ensure accuracy, and it is especially
    applicable in situations where the datasets have more than one observation for a given subject, or other primary object indicator for the dataset.

   The outputs are mutiple datasets containing frequencies and a dataset of mismatch observations at the &encapVar level.*/

%macro freqMismatch (dataset1, dataset2, encapVar, subVar, outdat=mismatchResults) ;

proc datasets library=work kill nolist;
quit;     

proc freq data=&dataset1 noprint;
	tables &encapVar.*&subVar. / out=ds1subfreq (keep=&encapVar. &subVar.);
	tables &encapVar.	/ out=ds1freq (keep=&encapVar. count rename=(count=ds1freq));
run;

proc freq data=&dataset2 noprint;
	tables &encapVar.*&subVar. / out=ds2subfreq (keep=&encapVar. &subVar.);
	tables &encapVar. / out=ds2freq (keep=&encapVar. count rename=(count=ds2freq));
run;

data &outdat.;
	merge ds1freq ds2freq;
		by &encapVar.;

	if ds1freq=ds2freq then delete;
run;

%mend freqMismatch;
