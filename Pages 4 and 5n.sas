%annomac;
 
%macro page4_5(Title,items,page,dsize);

%let text1 = 'Arial';  *swiss;   *Body;
%let text2 = 'Arial/bold';  *Header;
%let text3 = 'Arial/italic';  

  /*

  %let physician=3499;
  %let Title=Comparison of Other Questions;
  %let items=NUCC nusk nuli reac rehe wtap wtph;
  %let page=5;
  %let dsize=1.0;
  */
/* %let items=phcc phli phre phdt; */

data PIndividual;
     set subset(where=(physician=&physician) keep=physician specialty date2 response &items);
run;

data _null_; set PIndividual;
     if _n_=1 then call symput('specialty2',specialty);
run; 
data PSpecialty;
     set subset(where=(specialty=:"&specialty2")   
                 keep=physician specialty date2 response &items);
     *set subset(where=(physician=99955 and put(&group,&groupf)=:"&mgroup")  
                 keep=physician specialty date2 response &items);
	 physician=99955;
run;   
proc means noprint data=PSpecialty nway;
     class date2 response;
     var &items;
     output out=PSpecialty sum=;
	 id physician;
run; 
 
data POverall;
     set subset(where=(physician=99900)
                 keep=physician specialty region date2 response &items);
run;
proc means noprint data=POverall nway;
     class date2 response;
     var &items;
     output out=POverall sum=;
	 id physician;
run; 

/* create column names for nitems (n's), mitems (high response), and vitems (variance) column names */
data _null_;
     items="&items";
	 mitems=cat('m',tranwrd(items,' ',' m'));
	 nitems=cat('n',tranwrd(items,' ',' n'));
	 vitems=cat('v',tranwrd(items,' ',' v'));
	 call symput("mitems",mitems);
	 call symput("nitems",nitems);
	 call symput("vitems",vitems);

   * Overall;
	 Ritems=cat('R',tranwrd(items,' ',' R'));
	 RNitems=cat('RN',tranwrd(items,' ',' RN'));
	 RVitems=cat('RV',tranwrd(items,' ',' RV'));
	 call symput("Ritems",Ritems);
	 call symput("RNitems",RNitems);
	 call symput("RVitems",RVitems);

   * Specialty;
	 Sitems=cat('S',tranwrd(items,' ',' S'));
	 SNitems=cat('SN',tranwrd(items,' ',' SN'));
	 SVitems=cat('SV',tranwrd(items,' ',' SV'));
	 call symput("Sitems",Sitems);
	 call symput("SNitems",SNitems);
	 call symput("SVitems",SVitems);
run;  

/* populate nitems (n's), mitems (high response), and vitems (percent) columns */
/* code for questions with only 4 responses */
data PercentData; set PIndividual PSpecialty POverall; by physician date2;
     keep physician specialty region date2 Questions
          &items &nitems &vitems 
          &Sitems &SNitems &SVitems 
          &Ritems &RNitems &RVitems; 
     retain &nitems &mitems;
     array c(*) &items;
     array m(*) &mitems;
     array n(*) &nitems;
     array v(*) &vitems;

     array S(*) &Sitems;
     array SN(*) &SNitems;
     array SV(*) &SVitems;
     array R(*) &Ritems;
     array RN(*) &RNitems;
     array RV(*) &RVitems;
     Questions=dim(c);
	 do i=1 to Questions;
	    if i=1 then m(i)=0;
	    if vname(c(i)) =  'phre' and response=4 then m(i)=c(i);  /* outstanding only */
	    if vname(c(i)) ne 'phre' and response=5 then m(i)=c(i);  /* outstanding only */
	    if first.date2 then n(i)=0; n(i)=sum(of n(i) c(i));
		c(i)=m(i)/n(i); 
		v(i)=( c(i)*(1-c(i)) )/n(i);
		S(i)=C(i); SN(i)=n(i); SV(i)=v(i);
		R(i)=C(i); RN(i)=n(i); RV(i)=v(i);
	 end;
	 if last.date2; 
run; 
data PercentData2;
      merge PercentData(keep=physician Questions &Ritems &RNitems &RVitems date2 where=(physician=99900))
            PercentData(keep=physician &Sitems &SNitems &SVitems date2 where=(physician=99955))
            PercentData(keep=physician &items &nitems &vitems    date2 where=(physician=&physician))
           ; by date2; 
	 physician=&physician;
     sasdate=mdy(substr(left(date2),5,2),1,substr(left(date2),1,4));
	 date2label=put(sasdate,monname3.)!!' '!!left(year(sasdate));
proc sort; by descending date2;
run;

data PercentData2; set PercentData2;
     retain obs 0;
	 obs+1;
	 call symput('QuestionCount',questions);
run;

