function figs = heatmap_summarySelectivity(selectivity_struct, figName, params)

%Define colormap
cmap = {cbrewer('div','RdBu', 256);...
    cbrewer('div','RdBu', 256);...
    cbrewer('div', 'PiYG', 256);...
    cbrewer('seq','YlOrRd',256)};

for i = 1:numel(params)
%Get selectivity matrix
selMat = selectivity_struct.(params(i).comparison).values;
X = selectivity_struct.(params(i).comparison).domain; %Time or position

%Sort by peak position
for j = 1:size(selMat,1)
    peak(j) = find(selMat(j,:)==max(selMat(j,:)),1,"first");
end
[~,idx] = sort(peak,"descend");
selMat = selMat(idx,:);
    
figure('Name',figName,'Position',[200 0 400 800]);

ax(i) = imagesc('XData',X,...
    'YData',1:size(selMat,1),'CData',selMat); hold on;
plot([0,0],[0,size(selMat,1)],':k','LineWidth',1);
ylim([1,size(selMat,1)]);
xlim([X(1),X(end)]);
axis ij;

colormap(cmap{i}) 
c = colorbar;
clim = prctile(abs(selMat(:)),95);
caxis([-clim clim]);
c.Label.String = params(i).cLabel;

title(params(i).title)
ylabel('Cells');
xlabel(params(i).xLabel);
end