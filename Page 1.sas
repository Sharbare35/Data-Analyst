%let threshold=25;

*DATAFILE= "C:\Documents and Settings\Dad\My Documents\My SAS Files\IHC\Physician\ph2003.DBF";
       
PROC IMPORT OUT= WORK.PhysicianMaster 
              DATAFILE= "p:\ppqms\cppqphys\nov2010\phnov10.DBF"  
			/*DATAFILE= "h:\ihc\clinicphysicianreports\phnov10.DBF"*/
			DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;
  /* proc freq data=physicianMaster; tables date; run; */
Data PhysicianMaster; 
     format AverageScore phcc phli phre phdt 
            NUCC NUSK NULI REAC REHE WTAP WTPH
            best12.;
     set PhysicianMaster;
	 length date2label2 $15;
     array v(11) phcc phli phre phdt NUCC NUSK NULI REAC REHE WTAP WTPH;
     do i=1 to 11;
        if v(i)>5 or v(i)<1 then v(i)=.;
     end;
	 if phre>4 then phre=.;

    
	 if "&mvar"='PHCC' then AverageScore=Mean(of phcc);	/*calculating for each individual record*/
		else if "&mvar"='PHDT' then AverageScore=Mean(of phdt);
		else if "&mvar"='PHLI' then AverageScore=Mean(of phli);
		else if "&mvar"='PHRE' then AverageScore=Mean(of phre);
		

     
     year=int(date/10000);
     month=substr(left(date),5,2)+0;
     day=substr(left(date),7,2)+0;
     sasdate=mdy(month,day,year);
     date2=substr(left(date),1,6)+0;              
*    if date2=200307 then delete;
*	 if date2=200403 then delete;
*	 if date2=200407 then delete;
     date2label=put(sasdate,monname3.)!!' '!!left(year(sasdate));
	 if date2label='Nov 2009' then date2label2='Nov 2009';
	 if date2label='May 2010' then date2label2='May 2010';
	 if date2label='Nov 2010' then date2label2='Nov 2010';****most recent data pt;
run;



proc freq data=PhysicianMaster noprint; tables pname*physician / out=idformat;    
proc sort data=idformat; by physician descending count; run;
data idformat; set idformat; by physician;
     if first.physician;
     start=physician;
     label=pname;
     fmtname='pname';
proc format cntlin=idformat; run;
/*region*/
proc freq data=PhysicianMaster noprint; tables region*physician / out=ridformat;    
proc sort data=ridformat; by physician descending count; run;
data ridformat; set ridformat; by physician;
     if first.physician;
     start=physician;
     label=region;
     fmtname='rname';
proc format cntlin=ridformat; run;


LIBNAME GFONT0 'c:\CAT810';
data arrowfont;
   input char $ x y segment ptype $ lp $;
   CARDS;
C   0  50 1 V P
C  30  70 1 V P
C  35  65 1 V P
C  20  55 1 V P
C  65  55 1 V P
C  65  45 1 V P
C  20  45 1 V P
C  35  35 1 V P
C  30  30 1 V P
A   0  50 1 V P
A  30  80 1 V P
A  40  70 1 V P
A  27  57 1 V P
A  70  57 1 V P
A  70  43 1 V P
A  27  43 1 V P
A  40  30 1 V P
A  30  20 1 V P
>  70  50 1 V P
>  40  80 1 V P
>  30  70 1 V P
>  43  57 1 V P
>   0  57 1 V P
>   0  43 1 V P
>  43  43 1 V P
>  30  30 1 V P
>  40  20 1 V P 
D  50  70 1 V L
D  70  50 1 V L
D  50  30 1 V L
D  30  50 1 V L
D  50  70 1 V L
F  50  70 1 V P
F  70  50 1 V P
F  50  30 1 V P
F  30  50 1 V P
F  50  70 1 V P
;
proc gfont data=arrowfont
           name=arrow
           filled
           SHOWROMAN;
       *    NODISPLAY;
run;

