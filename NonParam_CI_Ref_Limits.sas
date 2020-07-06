*** Macro for Calculating the 1-alpha CI for the (100p)th percentile;

%macro Main(datout=,p=,cl=,nobs=,type=ASYMMETRIC);

	/* Calculate the starting point.*/
	%starting_point(&nobs., &p.);

	/* Calculate the percentile rank. */
	%calc_pctl(&nobs., &p.);

	/* Calculating the initial CL from the starting point */
	%calc_cl(Initial, &p., &cl., &nobs., &starting_point., type=&type.);

	/* Looping over similar start points. */
	proc sql noprint;
		select lower into :min_start from initial;
		select upper into :max_start from initial;
		select (upper - lower) into :range from initial;
	quit;

	%let min_start = &min_start.;
	%let max_start = &max_start.;
	%let range = &range.;

/*	%if &range. < 15 %then %do;*/
		%do s=&min_start. %to &max_start.;
			%calc_cl(cl_&s., &p., &cl., &nobs., &s., type=&type.);
		%end;
/*	%end;*/

	/* Organizing the output. */
	data temp;
		set Initial cl_&min_start.-cl_&max_start.;
			cdf_minus_cl = cdf_diff - cl;
			if cdf_minus_cl ge 0 then conf_met = 1;
			else conf_met = 0;
			abs_cdf_minus_cl = abs(cdf_minus_cl);
	run;

	proc sort data=temp;
		by DESCENDING conf_met abs_cdf_minus_cl ;
	run;

	data &datout.;
		set temp;
			by DESCENDING conf_met abs_cdf_minus_cl;
			row = _N_;
			np = &pctl_rank.;
	run;
	

	proc datasets lib=work nolist;
		delete cl_&min_start.-cl_&max_start.;
	run;quit;

%mend Main;


	%macro starting_point(n, p);

		data start_point;
			start_point = floor(&n.*&p.)+1;
		run; 
		
		%global starting_point;
		proc sql noprint;
			select start_point into :starting_point from start_point;
		quit;
		
	%mend starting_point;

	%macro calc_cl(datout, p, cl, n, start_point, type=ASYMMETRIC);

		%if %sysfunc(exist(&datout.)) %then %do;
			proc datasets lib=work; delete &datout.; run; quit;
		%end;

		%let upStep = 0;
		%let downStep = 0;
		%let count = 1;
		%let cdf_diff = 0;

		%if &start_point. = 0 %then %let start = 1;
		%else %let start = &start_point.;

		%do %until (&cdf_diff. ge &cl. OR &count. = &n.);

			/*stepping up and down (up on odd, down on even)*/
			%if &type. = ASYMMETRIC %then %do;
				%if %sysfunc(mod(&count., 2)) = 1 %then %do;
					%if (&start. + (&upStep. + 1)) le &n. %then %do;
						%let upStep = %eval(&upStep. + 1);
					%end;
					%else %do;
						%let downStep = %eval(&downStep. + 1);
					%end;
				%end;
				%else %do;
					%if (&start. - (&downStep. + 1)) > 0 %then %do;
						%let downStep = %eval(&downStep. + 1);
					%end;
					%else %do;
						%let upStep = %eval(&upStep. + 1);
					%end;
				%end;
			%end;
			%else %if &type. = SYMMETRIC %then %do;
				%if (&start. + (&upStep. + 1)) le &n. %then %do;
					%let upStep = %eval(&upStep. + 1);
				%end;
				%if (&start. - (&downStep. + 1)) > 0 %then %do;
					%let downStep = %eval(&downStep. + 1);
				%end;
			%end;

			/*calculating u-1 and l-1*/
			%let u_minus_1 = %eval(&start. + &upStep. - 1);
			%let l_minus_1 = %eval(&start. - &downStep. - 1);

			/*calculating the CDFs*/
			data upperCDF;
				do i = 0 to &u_minus_1. by 1;
						if i eq 0 then do;
							upperCDF = pdf('BINOMIAL',i,&p,&n.);
						end;
						else do;
							upperCDF + pdf('BINOMIAL',i,&p,&n.);
						end;
					output;
				end;
			run;

			data lowerCDF;
				do i = 0 to &l_minus_1. by 1;
						if i eq 0 then do;
							lowerCDF = pdf('BINOMIAL',i,&p,&n.);
						end;
						else do;
							lowerCDF + pdf('BINOMIAL',i,&p,&n.);
						end;
					output;
				end;
			run;			

			proc sql noprint;	
				select put(upperCDF, 20.15) into :CDF_u from upperCDF where i=&u_minus_1.;
				select put(lowerCDF, 20.15) into :CDF_l from lowerCDF where i=&l_minus_1.;
			quit;

			data &datout.;
				count=&count.;
				cl = &cl.;
				n = &n.;
				p = &p.;
				start_point = &start.;
				lower = &start. - &downStep.;
				upper = &start. + &upStep.;
				CDF_u = &CDF_u.;
				CDF_l = &CDF_l.;
				CDF_Diff = &CDF_u. - &CDF_l.;
				output;
			format CDF_Diff cdf_u cdf_l 20.15;
			run;

			proc sql noprint;
				select put(CDF_Diff, 20.15) into :CDF_Diff from &datout. where count=&count.;
			quit;

			%let count = %eval(&count. + 1);
		%end;

	%mend calc_cl;

	%macro calc_pctl(n, p);

		%global pctl_rank;

		%let np_real = %sysfunc(mod(&p.*(&n.),1));	%put Decimal: &np_real;
		%let np_int = %sysfunc(int(&p.*&n.)); 			%put Integer: &np_int;
		
		* Apply same rules as PROC UNIVARIATE for determining percentiles when PCTLDEF=2;
		%if %sysfunc(mod(&np_real.,1)) < 0.5 OR %sysfunc(mod(&np_real.,1)) > 0.5 %then %do;
			%let pctl_rank = %sysfunc(round(&p.*(&n.),1));
		%end;
		%else %if %sysfunc(mod(&np_real.,1)) = 0.5 %then %do;
			%if %sysfunc(mod(&np_int.,2)) = 1 %then %do;
				%let pctl_rank = %eval(&np_int.+1);
			%end;
			%else %do;
				%let pctl_rank = &np_int.;
			%end;
		%end;

	%mend calc_pctl;


%Main(datout=test025, p=0.025, cl=0.90, nobs=100, type=ASYMMETRIC);
%Main(datout=test975, p=0.975, cl=0.90, nobs=100, type=ASYMMETRIC);


/*%macro sasv(n);*/
/*	data test;*/
/*		%do i=1 %to &n.;*/
/*			number = &i.;*/
/*			output;*/
/*		%end;*/
/*	run;*/
/**/
/*	proc univariate data=test pctldef=2 noprint;*/
/*		var number;*/
/*		output out=check2 pctlpts=2.5 97.5 pctlpre=P */
/*					cipctldf=(lowerpre=LCL upperpre=UCL alpha=0.10)*/
/*					n=nobs; */
/*	run;*/
/*%mend sasv;*/
/**/
/*%macro both(nobs);*/
/**/
/*	%Main(datout=check975,p=0.975,cl=0.9,nobs=&nobs.);*/
/*	%Main(datout=check025,p=0.025,cl=0.9,nobs=&nobs.);*/
/*	%sasv(&nobs.);*/
/**/
/*%mend both;*/
/**/
/*%both(100);*/
