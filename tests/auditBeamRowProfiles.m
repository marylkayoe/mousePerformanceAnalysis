function auditBeamRowProfiles(T,C,fileName)
% Sample the exact debug-video matrices, without writing a video or full matrix.
n=size(T.postMouseVideoMatrix,3); frames=unique(max(2,min(n,round([.25 .5 .75]*n))));
f=figure('Visible','off','Color','w','Position',[50 50 1200 850]);
t=tiledlayout(numel(frames),3,'TileSpacing','compact','Padding','compact');
for k=frames
 for j=[k-1 k]
  nexttile; imagesc(T.postMouseVideoMatrix(:,:,j)); colormap(gray); axis image; hold on
  yline(C.barTopCoordOriginal,'r-'); yline(C.barTopCoordOriginal+C.barThickness,'r:');
  title(sprintf('Original frame %d; crop bad=%d',C.originalFrames(j),T.badFrames(j)));
 end
 nexttile; hold on
 u=double(C.rowMotion.unweighted(:,k)); w=double(C.rowMotion.probabilityWeighted(:,k));
 plot(u,C.rowMotion.rowHeightRelativeToBar,'Color',[.5 .5 .5]);
 plot(w,C.rowMotion.rowHeightRelativeToBar,'b'); yline(0,'r-'); yline(-C.barThickness,'r:');
 yline(C.rowMotion.weightedPosition(k),'b--'); xlabel('Row motion (sum absolute differences)'); ylabel('Height above bar (px)');
 title(sprintf('Pair valid=%d; index=%.1f px',~C.rowMotion.invalidFramePairMask(k),C.rowMotion.weightedPosition(k)));
 legend('Unweighted','Probability squared','Location','best'); grid on
end
title(t,strrep(fileName,'_','\_'));
exportgraphics(f,fullfile(getenv('TARA_BEAM_OUTPUT'),'plots',[fileName '.row_profile_audit.png']),'Resolution',130);
close(f)
end
