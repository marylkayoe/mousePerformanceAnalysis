function extract_tail_height(datasetFile)
% Summarize within-crossing height of motion, not stationary tail position.
% Median is weighted by frame-to-frame image motion across all rows, before
% centered 5-frame smoothing within contiguous valid samples. No spatial cuts.
here=fileparts(mfilename('fullpath'));load(datasetFile,'dataset');n=numel(dataset.trials);rows=struct([]);factor=700/1201;
for k=1:n
 t=dataset.trials(k);P=t.rowProfiles;Q=double(P.probabilityWeighted);h=double(P.rowHeightRelativeToBar(:))*factor;nf=size(Q,2);
 assert(nf==numel(P.invalidFramePairMask));x=nan(nf,1);meanHeight=nan(nf,1);nonfinite=0;zero=0;
 for j=1:nf
  if P.invalidFramePairMask(j),continue;end
  v=Q(:,j);if any(~isfinite(v))||any(v<0),nonfinite=nonfinite+1;continue;end
  total=sum(v);if total<=0,zero=zero+1;continue;end
  ind=find(cumsum(v)>=total/2,1,'first');x(j)=h(ind);meanHeight(j)=sum(v.*h)/total;
 end
 smoothX=nan(nf,1);ok=isfinite(x);starts=find(diff([false;ok;false])==1);ends=find(diff([false;ok;false])==-1)-1;
 for j=1:numel(starts),ind=starts(j):ends(j);smoothX(ind)=movmean(x(ind),5);end
 v=smoothX(isfinite(smoothX));r=struct('file',string(t.fileName),'nFrames',nf,'nInvalidPair',sum(P.invalidFramePairMask),'nNonfiniteProfile',nonfinite,'nZeroMotion',zero,'nValid',numel(v),'validFraction',numel(v)/nf,'meanHeight',NaN,'medianHeight',NaN,'sdHeight',NaN,'iqrHeight',NaN,'meanWeightedMeanHeight',NaN);
 if ~isempty(v),r.meanHeight=mean(v);r.medianHeight=median(v);r.meanWeightedMeanHeight=mean(meanHeight,'omitnan');end
 if numel(v)>=2,r.sdHeight=std(v,0);r.iqrHeight=iqr(v);end
 if isempty(rows),rows=r;else,rows(end+1)=r;end %#ok<AGROW>
 if mod(k,50)==0,fprintf('Summarized %d/%d\n',k,n);end
end
writetable(struct2table(rows),fullfile(here,'trial-motion-height.csv'));
end
