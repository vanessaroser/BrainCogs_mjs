function figs = fig_summary_psf_offsets( psf, offsets, sessionID, offsetID, titles )

idx.beam1 = contains(sessionID,'920nm');
idx.beam2 = contains(sessionID,'1064nm');
idx.zeiss = contains(sessionID,'zeiss');
idx.leica = contains(sessionID,'leica');
idx.olympus = contains(sessionID,'olympus');
idx.grinlens = contains(sessionID,'2p');


% Colors and Layout
cbrew = cbrewer("qual","Set1",9);
C.red = cbrew(1,:);
C.blue = cbrew(2,:);
C.green = cbrew(3,:);
C.pink = cbrew(8,:);
C.gray = cbrew(9,:);
X = 1:2;
offset = 0.2*[-1,0,1];
halfwidth = 0.1;

%PSFs
beams = ["920 nm","1064 nm"];
beamLabels = ["beam1","beam2"];
dim = ["x","y","z"];
obj = ["zeiss","leica","olympus"];
colors = {C.red,C.blue,C.green};
ylims = {[0,7],[0,7],[0,40]};
xlims = [0.5 2.5];
for i = 1:numel(beams)
    figs(i) = figure('Name',titles(i),'Position',[400,400,1200,400]);
    tiledlayout(1,3,'TileSpacing','tight')
    for j = 1:numel(dim)
        ax = nexttile;
        for k = 1:numel(obj)
            data.grin = psf(idx.(beamLabels(i)) & idx.(obj(k)) & idx.grinlens).(dim(j));
            data.nogrin = psf(idx.(beamLabels(i)) & idx.(obj(k)) & ~idx.grinlens).(dim(j));

            plot(X(1)+offset(k), data.nogrin,'o','MarkerEdgeColor',C.gray,'LineWidth',1.5); hold on;
            plot(X(1)+offset(k) + [-1,1]*halfwidth,...
                [1,1]*mean(data.nogrin),'Color',colors{k},'LineWidth',1.5);

            plot(X(2)+offset(k), data.grin,'o','MarkerEdgeColor',C.gray,'LineWidth',1.5);
            plot(X(2)+offset(k) + [-1,1]*halfwidth,...
                [1,1]*mean(data.grin),'Color',colors{k},'LineWidth',1.5);
        end
        ylabel('FWHM (um)');
        set(ax,'XTick',[X(1)+offset X(2)+offset],'XTickLabel',obj,'YLim',ylims{j},'XLim',xlims);
        title(['Resolution (' char(dim(j)) ')']);
        axis square;
    end

end

%Offsets
fields = fieldnames(idx);
for i=1:numel(fields) 
    idx.(fields{i}) = idx.(fields{i})(1:2:end); %Index by 920nm sessions (arbitrary)
end

figs(3) = figure('Name',titles(3),'Position',[400,400,400,400]);
X = 1:2;
for j = 1:numel(obj)
    data.grin = offsets{idx.(obj(j)) & idx.grinlens};
    data.nogrin = offsets{idx.(obj(j)) & ~idx.grinlens};

    plot(X(1)+offset(j), data.nogrin,'o','MarkerEdgeColor',C.gray,'LineWidth',1.5); hold on;
    plot(X(1)+offset(j) + [-1,1]*halfwidth,...
        [1,1]*mean(data.nogrin),'Color',colors{j},'LineWidth',1.5);

    plot(X(2)+offset(j), data.grin,'o','MarkerEdgeColor',C.gray,'LineWidth',1.5);
    plot(X(2)+offset(j) + [-1,1]*halfwidth,...
        [1,1]*mean(data.grin),'Color',colors{j},'LineWidth',1.5);
end
plot(xlims,[0,0],':k');
ax=gca;
ylabel('Peak_{920 nm} - peak_{1064 nm} (um)');
set(ax,'XTick',[X(1)+offset X(2)+offset],'XTickLabel',obj,'YLim',[-40,40],'XLim',xlims);
title('Axial Offset');
axis square;
