function obj=CouplingLine(x)

clearvars -except x
tStart = tic; 
%% setup the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
physical_constants;
unit = 1e-6; % specify everything in um
MSL.length = x(2);
MSL.port_dist = x(3);
MSL.width = x(1);
MSL.conductivity = 41e6;
MSL.thickness = 35e-6;
MSL.gap = 150;
substrate.thickness = 1524;
substrate.epr = 3.66;
substrate.kappa  = 3.7e-3 * 2*pi*2.45e9 * EPS0*substrate.epr;
f_min=1e7;
f_start = f_min;
f_stop  = 8e9 + f_min;
lambda = c0/(f_stop);

%% setup FDTD parameters & excitation function %%%%%%%%%%%%%%%%%%%%%%%%%%%%
FDTD = InitFDTD('endCriteria',1e-4);
FDTD = SetGaussExcite(FDTD,0.5*(f_start+f_stop),0.5*(f_stop-f_start));
BC   = {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PEC' 'PML_8'};
FDTD = SetBoundaryCond( FDTD, BC );

%% setup CSXCAD geometry & mesh %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CSX = InitCSX();
resolution = c0/(f_stop*sqrt(substrate.epr))/unit /20;
mesh.x=SmoothMeshLines([ MSL.gap/2 MSL.length/2 ],resolution/1, 1.8 );
mesh.x=SmoothMeshLines([ mesh.x MSL.length/2+MSL.port_dist],resolution, 1.8 );
mesh.x = SmoothMeshLines( [-mesh.x 0 mesh.x], resolution, 1.4 ,0 );
mesh.y = SmoothMeshLines2( [MSL.gap/2 MSL.width+MSL.gap/2], resolution/8 , 1.3);
mesh.y = SmoothMeshLines( [-0.5*lambda/unit -mesh.y 0 mesh.y 0.5*lambda/unit], resolution, 1.4);
mesh.z = SmoothMeshLines( [linspace(0,substrate.thickness,16) 0.5*lambda/unit], resolution );
CSX = DefineRectGrid( CSX, unit, mesh );

%% substrate
CSX = AddMaterial( CSX, 'RO4350B' );
CSX = SetMaterialProperty( CSX, 'RO4350B', 'Epsilon', substrate.epr,'Kappa',substrate.kappa);
start = [mesh.x(1),   mesh.y(1),   0];
stop  = [mesh.x(end), mesh.y(end), substrate.thickness];
CSX = AddBox( CSX, 'RO4350B', 0, start, stop );

%% MSL ports and lossy line
CSX = AddConductingSheet( CSX, 'gold', MSL.conductivity, MSL.thickness );
portstart = [ mesh.x(1),               MSL.gap/2, substrate.thickness];
portstop  = [ mesh.x(1)+MSL.port_dist,  MSL.width+MSL.gap/2, 0];
[CSX, port{1}] = AddMSLPort( CSX, 999, 1, 'gold', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', 10*resolution, 'MeasPlaneShift',  MSL.port_dist);

portstart = [mesh.x(end),              -MSL.gap/2-MSL.width, substrate.thickness];
portstop  = [mesh.x(end)-MSL.port_dist, -MSL.gap/2, 0];
[CSX, port{2}] = AddMSLPort( CSX, 999, 2, 'gold', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  MSL.port_dist );
%% Open Line

start = [mesh.x(1)+MSL.port_dist,    MSL.gap/2, substrate.thickness];
stop  = [MSL.length/2,  MSL.width+ MSL.gap/2, substrate.thickness];
CSX = AddBox(CSX,'gold',500,start,stop);
start = [mesh.x(end)-MSL.port_dist,   -MSL.width-MSL.gap/2, substrate.thickness];
stop  = [-MSL.length/2,  -MSL.gap/2, substrate.thickness];
CSX = AddBox(CSX,'gold',500,start,stop);

%% write/show/run the openEMS compatible xml-file
Sim_Path = 'tmp';
Sim_CSX = 'msl.xml';

[status, message, messageid] = rmdir( Sim_Path, 's' ); % clear previous directory
[status, message, messageid] = mkdir( Sim_Path ); % create empty simulation folder

WriteOpenEMS( [Sim_Path '/' Sim_CSX], FDTD, CSX );
CSXGeomPlot( [Sim_Path '/' Sim_CSX] );
RunOpenEMS( Sim_Path, Sim_CSX ,'');

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
obj=20*log10(abs(s11(801)))/(abs(20*log10(abs(s21(801)))))+tEnd/1000;

end
