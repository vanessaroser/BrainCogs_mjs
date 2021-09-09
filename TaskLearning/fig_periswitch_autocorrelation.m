function figs = fig_choice_autocorrelation(subjects)

lineWidth = 1;
clims = [-0.3,0.3];
%Image autocorrelation of choice vector
for i = 1:numel(subjects)
    %Populate matrix with autocorrelations from each session
    S = subjects(i).sessions;
    CData = cell2mat(arrayfun(...
        @(sessionIdx) S(sessionIdx).glm3.xcorrChoice, 1:numel(S),...
        'UniformOutput',false))';
    
    idx = 1:0.5*(numel(S(1).glm3.xcorrChoice)-1); %Index for trials i-nBack:i-1
    %     idx = 1:numel(S(1).glm3.xcorrChoice); %Index for trials i-nBack  :i+nBack
    
    X = idx-0.5*(size(CData,2)+1);
    X = X(idx);
    
    prefix = "xcorr_choice";
    figs(i) = figure('Name',join([prefix,subjects(i).ID],'_'),...
        'Position',[100 100 500 800]);
    ax = axes();
    img = imagesc(X(1),1,CData); hold on;
    
    %Line for first alternation session
    firstAltSession = find([S.sessionType]=="Alternation",1,'first');
    Y = firstAltSession-0.5;
    if ~isempty(Y)
        plot([X(1)-0.5, X(numel(idx))+0.5],[Y,Y],'-r','LineWidth',lineWidth);
    end
    title(subjects(i).ID,'Interpreter','none');
    set(ax, 'XTick',X, 'PlotBoxAspectRatio',[1,3,1], 'CLim', clims);
    xlabel('Lag (number of trials)');
    ylabel('Session number');
    xlim([X(1)-0.5,X(numel(idx))+0.5]);
    
    if i == numel(subjects)
        b = colorbar();
        b.Label.String = 'Pearson''s R';
    end
end