
function fig = plotSummaryPSF( psf, fig_title )

% Colors and Layout
cbrew = cbrewer("qual","Set1",9);
C.red = cbrew(1,:);
C.blue = cbrew(2,:);
C.green = cbrew(3,:);
C.pink = cbrew(8,:);
C.gray = cbrew(9,:);

fig = figure('Name',fig_title,'Position',[200,200,800,500]);
tiledlayout(2,3,'TileSpacing','compact');

%PSF
fields = ["x","y","z"];
xLabels = ["X-Position (um)","Y-Position (um)","Z-position (um)"];
minmaxFunc = @(data) (data-min(data))/max(data-min(data));
for i = 1:3
    nexttile;
    %Aggregate data
    for j = 1:numel(psf)
        %Plot smoothed data
        data(j).smooth = minmaxFunc(psf(j).(fields(i)).smoothed);
        data(j).X = psf(j).(fields(i)).X - psf(j).(fields(i)).loc; %re-center on peak
        plot(data(j).X,data(j).smooth,'.',"LineStyle","none","MarkerEdgeColor",cbrew(j,:)); hold on;

        %Plot Gaussian approximation
        data(j).gaussian = minmaxFunc(feval(psf(j).(fields(i)).gaussian, psf(j).(fields(i)).X(:)));
        plot(data(j).X, data(j).gaussian,"Color",cbrew(j,:)); hold on;

    end
    axis square tight;
    title(['PSF (' char(fields(i)) ')']);
    xlabel(xLabels(i)); ylabel("Norm. Intensity (au)");
end

%Plot FWHM vs. depth
for i = 1:3
    h = nexttile;
    %Aggregate data
    for j = 1:numel(psf)
        %FWHM
        fwhm(j) = psf(j).(fields(i)).fwhm;
        depth(j) = psf(j).depth;
    end
    %Scatter plot
    Mean = mean(fwhm);
    SEM = std(fwhm)/sqrt(numel(psf));
    axisFunc = @(data) [min(data)-0.1*range(data) max(data)+0.1*range(data)];
    if ~isnan(depth)
        scatter(depth,fwhm,'CData',cbrew(1:numel(psf),:));  hold on;
        title(['FWHM (' char(fields(i)) ') vs. Imaging Depth']);
        xlabel("Depth from surface (um)"); ylabel("FWHM (um)");
        set(h, 'XLim',axisFunc(depth),'YLim',axisFunc(fwhm));
        text(0.4,0.5,{['Mean' char(177) 'SEM ='],[num2str(Mean,2) char(177) num2str(SEM,2) ' um']},'Units','normalized');
    else
        for j=1:numel(fwhm)
            plot(0, fwhm(j),'o','MarkerEdgeColor',cbrew(j,:));  hold on;
        end
        plot([-1,1],[Mean,Mean],'k','LineStyle','-','LineWidth',2);
        set(h, 'XLim',[-2,6],'XTick',[],'XTickLabel',{},'YLim',axisFunc(fwhm));
        title(['FWHM (' char(fields(i)) ')']);
        ylabel('FWHM (um)');
        text(0.4,0.5,[num2str(Mean,2) char(177) num2str(SEM,2) ' um'],'Units','normalized');
        %         text(0.4,0.5,{['Mean' char(177) 'SEM ='],[num2str(Mean,2) char(177) num2str(SEM,2) ' um']},'Units','normalized');
    end
    axis square;
end
end