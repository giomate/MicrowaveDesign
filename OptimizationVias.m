close all
clear
clc
w0=5.673679733466199e+03;
l0=5.503524652657308e+04;
r0=98.469359458624040;
x0=[w0 l0 r0];
fun=@Vias;
options = optimset('Display','iter','PlotFcns',@optimplotfval);
[x,fval,exitflag,output] = fminsearch(fun,x0,options)