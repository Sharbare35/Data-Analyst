%annomac;

%macro page2_3(Title,group,groupf,mgroup,mcompare,TestStat);

%let text1 = 'Arial';  *swiss;   *Body;
%let text2 = 'Arial/bold';  *Header;
%let text3 = 'Arial/italic';  

options ORIENTATION=portrait;

*dm log 'clear';          ** clear log******************************************;
  /*
%put &region &RegionAverage;
%let Title=Region Comparison;
%let group=Region;
%let groupf=$regionf.;
%let mgroup=&region;
%let page=2;
%let mcompare=&RegionAverage;
%let TestStat=RegT;
  */



proc sort data=physicianindividual
               (where=(put(&group,&groupf)=:"&mgroup" 
                  and date2=201111))
                out=AnnoPage&page; 
                by AverageScore;


run;;

/************************NEW Code From Volunteer Beginning***************************************************************;;
*** Comparitive Percentage Bar chart *******************************************; */



data subset2;
  set subset (where=(put(&group,&groupf)=:"&mgroup"  and (physician ne 99955)));
  if physician=0 then physician=.;		 
  if date2=201111;
run;;
data sharenone; set subset2; run;

data subset3; 						/*overall physician data*/
  set subset (where=(physician=99900));
  if physician=0 then physician=.;		 
  if date2=201111;
run;;

data subset4; 						/*specialty physician data*/
  set subset (where=(physician=99955));
  if physician=0 then physician=.;	 
  if date2=201111;
run;;

data subset5;
  set subset2 subset3 subset4;
run; 
data sharentwo; set subset5; run; /*yes - spec is doubled*/

proc means noprint data=subset5 nway missing;
  class physician pname;
  var &mvar ;
  output out=subsetN 
         sum=ResponseN ;
run;;

%if &mvar=PHRE %then %do;   
proc means noprint data=subset5 nway missing;
  class physician pname;
  var &mvar;
  output out=subset5 
         sum=&mvar ;
         id response date2;
  where response ge 4; *&maxresp;				  /* Outstanding only; */
run;
%end;
%else %do;
proc means noprint data=subset5 nway missing;
  class physician pname;
  var &mvar;
  output out=subset5 
         sum=&mvar ;
         id response date2;
  where response ge 5; *&maxresp;				  /* Outstanding only; */
run;
%end;


data AvePercent(where=(ResponseN ge &Threshold));
   merge subset5(keep=physician pname response date2 &mvar)
         subsetN(keep=physician pname ResponseN);
   by physician;		
   PercentHigh=&mvar/ResponseN;
   if (physician=&physician) then do;
      call symput('P1',PercentHigh);
	  call symput('N1',ResponseN);
   end;
run;

data AvePercentAll; set AvePercent	(where=(physician=99900));
		 call symput('PercentHighAll',PercentHigh);
	     call symput('PercentNAll',ResponseN);
run;
data AvePercentSpec; set AvePercent	(where=(physician=99955));
		 call symput('PercentHighSpec',PercentHigh);
	     call symput('PercentNSpec',ResponseN);
run;
data AvePercent; set AvePercent	(where=(physician<99900));
run;
%put &PercentNAll / &PercentHighAll / &PercentNSpec / &PercentHighSpec;


proc means data=AvePercent noprint;
   var PercentHigh;
   output out=percentMaxMin min=PercentMin
                         max=PercentMax;
run;
data _null_;
   set percentMaxMin;
   if percentmin gt .3 then percentmin=0; else percentmin=0;
   if percentmax lt .7 then percentmax=1; else percentmax=1;
   call symput('percentmin',percentmin);
   call symput('percentmax',percentmax);
   call symput('percentrange',percentmax-percentmin);
run;
%put &percentmin;	 %put &percentmax;	 %put &percentrange;
*****************************************************************************;
proc sort data=AvePercent; by PercentHigh;

proc sort data=AvePercent
               /*(where=(put(&group,&groupf)=:"&mgroup" 
                  and date2=201111)	*/
                out=AnnoPage&page; 
                by PercentHigh;


run;;


****************************NEW Code From Volunteer END***********************************************************;


data AnnoPage&page;
   set AnnoPage&page
       nobs=PhysicianCount end=eof;  
   doc+1;
   length function color style $25 text $200 text1 text2 text3 $100;
   retain StartBarsY  7 EndBarsY 77  Yposition 10
          StartBarsX 25 EndBarsX 90  
          BarToSpaceRatio .8 
          xsys ysys '3'
          FirstGrayBar LastGrayBar 1 FoundFirstBlueBar 0
          signif 1.645; ** .2 = 1.282 , .1 = 1.645 , .05 = 1.96 ;
   if physician=&physician then select=1;

