folder=fileparts(mfilename('fullpath'));t=readtable(fullfile(folder,'example-motion-height-time-frames.csv'),'TextType','string');
files={'TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4','TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4'};
names={'Sedentary TMCS3\_S09 — D14 trial 2','Run TMCS2\_S18 — D14 trial 2'};factor=700/1201; bandMM=5;
fig=figure('Color','w','Visible','off','Units','pixels','Position',[80 80 1450 900]);lay=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');allrows=table;
for k=1:2
 a=t(t.File==files{k},:);q=load(fullfile(folder,'example-row-profiles',[files{k} '.profiles.mat']),'P');P=q.P;
 h=double(P.rowHeightRelativeToBar(:))*factor;w=double(P.probabilityWeighted);assert(size(w,2)==height(a));
 exclude=h>=0 & h<bandMM; weightAll=sum(w,1);weightKeep=sum(w(~exclude,:),1);numer=sum(w(~exclude,:).*h(~exclude),1);
 new=(numer./weightKeep)';invalid=P.invalidFramePairMask(:) | ~isfinite(weightKeep(:)) | weightKeep(:)<=0;new(invalid)=NaN;original=double(P.weightedPosition(:))*factor;
 valid=isfinite(original)&isfinite(a.MotionHeightMM);assert(max(abs(original(valid)-a.MotionHeightMM(valid)))<.001);
 values={original,new};curves=cell(1,2);
 for c=1:2
  v=values{c};ok=isfinite(v);z=nan(size(v));starts=find(diff([false;ok;false])==1);ends=find(diff([false;ok;false])==-1)-1;
  for j=1:numel(starts),ii=starts(j):ends(j);z(ii)=movmean(v(ii),5);end;curves{c}=z;
 end
 ax=nexttile(lay);hold(ax,'on');plot(ax,a.ElapsedSeconds,curves{1},'Color',[.6 .6 .6],'LineWidth',1.1,'DisplayName','Original');plot(ax,a.ElapsedSeconds,curves{2},'Color',[.05 .38 .68],'LineWidth',1.3,'DisplayName','0–5 mm above bar excluded');
 yline(ax,0,'--','Color',[.4 .4 .4],'HandleVisibility','off');xlim(ax,[0 5.5]);ylim(ax,[-20 90]);grid(ax,'on');title(ax,names{k});xlabel(ax,'Time since start of tracked crossing (s)');ylabel(ax,{'Motion-weighted height','relative to bar (mm)'});if k==1,legend(ax,'Location','northeast');end
 r=table(repmat(string(files{k}),height(a),1),a.TraversalFrame,a.OriginalFrame,a.ElapsedSeconds,original,new,curves{1},curves{2},'VariableNames',{'File','TraversalFrame','OriginalFrame','ElapsedSeconds','OriginalHeightMM','Exclude0to5mmHeightMM','OriginalSmoothedMM','Exclude0to5mmSmoothedMM'});allrows=[allrows;r];
 fprintf('%s: before %d valid, after %d valid, no remaining weight %d\n',files{k},sum(isfinite(original)),sum(isfinite(new)),sum(isfinite(original)&~isfinite(new)));
end
title(lay,{'Example motion-height traces: effect of removing motion near the bar','Blue: ignore image motion from 0 to <5 mm above bar before calculating height; 5-frame mean'});
base=fullfile(folder,'example-motion-height-exclude-0to5mm-D14');writetable(allrows,[base '.csv']);savefig(fig,[base '.fig']);exportgraphics(fig,[base '.png'],'Resolution',160);print(fig,[base '.svg'],'-dsvg');
