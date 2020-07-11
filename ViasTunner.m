% example demonstrating the use of a stripline terminated by the pml
% (c) 2013 Thorsten Liebig

close all
clear
clc

%% setup the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
physical_constants;
unit = 1e-6; % specify everything in um
SIW.FL=5e3;
SIW.LX = 10e3;
SIW.LY = 600;
SIW.CT=36e-6;
SIW.CC=41e6;
SIW.SH = 254;
SIW.epr = 3.66;
SIW.VR=1e3;
f_start = 1e8;
f_stop  = 6e9;

SIW.lambda = c0/(f_stop*unit);
%% setup FDTD parameters & excitation function %%%%%%%%%%%%%%%%%%%%%%%%%%%%
FDTD = InitFDTD('NrTS', 1e9,'endCriteria',1e-4);
FDTD = SetGaussExcite(FDTD,0.5*(f_start+f_stop),0.5*(f_stop-f_start));
BC   = {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PEC' 'PML_8'};
FDTD = SetBoundaryCond( FDTD, BC );
%% setup CSXCAD geometry & mesh %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CSX = InitCSX();
resolution = c0/(f_stop*sqrt(SIW.epr))/unit /10; % resolution of lambda/50
mesh.x =SmoothMeshLines( [(-SIW.LX-SIW.FL-SIW.lambda/2)*2  (SIW.LX+SIW.FL+SIW.lambda/2)*2], resolution/1, 1.4 ,0 );
mesh.y =SmoothMeshLines( [ -SIW.LY*2-SIW.lambda/2  SIW.LY*2+SIW.lambda/2], resolution/1, 1.4 ,0 );
mesh.z = SmoothMeshLines( [0 SIW.SH 4*SIW.SH SIW.lambda/2], resolution/1, 1.4 ,0 );
CSX = DefineRectGrid( CSX, unit, mesh );
[CSX mesh] = CreateSIW(CSX, mesh, SIW, resolution/1);
mesh = SmoothMesh(mesh, resolution, 1.5, 'algorithm',[1 3]);

%% FeedingPorts
portstart = [ -SIW.FL-SIW.LX/2, -SIW.LY/2, SIW.SH];
portstop  = [ -SIW.LX/2,         SIW.LY/2, 0];
[CSX,port{1}] = AddMSLPort( CSX,900, 1, 'copper', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', 10*resolution, 'MeasPlaneShift',  SIW.FL/1);

portstart = [ SIW.FL+SIW.LX/2, -SIW.LY/2, SIW.SH];
portstop  = [ SIW.LX/2,         SIW.LY/2, 0];
[CSX,port{2}] = AddMSLPort( CSX, 900, 2, 'copper', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  SIW.FL/1);
%%  write/show/run the openEMS compatible xml-file
Sim_Path = 'tmp';
Sim_CSX = 'vias.xml';

[status, message, messageid] = rmdir( Sim_Path, 's' ); % clear previous directory
[status, message, messageid] = mkdir( Sim_Path ); % create empty simulation folder

WriteOpenEMS( [Sim_Path '/' Sim_CSX], FDTD, CSX );
CSXGeomPlot( [Sim_Path '/' Sim_CSX] );
RunOpenEMS( Sim_Path, Sim_CSX ,'');

%% post-processing
close all
f = linspace( 1e6, f_max, 1601 );
port = calcPort( port, Sim_Path, f, 'RefImpedance', 50);

s11 = port{1}.uf.ref./ port{1}.uf.inc;
s21 = port{2}.uf.ref./ port{1}.uf.inc;

plot(f/1e9,20*log10(abs(s11)),'k-','LineWidth',2);
hold on;
grid on;
plot(f/1e9,20*log10(abs(s21)),'r--','LineWidth',2);
legend('S_{11}','S_{21}');
ylabel('S-Parameter (dB)','FontSize',12);
xlabel('frequency (GHz) \rightarrow','FontSize',12);
ylim([-40 2]);

%% extract parameter
A = ((1+s11).*(1-s11) + s21.*s21)./(2*s21);
C = ((1-s11).*(1-s11) - s21.*s21)./(2*s21) ./ port{2}.ZL;

Y = C;
Z = 2*(A-1)./C;

iZ = imag(Z);
iY = imag(Y);

fse = interp1(iZ,f,0);
fsh = interp1(iY,f,0);

df = f(2)-f(1);
fse_idx = find(f>fse,1);
fsh_idx = find(f>fsh,1);

LR = 0.5*(iZ(fse_idx)-iZ(fse_idx-1))./(2*pi*df);
CL = 1/(2*pi*fse)^2/LR;

CR = 0.5*(iY(fsh_idx)-iY(fsh_idx-1))./(2*pi*df);
LL = 1/(2*pi*fsh)^2/CR;

disp([' Series tank: CL = ' num2str(CL*1e12,3) 'pF;  LR = ' num2str(LR*1e9,3) 'nH -> f_se = ' num2str(fse*1e-9,3) 'GHz ']);
disp([' Shunt  tank: CR = ' num2str(CR*1e12,3) 'pF;  LL = ' num2str(LL*1e9,3) 'nH -> f_sh = ' num2str(fsh*1e-9,3) 'GHz ']);

 