data annopage&page; set PercentData2;
   length function color style $25 label L text $200 text1 text2 text3 $100;
   retain StartBarsY 5 EndBarsY 80  Yposition 10
          StartBarsX 30 EndBarsX 95  
          BarToSpaceRatio   .55      /* Space between bars           */
          BarToSpaceRatio2  .2       /* Space between groups of bars */
          xsys ysys '3'
          signif 1.645; ** .2 = 1.282 , .1 = 1.645 , .05 = 1.96 ;

   if &QuestionCount=4 then do; BarToSpaceRatio=.55; BarToSpaceRatio2=.2; end;
   if &QuestionCount=7 then do; BarToSpaceRatio=.45; BarToSpaceRatio2=.4; end;
   color='Black'; 
   spacecalc=(&QuestionCount*3 + (&QuestionCount-1));
   spacecalc=(&QuestionCount*3 + BarToSpaceRatio2*(&QuestionCount-1));
   BarWidth=((EndBarsY-StartBarsY)*BarToSpaceRatio)/(spacecalc); * Width of Bars;
   BarSpace=((EndBarsY-StartBarsY)*(1-BarToSpaceRatio))/(spacecalc+1); * Space between bars;
   BarSpace=(BarWidth*(1-BarToSpaceRatio));
      if  &QuestionCount=4 then BarWidth=BarWidth*.75;
   /* Headers and Titles */
   if _n_=1 then do;
     function='label'; color='black'; style="&text1"; 
        x=95; y=99.5; style="&text1" ;  position='5'; text='CHART';    size=0.6; output;  
        x=95; y=97; style="&text2";  position='5'; text="&page";    size=3.0; output;
        color='red';
        x=55; y=97; style="&text2";  position='6'; text=put(physician,pname.); size=0.8; output;
        color='black';
        x=55; y=95.5; style="&text1";  position='6'; text="Region: &region";  size=0.8; output;
        x=55; y=94; style="&text1";  position='6'; 
              if ("&specialty"='Surgery' or "&specialty"='Medical Subspecialties')
                 and &page=2 then  
                    text="Specialty: %trim(&specialty)*"; 
                    else text="Specialty: &specialty";
              size=0.8; output;
        x=50; y=88; style="&text2";  position='B'; 
              text="&Title";
              size=1.8; output;      position='E';
              text='Compared with Previous Two Years';
              size=1.4; *output;
       function='label'; x=50; y=85; position='5'; style="&text3"; size=.7;
       color='blue';
           text='Blue indicates a statistically significant difference '!!
                'between that score and your November 2011 score';
                output;

           line=1; color='black';
       y=EndBarsY+.9;  
       x=StartBarsX-3; text='Your';   position='B'; size=.8; style="&text1"; output;
       x=StartBarsX-3; text='Scores'; position='E'; size=.8; style="&text1"; output;
    end;

       /* X axis labels */
       do i= 0 to 1 by .1;
          size=.8; color='black';
          position='8'; x=(StartBarsX-.5) + (i * (EndBarsX-StartBarsX)); y=StartBarsY;
          function='label'; text=put(i,percent7.); 
          style="&text1"; output;
          position='5'; size=1;                              * reset parms;
       end;
       color='black'; size=5;
       function='move'; x=StartBarsX; y=StartBarsY; output;  * x axis line;
       function='draw'; x=EndBarsX  ;               output;
       function='move'; x=StartBarsX; y=StartBarsY; output;  * y axis line;
       function='draw'; y=EndBarsY  ;               output;
    

   size=1;
   Yposition=StartBarsY+Barspace;
   Yposition=EndBarsY-Barspace;
   array   q(&QuestionCount) &items;              * Question high responses;         
   array   v(&QuestionCount) &Vitems;             * Question variances;              
   array  vn(&QuestionCount) &Nitems;             * Question N;                      
   array  rm(&QuestionCount) &Ritems;             * Overall percent high responses;
   array  rv(&QuestionCount) &RVitems;            * Overall variances of questions;
   array rn2(&QuestionCount) &RNitems;            * Overall N questions;
   array  sm(&QuestionCount) &Sitems;             * Specialty percent high response;
   array  sv(&QuestionCount) &SVitems;            * Specialty variances of questions;
   array sn2(&QuestionCount) &SNitems;            * Specialty N questions;
   do i=1 to &QuestionCount;
          call vname(q(i),l); label=put(upcase(l),$vlabelf.); 
          Yposition=EndBarsY-(&QuestionCount*(i-1)*(BarSpace+BarWidth))
             -(obs)*(BarSpace+BarWidth);              
          Yposition=EndBarsY - ((4*i-4)*BarWidth + (4*i-3)*BarSpace)  
            - obs*(BarToSpaceRatio2*BarSpace+BarWidth) 
            - (obs*1)*(&QuestionCount=4) - (obs*.7)*(&QuestionCount=7)
            - (&QuestionCount*(i-1)*1.0*(&QuestionCount=4))
            - (&QuestionCount*(i-1)*0.29*(&QuestionCount=7));
          response=q(i);
          ScaleResponse=abs(((q(i)-0)/(1))*(EndBarsX-StartBarsX));

         lag1percent=lag1(q(i)); lag1var=lag1(v(i)); lag1n=lag1(vn(i));
         lag2percent=lag2(q(i)); lag2var=lag2(v(i)); lag2n=lag2(vn(i));
         if obs=2 then
			 ptest=(q(i)-lag1percent) /(lag1var+v(i))**.5;
          if obs=2 then
             put label / ptest= lag1mean= q(i)= lag1var= lag1n= v(i)= vn(i)= +2 '************';

          if obs=3 then
			 ptest=(q(i)-lag2percent) /(lag2var+v(i))**.5;
          if obs=3 then
             put label / ptest= lag2mean= q(i)= lag2var= lag2n= v(i)= vn(i)= +2 '************';
          if obs=1 then color='RED'; 
             else do; 
                  color='H078EEFF'; line=0; 
                  if abs(ptest)>signif then color='blue';
             end; 
          function='move'; y=Yposition;   x=StartBarsX; style='Solid';output;
          function='bar';  y=y+BarWidth;  x=StartBarsX+Scaleresponse; output;  * response bars;
             x=StartBarsX; y=Yposition; color='Black'; style='Empty'; output;  * black outline;
          /* Bar means */
             function='label'; style="&text1"; size=.8; 
          y=Yposition+.5*BarWidth+.5;  
          x=StartBarsX-5; text=put(response,percent7.1); position='6'; output;
          x=StartBarsX-9; text=left(date2label); position='4'; size=.8; output;
          if obs=1 then do;
             when='A';
             *** Overall Triangle ****;
             *OverallAverage=((rm(i)-3)/(5-3))*(EndBarsX-StartBarsX);
			 OverallAverage=abs(((rm(i)-0)/(1))*(EndBarsX-StartBarsX));
             function='poly'; 
                 x=StartBarsX+OverallAverage; y=Yposition+.5*BarWidth;
                 Ovrptest=(q(i)-rm(i))/(((q(i)*(1-q(i)))/vn(i)) + ((rm(i)*(1-rm(i)))/rn2(i)))**.5; 
                 if abs(OvrPTest)>signif then color='Blue'; else color='H000BF00';
				 style='MS';
                 output;
             function='polycont';  color='black';
               x=StartBarsX+OverallAverage+.5*BarWidth;
               y=Yposition;
               output;      
             function='polycont';  color='black';
               x=StartBarsX+OverallAverage-.5*BarWidth;
               y=Yposition;
               output;      
             function='polycont'; 
               x=StartBarsX+OverallAverage; 
               y=Yposition+.5*BarWidth;
               output;
             function='label';
               x=StartBarsX+OverallAverage;
               y=Yposition-.5*BarWidth+1.2*(&QuestionCount=4)
                                      +.5*(&QuestionCount=7);
               text='Med Group Pct'; size=.5; style="&text1"; position='5'; color='black';
               output;

             *** Specialty Triangle ****;
             *SpecialtyAverage=((sm(i)-3)/(5-3))*(EndBarsX-StartBarsX);
			 SpecialtyAverage=abs(((sm(i)-0)/(1))*(EndBarsX-StartBarsX));

             function='poly'; 
                 x=StartBarsX+SpecialtyAverage; y=Yposition+.5*BarWidth;
                 Specptest=(q(i)-sm(i))/(((q(i)*(1-q(i)))/vn(i)) + ((sm(i)*(1-sm(i)))/sn2(i)))**.5; 
                 if abs(Specptest)>signif then color='Blue'; else color='H000BF00';
