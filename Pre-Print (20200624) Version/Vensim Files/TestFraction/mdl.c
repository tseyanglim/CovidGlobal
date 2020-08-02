/*(Mon Jun 15 12:06:12 2020) From TestFractionFunction.mdl - C equations for the model */
#include "simext.c"
static COMPREAL temp0,temp1,temp2,temp3,temp4,temp5,temp6,temp7,temp8
,temp9,temp10,temp11,temp12,temp13,temp14,temp15,temp16,temp17,temp18
,temp19,temp20,temp21,temp22,temp23,temp24,temp25,temp26,temp27,temp28
,temp29,temp30,temp31,temp32,temp33,temp34,temp35,temp36,temp37,temp38
,temp39,temp40,temp41,temp42,temp43,temp44,temp45,temp46,temp47,temp48
,temp49,temp50,temp51,temp52,temp53,temp54,temp55,temp56,temp57,temp58
,temp59,temp60,temp61,temp62,temp63,temp64,temp65,temp66,temp67,temp68
,temp69,temp70,temp71,temp72,temp73,temp74,temp75,temp76,temp77,temp78
,temp79,temp80,temp81,temp82,temp83,temp84,temp85,temp86,temp87,temp88
,temp89,temp90,temp91,temp92,temp93,temp94,temp95,temp96,temp97,temp98
,temp99,temp100,temp101,temp102,temp103,temp104,temp105,temp106,temp107
,temp108,temp109,temp110,temp111,temp112,temp113,temp114,temp115,temp116
,temp117,temp118,temp119,temp120,temp121,temp122,temp123,temp124,temp125
,temp126,temp127,temp128,temp129,temp130,temp131 ;
static int sumind0,forind0 ; 
static int sumind1,forind1 ; 
static int sumind2,forind2 ; 
static int sumind3,forind3 ; 
static int sumind4,forind4 ; 
static int sumind5,forind5 ; 
static int sumind6,forind6 ; 
static int sumind7,forind7 ; 
static int simultid ;
static int sub0[]  /* expnt */ = {0,1,2,-1} ;
static int sub1[]  /* Rgn */ = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,
37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,
59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,-1} ;
static int sub2[]  /* TstSts */ = {0,1,-1} ;
#ifndef LINKEXTERN
#endif
unsigned char *mdl_desc()
{
return("(Mon Jun 15 12:06:12 2020) From TestFractionFunction.mdl") ;
}

/* compute the model rates */
void mdl_func0()
{double temp[10];
VGV->RATE[0] = 1.0 ;/* this is time */
/* #Recent Detected Infections>SMOOTHI# */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1+sub1[forind0]*1 ;
  VGV->RATE[1+sub1[forind0]*1] = (VGV->LEVEL[2504+sub1[forind0]*1]
-VGV->LEVEL[1+sub1[forind0]*1])/VGV->LEVEL[3524] ;
} /* #Recent Detected Infections>SMOOTHI# */

} /* comp_rate */

/* compute the delays */
void mdl_func1()
{double temp[10];
/* Reaching Testing Gate */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 79+sub1[forind0]*1 ;
  VGV->RATE[79+sub1[forind0]*1] = DELAY_N_a(0+sub1[forind0]*1,VGV->LEVEL[1566
+sub1[forind0]*1],(VGV->LEVEL[1408]+VGV->LEVEL[2269])/2.000000) ;
} /* Reaching Testing Gate */

} /* comp_delay */

/* initialize time */
void mdl_func2()
{double temp[10];
vec_arglist_init();
VGV->LEVEL[0] = VGV->LEVEL[1722] ;
} /* init_time */

/* initialize time step */
void mdl_func3()
{double temp[10];
/* a constant no need to do anything */
} /* init_tstep */

