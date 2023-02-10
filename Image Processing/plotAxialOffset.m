function fig = plotAxialOffset( offset, img, sessionID )

% Colors and Layout
cbrew = [cbrewer("qual","Paired",9);cbrewer("qual","Set1",9)];
C.red = cbrew(6,:);
C.red2 = cbrew(5,:);
C.blue = cbrew(2,:);
C.blue2 = cbrew(1,:);
C.green = cbrew(4,:);
C.green2 = cbrew(3,:);
C.pink = cbrew(17,:);
C.gray = cbrew(18,:);

fig = figure('Name',join([sessionID,"-Offset"]),'Position',[200,200,800,800]);
tiledlayout(3,3);

% Mean Projections for each spatial dimension
fields = ["y","x","z"];
xLabels = ["X-Position (um)","Y-Position (um)","X-position (um)"];
yLabels = ["Depth (um)","Depth (um)","Y-position (um)"];
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
fields = ["x","y","z"];
xLabels = ["X-Position (um)","Y-Position (um)","Depth (um)"];
for i = 1:numel(fields)
    nexttile;
    X = img.profile.(fields(i)).X;
    Y = img.profile.(fields(i)).data;
    plot(X,Y,'LineWidth',1.5);
    axis square;
    title(['Axis Profile (' char(fields(i)) ')']);
    xlabel(xLabels(i)); ylabel("Mean pixel intensity (au)");
end

%Offsets for each spatial dimension
fields = ["x","y","z"];
for i = 1:numel(fields)
    %Data and smoothed data
    nexttile;
    if ~isfield(offset,fields(i))
        continue 
    end
    X = offset.(fields(i)).X;
    Y = offset.(fields(i)).data;
    if size(Y,1)>1
        %Peak1
        plot(X,Y(1,:),'LineStyle','none','Marker','.','Color','k',"DisplayName","Raw1"); hold on;
        plot(X,offset.(fields(i)).smoothed(1,:),"Color",C.red,"LineWidth",1.5,"DisplayName","Peak1");
        %Peak2
        plot(X,Y(2,:),'LineStyle','none','Marker','.','Color',C.gray,"DisplayName","Raw2"); hold on;
        plot(X,offset.(fields(i)).smoothed(2,:),"Color",C.red2,"LineWidth",1.5,"DisplayName","Peak2");
    else
        plot(X(:),Y(:),'LineStyle','none','Marker','.','Color',C.red,"DisplayName","Data"); hold on;
        plot(X,offset.(fields(i)).smoothed,"Color",C.red,"LineWidth",1.5,"DisplayName","Smoothed");
    end

    %Plot Distance between Peaks
    X = offset.(fields(i)).loc;
    Y = offset.(fields(i)).peak;
    plot(X(1)*[1;1],[Y(1);0],"Color",'k',"LineWidth",1,"LineStyle",':',"DisplayName","Peak1");
    plot(X(2)*[1;1],[Y(2);0],"Color",'k',"LineWidth",1,"LineStyle",':',"DisplayName","Peak2");
    Y = 0.25*min(offset.(fields(i)).peak);
    plot(X,[Y,Y],"Color",'k',"LineWidth",1,"LineStyle",'-',"DisplayName","Offset");
    text(offset.(fields(i)).loc(1), Y-0.1, [num2str(offset.(fields(i)).diff, 2) ' um'],'Color','k','HorizontalAlignment','center');
    title(['Offset (' char(fields(i)) ')']);
    xlabel(xLabels(i)); ylabel("Mean pixel intensity (au)");
end