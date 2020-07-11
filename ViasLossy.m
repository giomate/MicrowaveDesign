function s4GHz=ViasLossy(w)
%

% examples / microstrip / MSL_Losses
%
% This example demonstrates how to model sheet conductor losses
%
% Tested with
%  - Matlab 2013a / Octave 3.8.1+
%  - openEMS v0.0.32
%
% (C) 2012-2014 Thorsten Liebig <thorsten.liebig@gmx.de>

close all
clear
clc

%% setup the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
physical_constants;
unit = 1e-6; % specify everything in um
MSL.length = 30e3;
MSL.port_dist = 10e3;
MSL.width =w;
MSL.conductivity = 41e6;
MSL.thickness = 35e-6;
SIW.VR=250;
substrate.thickness = 254;
substrate.epr = 3.6;
f_min=1e7;
f_start = f_min;
f_stop  = 8e9 + f_min;

lambda = c0/f_stop;

%% setup FDTD parameters & excitation function %%%%%%%%%%%%%%%%%%%%%%%%%%%%
FDTD = InitFDTD('endCriteria',1e-4);
FDTD = SetGaussExcite(FDTD,0.5*(f_stop-f_start),0.5*(f_start+f_stop));
BC   = {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PEC' 'PML_8'};
FDTD = SetBoundaryCond( FDTD, BC );

%% setup CSXCAD geometry & mesh %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CSX = InitCSX();
resolution = c0/(f_stop*sqrt(substrate.epr))/unit /20;
mesh.x = SmoothMeshLines( [-MSL.length/2-MSL.port_dist  MSL.length/2+MSL.port_dist], resolution/4, 1.3 ,0 );
mesh.y = SmoothMeshLines2( [0 MSL.width/2], resolution/8 , 1.3);
mesh.y = SmoothMeshLines( [-0.5*lambda/unit -mesh.y mesh.y 0.5*lambda/unit], resolution, 1.4);
mesh.z = SmoothMeshLines( [linspace(0,substrate.thickness,10) 0.5*lambda/unit], resolution );
CSX = DefineRectGrid( CSX, unit, mesh );

%% substrate
CSX = AddMaterial( CSX, 'RO4350B' );
CSX = SetMaterialProperty( CSX, 'RO4350B', 'Epsilon', substrate.epr );
start = [mesh.x(1),   mesh.y(1),   0];
stop  = [mesh.x(end), mesh.y(end), substrate.thickness];
CSX = AddBox( CSX, 'RO4350B', 0, start, stop );

%% MSL ports and lossy line
CSX = AddConductingSheet( CSX, 'copper', MSL.conductivity, MSL.thickness );
portstart = [ mesh.x(1),               -MSL.width/2, substrate.thickness];
portstop  = [ mesh.x(1)+MSL.port_dist,  MSL.width/2, 0];
[CSX, port{1}] = AddMSLPort( CSX, 999, 1, 'copper', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', 10*resolution, 'MeasPlaneShift',  MSL.port_dist);

portstart = [mesh.x(end),              -MSL.width/2, substrate.thickness];
portstop  = [mesh.x(end)-MSL.port_dist, MSL.width/2, 0];
[CSX, port{2}] = AddMSLPort( CSX, 999, 2, 'copper', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  MSL.port_dist );

start = [mesh.x(1)+MSL.port_dist,   -MSL.width/2, substrate.thickness];
stop  = [mesh.x(end)-MSL.port_dist,  MSL.width/2, substrate.thickness];
CSX = AddBox(CSX,'copper',500,start,stop);

% Copper Vias

CSX = AddMetal(CSX, 'via');
start = [0 0 substrate.thickness];
stop  = [0 0 0];
CSX = AddCylinder(CSX, 'via', 500, start, stop, (SIW.VR));
mesh.x = [mesh.x [-2 -1 -1/2  1/2 1 2]*SIW.VR];
mesh.y = [mesh.y [-2 -1 -1/2 1/2 1 2]*SIW.VR];

%% write/show/run the openEMS compatible xml-file
Sim_Path = 'tmp';
Sim_CSX = 'msl.xml';

[status, message, messageid] = rmdir( Sim_Path, 's' ); % clear previous directory
[status, message, messageid] = mkdir( Sim_Path ); % create empty simulation folder

WriteOpenEMS( [Sim_Path '/' Sim_CSX], FDTD, CSX );
%CSXGeomPlot( [Sim_Path '/' Sim_CSX] );
RunOpenEMS( Sim_Path, Sim_CSX ,'');

%% post-processing
close all
f = linspace( f_start, f_stop, 1601 );
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
s4GHz=20*log10(abs(s11(801)));
% [SMin, ind_fr]=min(S11ABS);
% if (ind_fr>1)
%     if (ind_fr<length(f))
%         SHigh=S11ABS(ind_fr+1:end);
%         SLow=S11ABS(1:ind_fr-1);
%     else
%         SHigh=SMin;
%         SLow=S11ABS(1:ind_fr-1);
%     end
% else
%       SHigh=S11ABS(ind_fr+1:end);
%       SLow=SMin;
% end
% 
% fh=length(SHigh)-sum(((SHigh-SMin)>3));
% fl=length(SLow)-sum(((SLow-SMin)>3));
% BW=f(fh+ind_fr)-f(fl)
end