***279*********************************************************************;
	   put Specptest= sm(i)= q(i)= sv(i) sn2(i)= v(i)= vn(i)=;
      *Specptest=(sm(i)-q(i))/((sv(i)/sn2(i)) + (v(i)/vn(i)))**.5; 
***************************************************************************;
				 style='MS';
                 output;
             function='polycont';  color='black';
               x=StartBarsX+SpecialtyAverage+.5*BarWidth;
               y=Yposition+BarWidth;
               output;      
             function='polycont';  color='black';
               x=StartBarsX+SpecialtyAverage-.5*BarWidth;
               y=Yposition+BarWidth;
               output;      
             function='polycont'; 
               x=StartBarsX+SpecialtyAverage; 
               y=Yposition+.5*BarWidth;
               output;
             function='label';
               x=StartBarsX+SpecialtyAverage;
               y=Yposition+BarWidth+.3;
               text='Specialty Pct'; /* text=''; */ size=.5; style="&text1"; position='B'; color='black';
               output;
             *** Question label ****;
             text=label; size=.8; color='black'; style="&text1"; x=(EndBarsX-startBarsX)/2;
             x=StartBarsX+4;
             position='5'; y=Yposition+BarWidth+BarSpace+.3; 
             position='C'; output;
          end;*if obs=1 then do;
   end;* do i=1 to &QuestionCount;

run;
data annopage&page; set annopage&page;
     page="page &page";
     size=size*(1.25/1.48);
run;
  /* proc ganno anno=annopage&page; run; */

%mend  page4_5;

%page4_5(Comparison of Physician Questions,phcc phli phre phdt,5,1.7);
%page4_5(Comparison of Other Questions,nucc nusk nuli reac rehe wtap wtph,6,1.0);


