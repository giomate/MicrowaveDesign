function obj=Ring1(x)
clearvars -except x
r=x(1);
s=x(2);
w=x(3);
l=x(4);
g=x(5);
res=x(6);
tStart = tic; 
%% setup the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
physical_constants;
unit = 1e-6; % specify everything in um
substrate.thickness = 1524;
substrate.epr = 3.66;
copperThickness=33;
f_min=1e7;
f_start = f_min;
f_stop  = 8e9 + f_min;
lambda = c0/(f_stop);
%% setup FDTD parameters & excitation function %%%%%%%%%%%%%%%%%%%%%%%%%%%%
FDTD = InitFDTD('endCriteria',1e-2);
FDTD = SetGaussExcite(FDTD,0.5*(f_stop-f_start),0.5*(f_start+f_stop));
BC   = {'PML_8' 'PML_8' 'MUR' 'MUR' 'PEC' 'MUR'};
FDTD = SetBoundaryCond( FDTD, BC );
%% setup CSXCAD geometry & mesh %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CSX = InitCSX();
resolution = c0/(f_stop*sqrt(substrate.epr)*unit *res);
mesh.x=[r r+g r+g+l];
mesh.x = SmoothMeshLines([ -mesh.x 0 mesh.x], resolution/2, 1.4 ,0 );
mesh.y=[w r 0.25*lambda/unit r+0.25*lambda/unit 1.25*r];
mesh.y = SmoothMeshLines2( [-mesh.y 0 mesh.y], resolution/1 , 1.4);
mesh.z = SmoothMeshLines( [linspace(0,substrate.thickness,8) substrate.thickness+copperThickness  0.5*lambda/unit], resolution/8,1.6);
CSX = DefineRectGrid( CSX, unit, mesh );
%% substrate
CSX = AddMaterial( CSX, 'RO4350B' );
CSX = SetMaterialProperty( CSX, 'RO4350B', 'Epsilon', substrate.epr );
start = [mesh.x(1),   mesh.y(1),   0];
stop  = [mesh.x(end), mesh.y(end), substrate.thickness];
CSX = AddBox( CSX, 'RO4350B', 0, start, stop );

%% MSL port
CSX = AddMetal( CSX, 'PEC' );
portstart = [ mesh.x(1), -w/2, substrate.thickness];
portstop  = [mesh.x(1)+l ,  w/2, 0];
[CSX,port{1}] = AddMSLPort( CSX, 999, 1, 'PEC', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', 10*resolution, 'MeasPlaneShift', l/2);

portstart = [mesh.x(end), -w/2, substrate.thickness];
portstop  = [mesh.x(end)-l,  w/2, 0];
[CSX,port{2}] = AddMSLPort( CSX, 999, 2, 'PEC', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  l/2 );
%% Ring
middleRadius=r-s/2;
start = [0,  0, substrate.thickness];
stop  = [ 0,  0, substrate.thickness+copperThickness];
CSX=AddCylindricalShell(CSX,'PEC',500,start,stop,middleRadius,s);
%% write/show/run the openEMS compatible xml-file
Sim_Path = 'tmp';
Sim_CSX = 'ring.xml';

[status, message, messageid] = rmdir( Sim_Path, 's' ); % clear previous directory
[status, message, messageid] = mkdir( Sim_Path ); % create empty simulation folder

WriteOpenEMS( [Sim_Path '/' Sim_CSX], FDTD, CSX );
%CSXGeomPlot( [Sim_Path '/' Sim_CSX] );
RunOpenEMS( Sim_Path, Sim_CSX );

%% post-processing

f = linspace( f_start, f_stop, 1601 );
port = calcPort( port, Sim_Path, f, 'RefImpedance', 50);

s11 = port{1}.uf.ref./ port{1}.uf.inc;
s21 = port{2}.uf.ref./ port{1}.uf.inc;
%% Plot
optFig=gcf;


f2=figure(1);
cla(f2);
plot(f/1e9,20*log10(abs(s11)),'k-','LineWidth',2);
hold on;
grid on;
plot(f/1e9,20*log10(abs(s21)),'r--','LineWidth',2);
legend('S_{11}','S_{21}');
ylabel('S-Parameter (dB)','FontSize',12);
xlabel('frequency (GHz) \rightarrow','FontSize',12);
hold off;
figure(optFig);
%% Output Value
tEnd = toc(tStart);
obj=20*log10(abs(s11(801)))-(10*log10(abs(s21(801))))+tEnd/1000;

end