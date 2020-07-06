/*just a test*/

%macro timertest;
	%timer(start);
	%timer(start, timername=Loop, timerinstance=1)

	data test;
		array v a b c d e f g h i j k l m n o p q r s t u w x y z;
		do over v;
			do i=1 to 1000000;
			v[_I_]=i; output;
			end;
		end;
	run;

	%timer(stop, timername=Loop, timerinstance=1);
	%timer(start, timername=Loop, timerinstance=2);

	%let varray = a b c d e f g h i j k l m n o p q r s t u w x y z;
	data test2;
		%do j=1 %to %sysfunc(countw(&varray.));
			do i=1 to 1000000;
				%scan(&&varray, &j, ' ') = i; output;
			end;
		%end;
	run;

	%timer(stop, timername=Loop, Timerinstance=2);
	%timer(stop);
%mend timertest;
%timertest;