/* State variable initial value computation*/
void mdl_func4()
{double temp[10];
/* #Recent Detected Infections>SMOOTHI# */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1+sub1[forind0]*1 ;
  VGV->LEVEL[1+sub1[forind0]*1] = (0) ;
}
/* Test Input Infection Rate */
 {
  VGV->lastpos = 3209 ;
  VGV->LEVEL[3209] = 0.001000*EXP(VGV->LEVEL[1565]/10.000000) ;
}
/* Infection Rate */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1566+sub1[forind0]*1 ;
  VGV->LEVEL[1566+sub1[forind0]*1] = VGV->LEVEL[3209]*VGV->LEVEL[1644
+sub1[forind0]*1]/100000.000000 ;
}
/* Reaching Testing Gate */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 79+sub1[forind0]*1 ;
  VGV->LEVEL[79+sub1[forind0]*1] = DELAY_N_i(135,79+sub1[forind0]*1,0
+sub1[forind0]*1,VGV->LEVEL[1566+sub1[forind0]*1],2.000000) ;
}
/* Covid Acuity */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 704+sub1[forind0]*1 ;
  VGV->LEVEL[704+sub1[forind0]*1] = VGV->LEVEL[939]*VGV->LEVEL[782
+sub1[forind0]*1] ;
}
/* Symptomatic Fraction in Poisson */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 2974+sub1[forind0]*1 ;
  VGV->LEVEL[2974+sub1[forind0]*1] = 1.000000-EXP((-VGV->LEVEL[704
+sub1[forind0]*1])) ;
}
/* Symptomatic Fraction Negative */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3052+sub1[forind0]*1 ;
  VGV->LEVEL[3052+sub1[forind0]*1] = 1.000000-EXP((-VGV->LEVEL[939
])) ;
}
} /* comp_init */

/* State variable re-initial value computation*/
void mdl_func5()
{double temp[10];
} /* comp_reinit */

