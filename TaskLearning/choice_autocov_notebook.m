nBack = 5;

choice = struct(...
    'loseSwitch',repmat([1,1,0,0],1,100),...
    'winSwitch', repmat([1,0],1,200),...
    'RRL',[0,repmat([1,1,0],1,133)],...
    'paradiddle',repmat([1,0,1,1,0,1,0,0],1,50)...
    );

autoCov = struct(...
    'loseSwitch',xcov(choice.loseSwitch,nBack,'coeff'),...
    'winSwitch', xcov(choice.winSwitch,nBack,'coeff'),...
    'RRL',xcov(choice.RRL,nBack,'coeff'),...
    'paradiddle',xcov(choice.paradiddle,nBack,'coeff')...
    );

X = -nBack:nBack;

tiledlayout(1,4,'TileSpacing','tight','Padding','tight');

ax(1) = nexttile();
plot(X,autoCov.winSwitch);
legend('Win-Switch');
ylabel('Corr. Coef.');

ax(2) = nexttile();
plot(X,autoCov.loseSwitch);
legend('Lose-Switch');

ax(3) = nexttile();
plot(X,autoCov.RRL);
legend('RRL');

ax(4) = nexttile();
plot(X,autoCov.paradiddle);
legend('Paradiddle');

set(ax,'YLim',[-1,1]);

