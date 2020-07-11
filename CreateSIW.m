function [CSX mesh] = CreateSIW(CSX, mesh, SIW, resolution, translate)
if (nargin<5)
    translate = [0 0 0];
end

%% Substrate

CSX = AddMaterial( CSX, 'RO4350B' );
CSX = SetMaterialProperty( CSX, 'RO4350B', 'Epsilon', SIW.epr );
start = [-SIW.LX/2-SIW.FL -SIW.LY/2-SIW.lambda/2 0]+translate;
stop  = [SIW.LX/2+SIW.FL  SIW.LY/2+SIW.lambda/2 SIW.SH]+translate;
CSX = AddBox( CSX, 'RO4350B', 10, start, stop );
mesh.z =SmoothMeshLines( [mesh.z   SIW.SH], resolution/1, 1.4 ,0 );
%% Make Ports
%CSX  = CreateSIW_Ports(CSX, SIW, resolution/1);
CSX = AddMetal( CSX, 'PEC' );
portstart = [ -SIW.FL-SIW.LX/2, -SIW.LY/2, SIW.SH];
portstop  = [ -SIW.LX/2,         SIW.LY/2, 0];
[CSX,port{1}] = AddMSLPort( CSX,900, 1, 'PEC', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', 10*resolution, 'MeasPlaneShift',  SIW.FL/1);

portstart = [ SIW.FL+SIW.LX/2, -SIW.LY/2, SIW.SH];
portstop  = [ SIW.LX/2,         SIW.LY/2, 0];
[CSX,port{2}] = AddMSLPort( CSX, 900, 2, 'PEC', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  SIW.FL/1);



%% Bottom Layer
% CSX = AddConductingSheet( CSX, 'copper_bottom', SIW.CC,SIW.CT );
% start = [-SIW.LX/2 -SIW.LY/2 -SIW.SH/2]+translate;
% stop  = [SIW.LX/2  SIW.LW/2 -SIW.SH/2]+translate;
% CSX = AddBox(CSX, 'copper_bottom', 30, start, stop);
% mesh.z = SmoothMeshLines( [ mesh.y -SIW.SH/2  -SIW.SH/2-SIW.CT/2 -SIW.SH/2+SIW.CT], resolution/16, 1.3 ,0 );
%% top Layer
start = [-SIW.LX/2 -SIW.LY/2 SIW.SH]+translate;
stop  = [SIW.LX/2  SIW.LY/2 SIW.SH]+translate;
CSX = AddBox(CSX, 'PEC', 60, start, stop);
%mesh.x = SmoothMeshLines( [mesh.x -SIW.LX/2  SIW.LX/2], resolution, 1.1 ,0 );
mesh.x = SmoothMeshLines([mesh.x -SIW.LX/2  SIW.LX/2], resolution/1, 1.4,0 );
mesh.y =SmoothMeshLines( [mesh.y -SIW.LY/2  SIW.LY/2], resolution/1, 1.4 ,0 );
mesh.z = SmoothMeshLines( [mesh.z   SIW.SH+SIW.CT], resolution/1, 1.4 ,0 );
%% Copper Vias

% CSX = AddMetal(CSX, 'via');
% start = [0 0 SIW.SH+SIW.CT]+translate;
% stop  = [0 0 0]+translate;
% CSX = AddCylinder(CSX, 'via', 20, start, stop, (SIW.VR+SIW.CT));
% mesh.x =SmoothMeshLines( [mesh.x [-2  2]*SIW.VR],resolution/1, 1.3 ,0 );
% mesh.y = SmoothMeshLines([mesh.y [-2  2]*SIW.VR],resolution/1, 1.3 ,0 );
% %% Hole
% CSX = AddMaterial( CSX, 'Air' );
% CSX = SetMaterialProperty( CSX, 'Air', 'Epsilon', 1, 'Mue', 1 );
% start = [0 0 SIW.SH+(SIW.CT*2)]+translate;
% stop  = [0 0 0]+translate;
% CSX = AddCylinder(CSX, 'Air', 99, start, stop, SIW.VR);
% mesh.z = SmoothMeshLines( [ mesh.y  start(3)], resolution/1, 1.4 ,0 );
end