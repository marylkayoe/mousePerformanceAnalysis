function plotStoppingFrameComparison(outputDir)
% Replot saved scalar results; no video loading required.
T=readtable(fullfile(outputDir,'comparison.csv'),'TextType','string');
A=T(1:2:end,:); B=T(2:2:end,:);
finite=isfinite(A.TotalMagnitude)&isfinite(B.TotalMagnitude);
zoom=finite & A.TotalMagnitude<1e10 & B.TotalMagnitude<1e10;
c1=[.1 .4 .75]; c2=[.85 .3 .1];
f=figure('Visible','off','Color','w','Position',[100 100 1400 950]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
nexttile; hold on
for k=find(zoom)'
 plot([A.NSlips(k) B.NSlips(k)],[A.TotalMagnitude(k) B.TotalMagnitude(k)],'-','Color',[.7 .7 .7],'HandleVisibility','off');
end
scatter(A.NSlips(zoom),A.TotalMagnitude(zoom),65,c1,'filled','DisplayName','Include stops');
scatter(B.NSlips(zoom),B.TotalMagnitude(zoom),65,c2,'filled','DisplayName','Exclude stops');
xlabel('Slip count'); ylabel('Total slip magnitude'); grid on; legend('Location','northwest');
title(sprintf('Zoom: %d pairs with both magnitudes < 10^{10}',sum(zoom)));
nexttile; hold on
scatter(A.NSlips,B.NSlips,65,c1,'filled'); lim=max([A.NSlips;B.NSlips])*1.1;
plot([0 lim],[0 lim],'k--'); xlim([0 lim]); ylim([0 lim]); axis square; grid on
xlabel('Slip count: include stops'); ylabel('Slip count: exclude stops'); title('All 12 pairs: dashed line = equal counts');
nexttile; hold on
for k=find(finite)'
 plot([A.NSlips(k) B.NSlips(k)],log10(1+[A.TotalMagnitude(k) B.TotalMagnitude(k)]),'-','Color',[.7 .7 .7],'HandleVisibility','off');
end
scatter(A.NSlips(finite),log10(1+A.TotalMagnitude(finite)),65,c1,'filled');
scatter(B.NSlips(finite),log10(1+B.TotalMagnitude(finite)),65,c2,'filled');
xlabel('Slip count'); ylabel('log_{10}(1 + total slip magnitude)'); grid on
 title('All 10 finite pairs: extreme value retained');
nexttile; axis off
text(0,1,{'Numerical issues: exclusion enabled', ...
 'TMCS3 S07 / D00 / trial 4: Inf', ...
 'TMCS2 S33 / D07 / trial 3: Inf', ...
 'TMCS3 S02 / D00 / trial 1: 1.85 x 10^{35}', ...
 '', 'All 24 calls completed without exceptions.', ...
 'Include-stops magnitudes were finite in all 12 videos.', ...
 '', 'Gray lines connect the same video.', ...
 'Magnitude = sum of normalized score above threshold.', ...
 'Exclusion occurs before smoothing and normalization.', ...
 'The zoom omits the three flagged pairs only for display.', ...
 'CSV retains every result, including Inf.'},'VerticalAlignment','top','FontSize',11);
sgtitle('12 random videos | LOCOTHRESHOLD 150 | SLIPTHRESHOLD 2.5 | mouse-size threshold 2');
exportgraphics(f,fullfile(outputDir,'comparison.png'),'Resolution',160);
exportgraphics(f,fullfile(outputDir,'comparison.pdf'),'ContentType','vector');
close(f);
fid=fopen(fullfile(outputDir,'README.txt'),'a');
fprintf(fid,'\nUpdated plots: count panel contains all 12 pairs; log-transformed panel contains all 10 finite pairs; zoom contains 9 pairs with both magnitudes < 1e10. Three extreme/nonfinite exclusion results are explicitly listed in the figure.\n'); fclose(fid);
fprintf('Counts: lower=%d equal=%d higher=%d; medians include/exclude=%.3g/%.3g\n',sum(B.NSlips<A.NSlips),sum(B.NSlips==A.NSlips),sum(B.NSlips>A.NSlips),median(A.NSlips),median(B.NSlips));
end