*** Formats *************************************************************************;
proc format; 
     value $ regionf  
           'CU'     = 'Central Utah'
           'CV'     = 'Cache Valley'
           'SU'     = 'Southern Utah'
           'UCLDS'  = 'LDS Campus'
           'UCMAIN' = 'Salt Lake Clinic'
           'UCNSL'  = 'So. Davis/No. Salt Lake'
           'UCSSL'  = 'South Salt Lake'
           'UCCSL'  = 'Central Salt Lake'
           'UN'     = 'Weber/North Davis'
           'US'     = 'Utah Valley'
           other    = 'delete';                * region=PD or NON;
     value $ specf  
           'FP'     = 'Family Practice'
           'IM'     = 'Internal Medicine'
           'IMS'    = 'Medical Subspecialties'
           'MI'     = 'Midlevel Providers'
           'OB'     = 'Obstetrics and Gynecology'
           'PE'     = 'Pediatrics'
           'SU'     = 'Surgery'                     
            other    = 'Other';                * specialty=PD;
     value $ vlabelf 
           'NUCC'   = 'Caring and Concern Shown to You by the Nursing Staff' 
           'NUSK'   = 'Skills and Knowledge of the Nursing Staff'
           'NULI'   = 'How Well the Nursing Staff Listened to You and Understood Your Concerns'
           'REAC'   = 'How Promptly You Were Acknowledged by the Receptionists' 
           'REHE'   = 'Helpfulness of the Receptionists' 
           'WTAP'   = 'Being Able to Get an Appointment For When You Wanted to be Seen'
           'WTPH'   = 'Total Amount of Time You Spent Waiting'
           'PHLI'   = 'How Well the Physician Listened to You and Understood Your Concerns'
           'PHRE'   = 'Would Recommend this Physician   (1=Definitely No, 4=Definitely Yes)'
           'PHDT'   = 'Skills and Knowledge of the Physician'
           'PHCC'   = 'Caring and Concern Shown to You by the Physician';
run; 
  *** Individual Physicians *************************;
proc means data=PhysicianMaster(where=(physician ne 999999)) noprint nway; 
     class physician date2; 
     var AverageScore phcc phli phre phdt NUCC NUSK NULI REAC REHE WTAP WTPH;
     output out=PhysicianIndividual 
            mean= 
            var=VarAverageScore  Vphcc Vphli Vphre Vphdt 
                VNUCC VNUSK VNULI VREAC VREHE VWTAP VWTPH
              n=NAverageScore  Nphcc Nphli Nphre Nphdt 
                NNUCC NNUSK NNULI NREAC NREHE NWTAP NWTPH;
            id region specialty date2label date2label2 plname pname;
run; 
 
proc sort data=PhysicianIndividual out=fill; by physician descending date2;
data fill; set fill; by physician; if first.physician; 
     if first.physician; 
     if date2 ne 201011 then delete; 
     if _freq_ => &threshold;        
     keep physician date2;
	 date2=201011; output;
	 date2=201005; output;
	 date2=200911; output;
	 run;
proc sort; by physician date2;
run;
Data PhysicianIndividual; merge PhysicianIndividual fill(in=a); by physician date2;
     if a;
run;
/**/
  
proc sort data=PhysicianIndividual out=PhysicianSorted(keep=plname physician);
     by physician;
data PhysicianSorted; set PhysicianSorted; by physician;
     if last.physician;
     pname=put(physician,pname.);
proc sort; by plname pname;
run;
data null_; set physiciansorted;
     if plname='' then delete;;
     put '%PhysRep(' physician 5. ');      *' pname ';'; 
run;


  *** Physician Division ****************************;
