Sum the B array columns based on corresponding non-zero values in the A array and by group

   Two Solutions

        1. proc sql
        2. WPS proc R

    Paul Dorfman on end

        1. Datastep
        2. Hash

github
https://tinyurl.com/ydfbdhug
https://github.com/rogerjdeangelis/utl_sum_values_in_one_array_based_on_non_zero_values_in_another_aray_by_group

see
https://tinyurl.com/ybkha2wn
https://stackoverflow.com/questions/51097490/sas-sum-over-subset-of-a-table-column-multiple-times

INPUT
=====

             A Array                                   B Array                    |
                                                                                  |  If A9 = 1 then sum corresponding B9
 GRP  A1  A2  A3  A4  A5  A6  A7  A8  A9     B1  B2  B3  B4  B5  B6  B7  B8  B9   |  A9  B9
                                                                                  |
 CAT   1   0   1   0   0   0   0   0   1      5   4   7   2   1   6   6   8   8   |   1   8
 CAT   1   0   1   0   1   0   0   1   0      6   7   7   1   3   3   0   6   0   |   1       do not sum these becase
 CAT   0   0   0   0   1   1   0   1   0      6   1   3   8   5   5   0   7   2   |   0       A9 is not = 1
 CAT   0   1   1   0   0   0   1   0   1      5   0   7   1   7   5   8   3   2   |   0   2
 CAT   0   0   0   0   0   0   1   0   1      2   3   7   0   7   0   1   3   8   |   0   8
                                                                                         ==
                                                                                         18

 DOG   1   1   0   0   0   0   0   0   0      1   4   7   4   1   1   1   1   1   |   0
 DOG   1   0   0   1   1   0   0   1   1      8   0   6   3   6   2   0   1   1   |   1   1
 DOG   1   1   0   1   1   1   1   0   1      2   3   2   7   8   2   4   0   0   |   1   0
 DOG   0   1   1   1   1   1   0   0   0      3   5   5   3   1   5   5   8   5   |   0
                                                                                         ==

 EXAMPLE OUTPUT                                                                       1

 WORK.WANT total obs=2

 GRP    A1B1    A2B2    A3B3    A4B4    A5B5    A6B6    A7B7    A8B8    A9B9

 CAT     11       0      21       0       8       5       9      13      18
 DOG     11      12       5      13      15       7       4       1       1


PROCESS
=======

1. proc sql

  * very fast?;
  proc sql;
    create
       table want as
    select
       grp
       %array(abs,values=1-9)
      ,%do_over(abs,phrase=sum(A?*B?) as A?B?,between=comma)
    from
       sd1.have
    group
       by grp
  ;quit;


2. WPS proc R (working code)

   aggregate(have[,2:10]*have[,11:19],by=have[,1],sum);



OUTPUT
=====

 WORK.WANT total obs=2

   GRP    A1B1    A2B2    A3B3    A4B4    A5B5    A6B6    A7B7    A8B8    A9B9

   CAT     11       0      21       0       8       5       9      13      18
   DOG     11      12       5      13      15       7       4       1       1

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;


options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
 call streaminit(1234);
 retain grp;
 array as[9] a1-a9;
 array bs[9] b1-b9;
 do j=1 to 9;
 if j le 5 then grp='CAT';
 else grp='DOG';
 do i=1 to 9;
    as[i]= int(2*uniform(5831))  ;
    bs[i]= int(9*uniform(12334))  ;
 end;
 output;
 end;
 drop i j;
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

SQL see process

* WPS PROC R;

%utl_submit_wps64('
libname sd1 "d:/sd1";
options set=R_HOME "C:/Program Files/R/R-3.3.2";
libname wrk "%sysfunc(pathname(work))";
proc r;
submit;
source("C:/Program Files/R/R-3.3.2/etc/Rprofile.site", echo=T);
library(haven);
have<-read_sas("d:/sd1/have.sas7bdat");
wantwps<-aggregate(have[,2:10]*have[,11:19],by=have[,1],sum);
endsubmit;
import r=wantwps data=wrk.wantwps;
run;quit;
');

WANTWPS total obs=2

  GRP    A1    A2    A3    A4    A5    A6    A7    A8    A9

  CAT    11     0    21     0     8     5     9    13    18
  DOG    11    12     5    13    15     7     4     1     1


*____             _
|  _ \ __ _ _   _| |
| |_) / _` | | | | |
|  __/ (_| | |_| | |
|_|   \__,_|\__,_|_|

;

Paul Dorfman <sashole@bellsouth.net>
6:09 PM (13 hours ago)
 to SAS-L, me
Roger,

Methinks it's quite simple to take advantage of the fact that the A's have Boolean values and use a single DATA step:

data have ;
  call streaminit (5) ;
  do GRP = "MOU", "CAT", "DOG" ;
    do _n_ = 1 to ceil (rand ("uniform") * 17) ;
      array A A1-A9 ;
      array B B1-B9 ;
      do over A ;
        A = floor (rand ("uniform") * 2) ;
        B = floor (rand ("uniform") * 9) ;
      end ;
      if _n_ <= 7 then output ;
    end ;
  end ;
run ;

data want (keep = grp AB:) ;
  do until (last.grp) ;
    set have ;
    by GRP notsorted ;
    array A A: ;
    array B B: ;
    array AB AB1-AB9 ;
    do over A ;
      AB = sum (AB, A * B) ;
    end ;
  end ;
run ;

Or, we can let proc MEANS do the job by preceding it with a view (which will work regardless of whether the input is grouped or not):

data v (keep = grp AB:) / view = v ;
  set have ;
  array A A: ;
  array B B: ;
  array AB AB1-AB9 ;
  do over A ;
    AB = A * B ;
  end ;
run ;

proc means noprint nway data = v ;
  class grp ;
  var AB: ;
  output out = want (drop = _:) sum= ;
run ;

Best regards


Paul Dorfman via listserv.uga.edu
6:32 PM (13 hours ago)
 to SAS-L
On second thought, if the input data isn't grouped/sorted, the goal can be also attained by using a hash:

data _null_ ;
  set have end = z ;
  array A A: ;
  array B B: ;
  if _n_ = 1 then do ;
    dcl hash h (ordered:"A") ;
    h.definekey ("grp") ;
    h.definedata ("grp") ;
    do over A ;
      h.definedata (cats("AB",_i_)) ;
    end ;
    h.definedone () ;
  end ;
  array AB AB1-AB9 ;
  _iorc_ = h.find() ;
  do over AB ;
    if _iorc_ then AB = A * B ;
    else           AB + A * B ;
  end ;
  h.replace() ;
  if z then h.output (dataset: "want") ;


Roger DeAngelis            6:32 PM (13 hours ago)
Thanks Paul Minimal key strokes using ':' and do over, nice! Each method has ...

Roger DeAngelis            6:45 PM (13 hours ago)
One other point. Ah the Hash There is often very little loss in generality wi...

Paul Dorfman            8:52 PM (11 hours ago)
Pleasure, Roger. I must admit that I'm partial to the functionality of olde g...

Roger DeAngelis <rogerjdeangelis@gmail.com>
6:19 AM (1 hour ago)
to Paul, SAS-L
Good points

I suspect but do not know for sure.

  If the data is large, Teradata might sample the data and estimate the skew in the grouping
variable. It would use this skew information to assign cores to groups. Might even create an
index on the fly. I suspect it also depends on the complexity of the logic. I think SAS does some of this.


Click here to Reply, Reply to all, or Forward
3.68 GB (24%) of 15 GB used
Manage

