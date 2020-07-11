function CSX  = CreateSIW_Ports(CSX, SIW, resolution)
%% FeedingPorts
CSX = AddMetal( CSX, 'PEC' );
portstart = [ -SIW.FL-SIW.LX/2, -SIW.LY/2, SIW.SH];
portstop  = [ -SIW.LX/2,         SIW.LY/2, 0];
[CSX,port{1}] = AddMSLPort( CSX,900, 1, 'PEC', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', 10*resolution, 'MeasPlaneShift',  SIW.FL/1);

portstart = [ SIW.FL+SIW.LX/2, -SIW.LY/2, SIW.SH];
portstop  = [ SIW.LX/2,         SIW.LY/2, 0];
[CSX,port{2}] = AddMSLPort( CSX, 900, 2, 'PEC', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  SIW.FL/1);


end