%annomac;

/*data annopage6;
     xsys='2'; ysys='2';
     length color function $8;
     color='white'; size=.1;
     function='move';  x=100; y=100; output;
     function='label'; text='page intentionaly left blank';
         page='page 6';
output;	*/


data allanno;
*     set annopage3 annopage4;
*     set annopage1 annopage2 annopage3;
*     set annopage1 annopage2 annopage6 annopage4 annopage5;
*     set annopage1 annopage2 annopage3 annopage4 annopage5 annopage6;
     set annopage1 annopage2 annopage3 annopage4 annopage5 annopage6;
by page;
run;
proc ganno anno=allanno name=page;
run;