/*  Active Time Step Equation */
void mdl_func6()
{double temp[10];
} /* comp_tstep */
/*  Auxiliary variable equations*/
void mdl_func7()
{double temp[10];
/* Recent Detected Infections */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 2738+sub1[forind0]*1 ;
  VGV->LEVEL[2738+sub1[forind0]*1] = VGV->LEVEL[1+sub1[forind0]*1]
 ;
}
/* Potential Test Demand from Susceptible Population */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 2582+sub1[forind0]*1 ;
  VGV->LEVEL[2582+sub1[forind0]*1] = VGV->LEVEL[1644+sub1[forind0]
*1]*VGV->LEVEL[2816+sub1[forind0]*1]*VGV->LEVEL[1330+sub1[forind0]
*1]+VGV->LEVEL[2191+sub1[forind0]*1]*POWER(VGV->LEVEL[2738+sub1[forind0]
*1],VGV->LEVEL[2896+sub1[forind0]*1]) ;
}
/* Covid Acuity */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 704+sub1[forind0]*1 ;
  VGV->LEVEL[704+sub1[forind0]*1] = VGV->LEVEL[939]*VGV->LEVEL[782
+sub1[forind0]*1] ;
}
/* Additional Asymptomatic Relative to Symptomatic */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 235+sub1[forind0]*1 ;
  VGV->LEVEL[235+sub1[forind0]*1] = ZIDZ(0,VGV->LEVEL[3525+sub1[forind0]
*1]-EXP((-VGV->LEVEL[704+sub1[forind0]*1])),1.000000-VGV->LEVEL[3525
+sub1[forind0]*1]) ;
}
/* Poisson Subset Reaching Test Gate */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 2270+sub1[forind0]*1 ;
  VGV->LEVEL[2270+sub1[forind0]*1] = VGV->LEVEL[79+sub1[forind0]*1
]/(1.000000+VGV->LEVEL[235+sub1[forind0]*1]) ;
}
/* Positive Candidates Interested in Testing Poisson Subset */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 2348+sub1[forind0]*1 ;
  VGV->LEVEL[2348+sub1[forind0]*1] = VGV->LEVEL[2270+sub1[forind0]
*1]*VGV->LEVEL[1330+sub1[forind0]*1] ;
}
/* Positive Candidates Interested in Testing Poisson Subset Adj */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 2426+sub1[forind0]*1 ;
  VGV->LEVEL[2426+sub1[forind0]*1] = MAX(0.001000*VGV->LEVEL[2582+sub1[forind0]
*1],VGV->LEVEL[2348+sub1[forind0]*1]) ;
}
/* a */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 157+sub1[forind0]*1 ;
  VGV->LEVEL[157+sub1[forind0]*1] = XIDZ(0,VGV->LEVEL[2582+sub1[forind0]
*1],VGV->LEVEL[2426+sub1[forind0]*1],1.000000) ;
}
/* Test Input Testing Capacity */
 {
  VGV->lastpos = 3210 ;
  VGV->LEVEL[3210] = 0.001000*EXP(VGV->LEVEL[3208]/10.000000) ;
}
/* Testing Capacity Net of Post Mortem Tests */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3211+sub1[forind0]*1 ;
  VGV->LEVEL[3211+sub1[forind0]*1] = VGV->LEVEL[3210]*VGV->LEVEL[1644
+sub1[forind0]*1]/100000.000000 ;
}
/* Testing Demand */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3289+sub1[forind0]*1 ;
  VGV->LEVEL[3289+sub1[forind0]*1] = VGV->LEVEL[2348+sub1[forind0]
*1]*VGV->LEVEL[2974+sub1[forind0]*1]+VGV->LEVEL[2582+sub1[forind0]
*1]*VGV->LEVEL[3052+sub1[forind0]*1] ;
}
/* Testing on Living */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3367+sub1[forind0]*1 ;
  VGV->LEVEL[3367+sub1[forind0]*1] = MIN(VGV->LEVEL[3211+sub1[forind0]
*1],VGV->LEVEL[3289+sub1[forind0]*1]) ;
}
/* b */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 392+sub1[forind0]*1 ;
  VGV->LEVEL[392+sub1[forind0]*1] = ZIDZ(0,VGV->LEVEL[3367+sub1[forind0]
*1]-VGV->LEVEL[2426+sub1[forind0]*1]-VGV->LEVEL[2582+sub1[forind0]
*1],VGV->LEVEL[2426+sub1[forind0]*1]) ;
}
/* t3 */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3130+sub1[forind0]*1 ;
  VGV->LEVEL[3130+sub1[forind0]*1] = POWER(((-9.000000)*VGV->LEVEL[392
+sub1[forind0]*1]+1.732100*SQRT(4.000000*POWER(VGV->LEVEL[157+sub1[forind0]
*1],3.000000)+27.000000*POWER(VGV->LEVEL[392+sub1[forind0]*1],2.000000
))),(1.000000/3.000000)) ;
}
/* Ymix */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3759+sub1[forind0]*3+0*1 ;
  VGV->LEVEL[3759+sub1[forind0]*3+0*1] = (-VGV->LEVEL[392+sub1[forind0]
*1])/(1.000000+VGV->LEVEL[157+sub1[forind0]*1]) ;
}
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3759+sub1[forind0]*3+1*1 ;
  VGV->LEVEL[3759+sub1[forind0]*3+1*1] = (SQRT(POWER(VGV->LEVEL[157
+sub1[forind0]*1],2.000000)-4.000000*VGV->LEVEL[392+sub1[forind0]*1
])-VGV->LEVEL[157+sub1[forind0]*1])/2.000000 ;
}
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3759+sub1[forind0]*3+2*1 ;
  VGV->LEVEL[3759+sub1[forind0]*3+2*1] = ((-0.873580)*VGV->LEVEL[157
+sub1[forind0]*1])/VGV->LEVEL[3130+sub1[forind0]*1]+0.381570*VGV->LEVEL[3130
+sub1[forind0]*1] ;
}
/* lnymix */
for(forind0=0;forind0<78;forind0++)
for(forind1=0;forind1<3;forind1++)
 {
  VGV->lastpos = 1723+sub1[forind0]*3+sub0[forind1]*1 ;
  VGV->LEVEL[1723+sub1[forind0]*3+sub0[forind1]*1] = (-LN(MAX(1e-06
,1.000000-VGV->LEVEL[3759+sub1[forind0]*3+sub0[forind1]*1]))) ;
}
/* cft */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 470+sub1[forind0]*3+0*1 ;
  VGV->LEVEL[470+sub1[forind0]*3+0*1] = VGV->LEVEL[1723+sub1[forind0]
*3+0*1] ;
}
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 470+sub1[forind0]*3+1*1 ;
  VGV->LEVEL[470+sub1[forind0]*3+1*1] = VGV->LEVEL[1723+sub1[forind0]
*3+1*1]-VGV->LEVEL[1723+sub1[forind0]*3+0*1] ;
}
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 470+sub1[forind0]*3+2*1 ;
  VGV->LEVEL[470+sub1[forind0]*3+2*1] = (LN(MIN(100.000000,MAX(1e-06
,ZIDZ(0,VGV->LEVEL[1723+sub1[forind0]*3+2*1]-VGV->LEVEL[1723+sub1[forind0]
*3+0*1],VGV->LEVEL[1723+sub1[forind0]*3+1*1]-VGV->LEVEL[1723+sub1[forind0]
*3+0*1])/LN(2.000000))))) ;
}
/* Extrapolated Estimator */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 860+sub1[forind0]*1 ;
  VGV->LEVEL[860+sub1[forind0]*1] = IF_THEN_ELSE(VGV->LEVEL[782+sub1[forind0]
*1]>1.000000,VGV->LEVEL[470+sub1[forind0]*3+0*1]+VGV->LEVEL[470+sub1[forind0]
*3+1*1]*POWER((VGV->LEVEL[782+sub1[forind0]*1]-1.000000),VGV->LEVEL[470
+sub1[forind0]*3+2*1]),VGV->LEVEL[1723+sub1[forind0]*3+0*1]) ;
}
/* Y */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3681+sub1[forind0]*1 ;
  VGV->LEVEL[3681+sub1[forind0]*1] = MIN(1.000000,MAX(1e-06,1.000000
-EXP((-VGV->LEVEL[860+sub1[forind0]*1])))) ;
}
/* Prob Missing Symptm */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 2660+sub1[forind0]*1 ;
  VGV->LEVEL[2660+sub1[forind0]*1] = MAX(0,LN(VGV->LEVEL[3681+sub1[forind0]
*1])/VGV->LEVEL[939]+1.000000) ;
}
/* Indicated fraction negative demand tested */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1409+sub1[forind0]*1 ;
  VGV->LEVEL[1409+sub1[forind0]*1] = 1.000000-EXP(VGV->LEVEL[939]*
(VGV->LEVEL[2660+sub1[forind0]*1]-1.000000)) ;
}
/* Indicated fraction positive demand tested */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1487+sub1[forind0]*1 ;
  VGV->LEVEL[1487+sub1[forind0]*1] = 1.000000-EXP(VGV->LEVEL[704+sub1[forind0]
*1]*(VGV->LEVEL[2660+sub1[forind0]*1]-1.000000)) ;
}
/* Tests on Negative Patients */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3445+sub1[forind0]*1 ;
  VGV->LEVEL[3445+sub1[forind0]*1] = VGV->LEVEL[3367+sub1[forind0]
*1]*ZIDZ(0,VGV->LEVEL[1409+sub1[forind0]*1]*VGV->LEVEL[2582+sub1[forind0]
*1],VGV->LEVEL[1409+sub1[forind0]*1]*VGV->LEVEL[2582+sub1[forind0]
*1]+VGV->LEVEL[1487+sub1[forind0]*1]*VGV->LEVEL[2348+sub1[forind0]
*1]) ;
}
/* Total Test on Covid Patients */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 3603+sub1[forind0]*1 ;
  VGV->LEVEL[3603+sub1[forind0]*1] = MAX(0,MIN(VGV->LEVEL[2348+sub1[forind0]
*1],VGV->LEVEL[3367+sub1[forind0]*1]-VGV->LEVEL[3445+sub1[forind0]
*1])) ;
}
/* Fraction Interested not Tested */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1096+sub1[forind0]*1 ;
  VGV->LEVEL[1096+sub1[forind0]*1] = 1.000000-ZIDZ(0,VGV->LEVEL[3603
+sub1[forind0]*1],VGV->LEVEL[2348+sub1[forind0]*1]) ;
}
/* Average Acuity of Correctly Tested */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 313+sub1[forind0]*1 ;
  VGV->LEVEL[313+sub1[forind0]*1] = VGV->LEVEL[704+sub1[forind0]*1
]*XIDZ(0,(1.000000-VGV->LEVEL[2660+sub1[forind0]*1]*POWER(VGV->LEVEL[1096
+sub1[forind0]*1],2.000000)),1.000000-VGV->LEVEL[1096+sub1[forind0]
*1],2.000000*VGV->LEVEL[2660+sub1[forind0]*1]) ;
}
/* Fraction Interseted not Correctly Tested */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1174+sub1[forind0]*1 ;
  VGV->LEVEL[1174+sub1[forind0]*1] = 1.000000-(1.000000-VGV->LEVEL[1096
+sub1[forind0]*1])*VGV->LEVEL[2895] ;
}
/* Test Input Infection Rate */
 {
  VGV->lastpos = 3209 ;
  VGV->LEVEL[3209] = 0.001000*EXP(VGV->LEVEL[1565]/10.000000) ;
}
/* Infection Rate */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1566+sub1[forind0]*1 ;
  VGV->LEVEL[1566+sub1[forind0]*1] = VGV->LEVEL[3209]*VGV->LEVEL[1644
+sub1[forind0]*1]/100000.000000 ;
}
/* Fraction Infections Identified */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1018+sub1[forind0]*1 ;
  VGV->LEVEL[1018+sub1[forind0]*1] = VGV->LEVEL[2348+sub1[forind0]
*1]*(1.000000-VGV->LEVEL[1174+sub1[forind0]*1])/VGV->LEVEL[1566+sub1[forind0]
*1] ;
}
/* Average Fraction Infections Identified */
 {
  VGV->lastpos = 391 ;
    temp0 = 0.0 ;
for(sumind0=0;sumind0<78;sumind0++)
    temp0 += VGV->LEVEL[1018+sub1[sumind0]*1] ;
  VGV->LEVEL[391] = temp0/(COMPREAL)78 ;
}
/* Flu Acuity Relative to Covid */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 940+sub1[forind0]*1 ;
  VGV->LEVEL[940+sub1[forind0]*1] = VGV->LEVEL[939]/VGV->LEVEL[704
+sub1[forind0]*1] ;
}
/* Fraction of Additional Symptomatic */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 1252+sub1[forind0]*1 ;
  VGV->LEVEL[1252+sub1[forind0]*1] = VGV->LEVEL[235+sub1[forind0]*1
]/(1.000000+VGV->LEVEL[235+sub1[forind0]*1]) ;
}
/* lnymix 0 */
for(forind0=0;forind0<78;forind0++)
for(forind1=0;forind1<3;forind1++)
 {
  VGV->lastpos = 1957+sub1[forind0]*3+sub0[forind1]*1 ;
  VGV->LEVEL[1957+sub1[forind0]*3+sub0[forind1]*1] = (-LN(MAX(1e-06
,1.000000-VGV->LEVEL[3759+sub1[forind0]*3+sub0[forind1]*1]))) ;
}
/* Positive Tests of Infected */
for(forind0=0;forind0<78;forind0++)
 {
  VGV->lastpos = 2504+sub1[forind0]*1 ;
  VGV->LEVEL[2504+sub1[forind0]*1] = VGV->LEVEL[2348+sub1[forind0]
*1]*(1.000000-VGV->LEVEL[1174+sub1[forind0]*1]) ;
}
} /* comp_aux */
int execute_curloop() {return(0);}
static void vec_arglist_init()
{
}
void VEFCC comp_rate(void)
{
mdl_func0();
}

void VEFCC comp_delay(void)
{
mdl_func1();
}

void VEFCC init_time(void)
{
mdl_func2();
}

void VEFCC init_tstep(void)
{
mdl_func3();
}

void VEFCC comp_init(void)
{
mdl_func4();
}

void VEFCC comp_reinit(void)
{
mdl_func5();
}

void VEFCC comp_tstep(void)
{
mdl_func6();
}

void VEFCC comp_aux(void)
{
mdl_func7();
}

