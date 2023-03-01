X = S.sensory.cueRegion.position;
data.left = mean(S.sensory.cueRegion.left);
sd.left =  std(S.sensory.cueRegion.left).*[-1;1];
data.right = mean(S.sensory.cueRegion.right);
sd.right =  std(S.sensory.cueRegion.right).*[-1;1];

data.priorLeft = mean(S.sensory.cueRegion.priorLeft);
sd.priorLeft =  std(S.sensory.cueRegion.priorLeft).*[-1;1];
data.priorRight = mean(S.sensory.cueRegion.priorRight);
sd.priorRight =  std(S.sensory.cueRegion.priorRight).*[-1;1];

figure;
plot(X,data.left); hold on;
plot(X,data.right);
error = data.left+sd.left;
fill([X,fliplr(X)],[error(1,:),fliplr(error(2,:))],'b','FaceAlpha',0.1);

plot([0 0],ylim,':k');

figure;
plot(X,data.priorLeft); hold on;
error = data.priorLeft+sd.priorLeft;
fill([X,fliplr(X)],[error(1,:),fliplr(error(2,:))],'b','FaceAlpha',0.1);
plot(X,data.priorRight);
plot([0 0],ylim,':k');