if maxresp=5  then do; 
    range='2 to 5';
   LowScale=2;
  end; 	

/* SCALE ADJUSTMENTS */
/*   if maxresp=5  then do; 
     range='3 to 5';
       LowScale=3;   
  end;  */

  
  if maxresp=4  then do;
     range='2 to 4';
     LowScale=2;
  end;
  
  

   /* Determines significance difference in top box*/
	*scaleresponse=20;
	*ScaleResponse=((PercentHigh-LowScale)/(maxResp-LowScale))*(EndBarsX-StartBarsX);
   ScaleResponse=abs(((PercentHigh-0)/(1))*(EndBarsX-StartBarsX));

   *ScaleResponse=((AverageScore-3)/(5-3))*(EndBarsX-StartBarsX);
  *PhyT=(AverageScore-&PhysicianAverage)/
     ((VarAverageScore/NAverageScore)+(&PhysicianVar/&PhysicianN))**.5; 
  *DivT=(&DivisionAverage-&PhysicianAverage)/
     ((&DivisionVar/&DivisionN)+(&PhysicianVar/&PhysicianN))**.5;  
  *RegT=(&RegionAverage-&PhysicianAverage)/
     ((&RegionVar/&RegionN)+(&PhysicianVar/&PhysicianN))**.5;  
  *if select then put RegT " = &RegionAverage - &physicianAverage" / 
      "&RegionVar / &RegionN +( &PhysicianVar / &PhysicianN))**.5";  
  *SpeT=(&SpecialtyAverage-&PhysicianAverage)/
     ((&SpecialtyVar/&SpecialtyN)+(&PhysicianVar/&PhysicianN))**.5;   

    PhyT=(&p1-PercentHigh   )/(&p1*(1-&p1)/&n1 + PercentHigh*   (1-PercentHigh)/ResponseN)**.5;
    DivT=(&p1-&PercentHighAll)/(&p1*(1-&p1)/&n1 + &PercentHighAll*(1-&PercentHighAll)/&PercentNAll)**.5;
    SpeT=(&p1-&PercentHighSpec)/(&p1*(1-&p1)/&n1 + &PercentHighSpec*(1-&PercentHighSpec)/&PercentNSpec)**.5;
    if abs(PhyT)>signif then ItIsSig='Hey'; else ItIsSig='___';

   color='Black'; 
   if      50<=PhysicianCount    then WidthKeyBar=1.5;  ** Width of Physician Red Bar;
   else if 30<=PhysicianCount<50 then WidthKeyBar=2.0;
   else if 30<=PhysicianCount<50 then WidthKeyBar=3.0;
   else if 15<=PhysicianCount<30 then WidthKeyBar=3.0;
   else if     PhysicianCount<15 then WidthKeyBar=6.0;
   KeyBarSpace=1;

   BarWidth=((EndBarsY-StartBarsY-WidthKeyBar-2*KeyBarSpace)*BarToSpaceRatio)/
            (PhysicianCount);    * Width of Bars;
   BarSpace=((EndBarsY-StartBarsY-WidthKeyBar-2*KeyBarSpace)*(1-BarToSpaceRatio))/
            (PhysicianCount);    * Space between bars;
   if select=1 then do;
     function='label'; color='black'; style="&text1"; 
        x=95; y=99.5; style="&text1";  position='5'; text='CHART';    size=0.6; output;  
        x=95; y=97; style="&text2";  position='5'; text="&page";    size=3.0; output;
        color='red';
        x=55; y=97; style="&text2";  position='6'; text=put(physician,pname.); size=0.8; output;
        color='black';
        x=55; y=95.5; style="&text2";  position='6'; text="Region: &region";  size=0.8; output;
        x=55; y=94; style="&text1";  position='6'; 
              if ("&specialty"='Surgery' or "&specialty"='Medical Subspecialties')
                 and &page=2 then  
                    text="Specialty: %trim(&specialty)*"; 
                    else text="Specialty: &specialty";
              size=0.8; output;
        x=50; y=88; style="&text2";  position='B'; 
              text="&Title";
              size=2.0; output;      position='E';
              text="Compared with Physicians in Your &Group";
              size=2.0;* output;
        x=50; y=86; style="&text1";   position='5'; 
              text='Based on the Overall Score Which is an Average of the 3 Physician Rating Questions';
                                                                    size=1.0; *output;
        x=50; y=84.3; style="&text1";   position='5'; 
              text='(Caring and Concern, Skills and Knowledge, Listened) ';
                                                                    size=.6; *output;
																	x=50; y=86; style="&text1";   position='5'; 
               if "&mvar"='PHCC' then text='Caring and Concern Shown to You by the Physician';
		else if "&mvar"='PHDT' then text='Skills and Knowledge of the Physician';
		else if "&mvar"='PHLI' then text='How Well the Physician Listened to You and Understood Your Concerns';
		else if "&mvar"='PHRE' then text='Would Recommend this Physician   (1=Definitely No, 4=Definitely Yes)';
        size=2.0; output;
                                                         

       function='label'; x=50; y=82; position='5'; style="&text3"; size=.7;
           color='blue';
           text='Blue indicates a statistically significant difference between that '!!
                'score and your score'; output;
           y=EndBarsY+.3; x=50; position='2';
           text='Each bar represents an individual physician';  
           color='black'; style="&text1"; output;

       /* X axis labels */
	   increment=.1;
       do i= 0 to 1 by increment;
          size=.8; color='black';
          position='8'; x=(StartBarsX-.5) + (i * (EndBarsX-StartBarsX)); y=StartBarsY;
