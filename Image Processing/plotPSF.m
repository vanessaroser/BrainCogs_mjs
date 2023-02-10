function fig = plotPSF( psf, img, sessionID )

% Colors and Layout
cbrew = cbrewer("qual","Set1",9);
C.red = cbrew(1,:);
C.blue = cbrew(2,:);
C.green = cbrew(3,:);
C.pink = cbrew(8,:);
C.gray = cbrew(9,:);

fig = figure('Name',sessionID,'Position',[200,200,800,800]); 
tiledlayout(3,3);

% Mean Projections for each spatial dimension
fields = ["x","y","z"];
xLabels = ["Y-Position (um)","X-Position (um)","X-position (um)"];
yLabels = ["Axial Displacement (um)","Axial Displacement (um)","Y-position (um)"];
for i = 1:3
    nexttile;
    X = img.meanProj.(fields(i)).X;
    Y = img.meanProj.(fields(i)).Y;
    imagesc(X,Y,img.meanProj.(fields(i)).data);
    axis xy square; if fields(i)=="z", axis ij; end
    title(['Mean Projection (' char(fields(i)) ')']);
    xlabel(xLabels(i)); ylabel(yLabels(i));
end

%Profile along each spatial dimension
xLabels = ["X-Position (um)","Y-Position (um)","Axial Displacement (um)"];
for i = 1:3
    nexttile;
    X = img.profile.(fields(i)).X;
    Y = img.profile.(fields(i)).data;
    plot(X,Y,'LineWidth',1.5);
    axis square; 
    title(['Axis Profile (' char(fields(i)) ')']);
    xlabel(xLabels(i)); ylabel("Mean pixel intensity (au)");
end

%PSF for each spatial dimension
xLabels = ["X-Position (um)","Y-Position (um)","Axial Displacement (um)"];
for i = 1:numel(fields)
    %Data and smoothed data
    nexttile;
    X = psf.(fields(i)).X;
    Y = psf.(fields(i)).data;
    gaussian = feval(psf.(fields(i)).gaussian,X(:));
    plot(X,Y,'LineStyle','none','Marker','.','Color',C.gray,"DisplayName","signal"); hold on;
    plot(X,gaussian,"Color",C.red,"LineWidth",1.5,"DisplayName","gaussian"); 

    %Interpolate X and Y values and plot FWHM
    fwhm_X = psf.(fields(i)).loc + 0.5*[-psf.(fields(i)).fwhm +psf.(fields(i)).fwhm];
    fwhm_Y = [1,1]*0.5*psf.(fields(i)).peak;
    plot(fwhm_X,fwhm_Y,'-k',"LineWidth",1,"DisplayName","FWHM"); 
    plot(fwhm_X,fwhm_Y,'|k',"LineStyle","none");
    text(psf.(fields(i)).loc+0.6*(psf.(fields(i)).fwhm),...
        fwhm_Y(1), [num2str(psf.(fields(i)).fwhm, 2) ' um'],'Color','k');
    title(['PSF (' char(fields(i)) ')']);
    xlabel(xLabels(i)); ylabel("Mean pixel intensity (au)");

    %Annotate peak location (for offsets)
    if fields(i)=="z"
        peakX = X(gaussian==max(gaussian));
        plot([peakX,peakX],[max(gaussian),0],':k',"LineWidth",1);
        plot(peakX,0.03,'v','MarkerFaceColor','w','MarkerEdgeColor','k'); %arrowhead
        text(peakX+1,0.1, [num2str(psf.(fields(i)).loc, 2) ' um'],'Color','k');
    end

end