proc means data=PhysicianMaster(where=(region ne 'NON')) noprint nway; class date2; 
     var AverageScore phcc phli phre phdt NUCC NUSK NULI REAC REHE WTAP WTPH;
     output out=PhysicianDivision 
            mean=DMAverageScore DMphcc DMphli DMphre DMphdt 
                 DMNUCC DMNUSK DMNULI DMREAC DMREHE DMWTAP DMWTPH 
            var=DVAverageScore DVphcc DVphli DVphre DVphdt 
                 DVNUCC DVNUSK DVNULI DVREAC DVREHE DVWTAP DVWTPH 
              N=DN;
              id date2label date2label2;
run;   

  *** Physician Region ****************************;
proc means data=PhysicianMaster(where=(REGION ne 'PD')) noprint nway; class region date2; 
     var AverageScore phcc phli phre phdt NUCC NUSK NULI REAC REHE WTAP WTPH;
     output out=PhysicianRegion 
            mean=RMAverageScore RMphcc RMphli RMphre RMphdt 
                 RMNUCC RMNUSK RMNULI RMREAC RMREHE RMWTAP RMWTPH 
            var=RVAverageScore RVphcc RVphli RVphre RVphdt 
                 RVNUCC RVNUSK RVNULI RVREAC RVREHE RVWTAP RVWTPH 
              N=RN RNphcc RNphli RNphre RNphdt 
                 RNNUCC RNNUSK RNNULI RNREAC RNREHE RNWTAP RNWTPH ;
              id date2label date2label2;
run;   

  *** Physician Specialty ****************************;
proc means data=PhysicianMaster(where=(SPECIALTY ne 'PD')) noprint nway; class specialty date2; 
     var AverageScore phcc phli phre phdt NUCC NUSK NULI REAC REHE WTAP WTPH;
     output out=PhysicianSpecialty 
            mean=SMAverageScore SMphcc SMphli SMphre SMphdt 
                 SMNUCC SMNUSK SMNULI SMREAC SMREHE SMWTAP SMWTPH 
            var=SVAverageScore SVphcc SVphli SVphre SVphdt 
                 SVNUCC SVNUSK SVNULI SVREAC SVREHE SVWTAP SVWTPH 
              N=SN SNphcc SNphli SNphre SNphdt 
                 SNNUCC SNNUSK SNNULI SNREAC SNREHE SNWTAP SNWTPH ;
              id date2label date2label2;
run;   

*************************************************************************************;;;

data  Work.PhysicianMasterAll; set PhysicianMaster;
	physician=99900; specialty=.; region=.; pname=.;
run;

data  Work.PhysicianMasterSpec; set PhysicianMaster(where=(specialty="&specialty" ));
	physician=99955;  region=.; pname=.;
run;

data  Work.PhysicianMaster; set Work.PhysicianMaster  Work.PhysicianMasterAll Work.PhysicianMasterSpec; run;


PROC SORT data=Work.PhysicianMaster out=work.PPQBase2; 
  BY physician pname specialty date2 SURVEY;
   
run;

* Delete any old subset data;       
Data _null_;
  if (exist('Work.Subset')) 
     then call execute('proc datasets library=work; delete subset; run; quit;');
run;

* Create new subset data;       
%macro respfreq(mvar);
    Proc freq data=work.ppqbase2(where=(&mvar gt .))   noprint; 
       tables &mvar / 
         out=TempPhys(rename=(&mvar=response count=&mvar));
    BY physician pname specialty region date2 SURVEY;
     %if not %sysfunc(exist(work.Subset)) %then %do;  
      data subset;
        set TempPhys; by physician pname specialty region date2 SURVEY response;
      run;
    %end;
    %else %do;
      data subset;
         merge subset TempPhys;
         by physician pname specialty region date2 SURVEY response;
         label &mvar="&mvar";
      run;
    %end;
   
%mend respfreq;
     
%respfreq(phcc);  %respfreq(phli);  %respfreq(phre);  %respfreq(phdt); %respfreq(NUCC);
%respfreq(NUSK);  %respfreq(NULI);  %respfreq(REAC);  %respfreq(REHE);  
%respfreq(WTAP);  %respfreq(WTPH);  
 
   data subset;
     set subset;
     label response='RESPONSE'; drop percent;
   run;