/*          position='8'; x=StartBarsX + ((i-lowscale)/(maxResp-lowscale)) * (EndBarsX-StartBarsX); y=StartBarsY; */
          function='label'; text=put(i,percent7.); 
          style="&text1"; output;
          position='5'; size=1.0; text="";                                        * reset parms;
       end;
       color='black'; size=4;
       function='move'; x=StartBarsX; y=StartBarsY; output;  * x axis line;
       function='draw'; x=EndBarsX  ;               output;
       function='move'; x=StartBarsX; y=StartBarsY; output;  * y axis line;
       function='draw'; y=EndBarsY  ;               output;
   end;

   /* Code to help detect non-contiguous significant bars */
      if Phyt>signif  then FirstGrayBar=doc;
	  if FoundFirstBlueBar=0 and Phyt>-signif then LastGrayBar =doc;
	  if Phyt<-signif then FoundFirstBlueBar=1;
	  /*
      if not FoundFirstGrayBar and Phyt>(signif) then do;
         FirstGrayBar=doc;
         FoundFirstGrayBar=1;
      end;
      if Phyt>(-signif) then LastGrayBar=doc;
	  */

   /* Response Bar */
   function='move'; size=1; color='black';
       if      _n_=1 and select then Yposition=StartBarsY+Barspace;
       else if _n_=1            then Yposition=StartBarsY+KeyBarSpace;
       else if           select then Yposition+KeyBarSpace-Barspace;
       y=Yposition;   x=StartBarsX;          output;
   function='bar'; 
       style='Solid'; color='H000BF00'; line=0;
       if abs(Phyt)>signif then color='blue';
       if select then do; style='Solid'; color='red'; end;
       if select then y=y+WidthKeyBar;
       else           y=y+BarWidth;
       x=StartBarsX+Scaleresponse; output;  
   x=StartBarsX; y=Yposition; color='Black'; style='Empty';   output;   * black outline;

   *** Average triangles ************************************************************;
   if select then do;
      line=1;
		DivPercentHigh=abs(((&PercentHighAll-0)/(1))*(EndBarsX-StartBarsX));
	  **;
      *DivisionAverage=((&DivisionAverage-3)/(5-3))*(EndBarsX-StartBarsX);
        when='A';
        function='poly'; 
          x=StartBarsX+DivPercentHigh; 
          y=Yposition+.5*WidthKeyBar; style='solid';
          if abs(Divt)>signif then color='Blue'; else color='H000BF00';  
          output;
        function='polycont';  color='black';
          x=StartBarsX+DivPercentHigh+.5*WidthKeyBar;
          y=Yposition+WidthKeyBar;      y=Yposition; 
          output;      
        function='polycont';  color='black';
          x=StartBarsX+DivPercentHigh-.5*WidthKeyBar;
          y=Yposition+WidthKeyBar;      y=Yposition; 
          output;      
        function='polycont'; 
          x=StartBarsX+DivPercentHigh; 
          y=Yposition+.5*WidthKeyBar;
          output;
        function='label';
          x=StartBarsX+DivPercentHigh;
          y=Yposition+WidthKeyBar+.3;     y=Yposition-.5*KeyBarSpace+.3;
          text='Med Group Pct'; size=.5; style="&text1"; position='5'; color='black';
          output;

		SpecPercentHigh=abs(((&PercentHighSpec-0)/(1))*(EndBarsX-StartBarsX));
        *&Group.Average = ((&Mcompare -3)/(5-3))*(EndBarsX-StartBarsX);
        function='poly'; 
          x=StartBarsX+SpecPercentHigh; 
          y=Yposition+.5*WidthKeyBar;   style='solid';
          if abs(&TestStat)>signif then color='blue'; else color='H000BF00';
          output;
        function='polycont';  color='black';
          x=StartBarsX+SpecPercentHigh+.5*WidthKeyBar;
          y=Yposition;             y=Yposition+WidthKeyBar;
          output;      
        function='polycont';
          x=StartBarsX+SpecPercentHigh-.5*WidthKeyBar;
          y=Yposition;             y=Yposition+WidthKeyBar;
          output;      
        function='polycont'; 
          x=StartBarsX+SpecPercentHigh; 
          y=Yposition+.5*WidthKeyBar;
          output;
        function='label';
          x=StartBarsX+SpecPercentHigh;
          y=Yposition-.5*KeyBarSpace+.3;   y=Yposition+WidthKeyBar+.3; 
          text="%trim(&Group) Pct"; size=.5; style="&text1"; position='B'; color='black';
          output;
          when='B';
   end;

   

   /* Bar means */
   /*function='label'; style="&text1"; size=.6; color='black'; 
      if select then y=Yposition+.5*(WidthKeyBar+KeyBarSpace);
                else y=Yposition+BarSpace+.5*(BarWidth);  
      x=StartBarsX-3; text=put(AverageScore,4.2); position='6'; output;
		  */

		  /* Bar Percent */
   function='label'; style="&text1"; size=.6; color='black'; 
      if select then y=Yposition+.5*(WidthKeyBar+KeyBarSpace);
                else y=Yposition+BarSpace+.5*(BarWidth);  
      x=StartBarsX-3; text=put(PercentHigh,percent7.1); position='6'; output;


   /* Your Score Arrow */
   if select then do;
      function='label'; size=1; style="&text2"; x=StartBarsX-18;
          text='Your Score';  position='6';  output;   
      style='Arrow'; text='>'; 
      x=StartBarsX-6;      
        position='6'; output;  
     *y=Yposition + .5*WidthKeyBar;
   end;
   
   else do;
   *****physician name;
  function='label'; size=.5; style="&text1"; x=StartBarsX-20;
  y=Yposition+BarSpace+.5*(BarWidth);
          text=put(physician,pname.);  position='6';  output; 

  *****region;
  function='label'; size=.5; style="&text1"; x=StartBarsX-8;
  y=Yposition+BarSpace+.5*(BarWidth);
          text=put(physician,rname.);  position='6';  output;
  end;


     /* Asterisk footnote */
     if ("&specialty"='Surgery' or "&specialty"='Medical Subspecialties') 
        and &page=2 then do; 
         function='label'; style="&text3"; size=0.65; x=10; y=2; position='6';
         if "&specialty"=:'Surgery' then 
            text='*General, Cardiovascular, Orthopedic, Otolaryngology, Plastic, Podiatry, Urology, etc.';
         if "&specialty"='Medical Subspecialties' then 
            text='*Allergy/Imm, Cardio, Derma, GI, Hem/Onc, Inf Disease, '!!
                 'Neuro, Ophth, Phys Med/Rehab, Pulm, Rheum, etc.';
         output;
     end;

   if select then Yposition + KeyBarSpace + WidthKeyBar;
             else Yposition + BarSpace    + BarWidth   ; 

   if eof then do;
      call symput('FirstGrayBar',FirstGrayBar);
      call symput('LastGrayBar',LastGrayBar);
   end;
run; 
%put &FirstGrayBar / &LastGrayBar;
   /* Adjust for bar significance not being contiguous */
    data AnnoPage&page; set AnnoPage&page end=eof;
       if doc<&FirstGrayBar and function='bar' and color='H000BF00' 
          then color='blue';
       if doc>&LastGrayBar  and function='bar' and color='H000BF00' 
          then color='blue';
     **size=size*.8;
		size=size; size=size*(1.25/1.48);
     page="page &page";
    run; 
%mend;

*%page2_3(Nov 2010 Region Comparison,Region,$regionf.,&region,1,&RegionAverage,RegT);
%page2_3(Nov 2011 Specialty Comparison,Specialty,$specf.,&specialty,   &SpecialtyAverage,SpeT);
 *      (Title,                                  group,  groupf,mgroup,mcompare,         TestStat);

