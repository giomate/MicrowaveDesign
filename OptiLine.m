close all
clear
clc
w0=3.55e+03;
l0=4.76e+03;
fl0=9.28e3;

x0=[ w0 l0 fl0];
fun=@CouplingLine;
options = optimset('Display','iter','PlotFcns',@optimplotfval);
[x,fval,exitflag,output] = fminsearch(fun,x0,options)