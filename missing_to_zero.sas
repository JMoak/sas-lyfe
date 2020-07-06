%macro missing_to_zero(indat);

	proc contents data=&indat. out=temp (keep=name type) noprint;
	run;

	proc sql noprint;
		select name into :numvars separated by ' ' from temp where type=1;
		select name into :charvars separated by  ' ' from temp where type=2;
	quit;

	data &indat;
		set &indat;

		array nums &numvars.;
		array chars &charvars.;
		do over nums;
			if nums[_I_] = . then nums[_I_] = 0;
		end;
		do over chars;
			if strip(chars[_I_]) = '' then chars[_I_] = '0';
		end;
	run;

	proc datasets lib=work nolist;
		delete temp;
	run; quit;

%mend missing_to_zero;
