close all
clear
clc
w0=3.57e+03;
l0=8e+03;
s0=3.57e3;
r0=7.34e3;
gap0=127;
res0=24;
x0=[r0 s0 w0 l0 gap0 res0];
fun=@Ring1;
options = optimset('Display','iter','PlotFcns',@optimplotfval);
[x,fval,exitflag,output] = fminsearch(fun,x0,options)