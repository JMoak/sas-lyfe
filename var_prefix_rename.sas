%macro rename (lib, dsn, oldpre, newpre);

	proc sql; 
		select name into :changeList separated by " " from dictionary.columns 
			where lowcase(libname)="&lib." and lowcase(memname)="&dsn." and find(name, "&oldpre.") > 0; 
	quit;

	data &lib..&dsn.;
		set &lib..&dsn.;

		%do i=1 %to %sysfunc(countw(&changeList.));
			%let iName = %scan(%scan(&changeList., &i., ' '), 1, "&oldpre.");

			&newpre.&iName. = &oldpre.&iName.;
			drop &oldpre.&iName.;
		%end;
	run;

%mend rename;

data testing;
	aboo1 = 1;
	acoo1 = 2;
	adoo1 = 3;
run;

%rename(work, testing, a, z);
