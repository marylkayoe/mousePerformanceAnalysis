function finalizeTaraBeamRerun(outputDir)
% Validate saved event positions/profiles and aggregate an explicitly qualified plot set.
M=jsondecode(fileread(fullfile(outputDir,'run_manifest.json')));
addpath(fullfile(outputDir,'code_snapshot'),'-begin');
environment=struct('MATLAB',version,'Architecture',computer,'Toolboxes',ver,'CapturedFunction',which('capturedTaraBeam'),'SmoothFunction',which('smooth'));
fid=fopen(fullfile(outputDir,'environment.json'),'w');fwrite(fid,jsonencode(environment));fclose(fid);
edgeChecks=validateBeamRowProfileEdges();fid=fopen(fullfile(outputDir,'row_profile_edge_checks.json'),'w');fwrite(fid,jsonencode(edgeChecks));fclose(fid);
ref=load('/Users/yoe/Downloads/BB_values_261105_2.mat');values=ref.values_261105_2;
ref=load('/Users/yoe/Downloads/BB_fileNames_261105_2.mat');refFiles=string(ref.fileNames_261105_2);
ref=load('/Users/yoe/Downloads/BB_fieldNames_261105_2.mat');fields=string(ref.fieldsToExtract);
allEvents={};allComparisons={};rows=struct([]);coverage=false(numel(M.files),20);edges=linspace(0,1,21);
for j=1:numel(M.files)
 z=M.files(j);base=fullfile(outputDir,'trials',z.file);
 row=struct('File',string(z.file),'Cohort',string(z.cohort),'MouseID',string(z.mouseID),'CageID',string(z.cageID), ...
 'Group',string(z.group),'Day',z.day,'TrialNumber',z.trialNumber,'TailID',z.tailID,'Status',"not_attempted", ...
 'Stage',"none",'Frames',NaN,'FirstOriginalFrame',NaN,'LastOriginalFrame',NaN,'ImageWidth',NaN, ...
 'ImageHeight',NaN,'EncodedWidth',NaN,'EncodedHeight',NaN,'GeometryMismatch',false,'VideoReaderFrameRate',NaN,'EncodedFrameRate',NaN,'AnalysisFrameRate',NaN,'FrameRateMismatch',false, ...
 'NSlips',NaN,'NStops',NaN,'CorrectStoppedFrames',NaN,'ReferenceStoppedFrames',NaN,'CorrectStopTotalMatch',false, ...
 'SlipsValidated',false,'StopsValidated',false,'SlipsReferenceMatch',false,'StopsReferenceMatch',false, ...
 'CentroidsReferenceMatch',false,'DirectionConsistent',false,'ValidSlipPlotCrossing',false,'ValidStopPlotCrossing',false, ...
 'EventsWithMissingPosition',NaN,'TailBadFrames',NaN,'MissingCentroidSamples',NaN,'SpeedNonfinite',NaN, ...
 'MovementNonfinite',NaN,'TailTotalNonfinite',NaN,'TailAboveNonfinite',NaN,'TailBelowNonfinite',NaN, ...
 'ProfilesPresent',false,'ProfilesVerified',false,'ValidWeightedHeightSamples',NaN,'ValidUnweightedHeightSamples',NaN, ...
 'TraceInfinities',NaN,'SummaryNonfiniteFields',"",'Error',"");
 if isfile([base '.status.json'])
  s=jsondecode(fileread([base '.status.json']));row.Status=string(s.status);row.Stage=string(s.stage);row.Error=string(s.error);
 end
 if ~isfile([base '.mat']), rows=[rows;row];continue;end %#ok<AGROW>
 D=load([base '.mat']);C=D.C;clear D
 scalarNames=fieldnames(C.summary); badNames=strings(0,1);
 for sn=1:numel(scalarNames)
  value=C.summary.(scalarNames{sn});if isnumeric(value)&&isscalar(value)&&~isfinite(value),badNames(end+1)=string(scalarNames{sn});end
 end
 row.SummaryNonfiniteFields=strjoin(badNames,';');
 n=numel(C.originalFrames);row.Frames=n;row.FirstOriginalFrame=C.firstOriginalFrame;row.LastOriginalFrame=C.lastOriginalFrame;
 row.ImageWidth=C.decodedVideoSize(2);row.ImageHeight=C.decodedVideoSize(1);
 row.EncodedWidth=C.encodedTiming.streams.width;row.EncodedHeight=C.encodedTiming.streams.height;
 row.GeometryMismatch=row.ImageWidth~=row.EncodedWidth||row.ImageHeight~=row.EncodedHeight;row.VideoReaderFrameRate=C.videoReaderFrameRate;row.EncodedFrameRate=C.encodedFrameRate;
 row.AnalysisFrameRate=C.analysisFrameRate;row.FrameRateMismatch=C.frameRateMetadataMismatch;
 row.DirectionConsistent=C.entryDirectionConsistent;row.SlipsValidated=C.validation.slipValid;row.StopsValidated=C.validation.stopValid;
 row.SlipsReferenceMatch=C.referenceSummaryMatch.slip;row.StopsReferenceMatch=C.referenceSummaryMatch.stop;
 row.CorrectStoppedFrames=sum(C.stoppingFrames);row.NStops=size(C.stoppingStartStops,1);
 if isfield(C,'slipEventStarts'),row.NSlips=numel(C.slipEventStarts);end
 if isfield(C,'tailBadFrames'),row.TailBadFrames=sum(C.tailBadFrames);end
 row.TraceInfinities=sum(isinf(C.mouseCentroids),'all')+sum(isinf(C.forwardSpeeds));
 for tf={'movementTrace','tailMovementTrace','tailMovementTraceAboveBar','tailMovementTraceUnderBar'}
  if isfield(C,tf{1}),row.TraceInfinities=row.TraceInfinities+sum(isinf(C.(tf{1})));end
 end
 row.MissingCentroidSamples=sum(any(~isfinite(C.mouseCentroids),2));row.SpeedNonfinite=sum(~isfinite(C.forwardSpeeds));
 for pair={'movementTrace','MovementNonfinite';'tailMovementTrace','TailTotalNonfinite';'tailMovementTraceAboveBar','TailAboveNonfinite';'tailMovementTraceUnderBar','TailBelowNonfinite'}'
  if isfield(C,pair{1}),row.(pair{2})=sum(~isfinite(C.(pair{1})));end
 end
 comparison=readtable([base '.comparison.csv'],'TextType','string');
 comparison.Note=string(comparison.Note);comparison.Note(ismissing(comparison.Note)|comparison.Note=="NaN")="";
 comparison.Match=logical(comparison.Match);q=comparison.Field=="mouseCentroids";
 row.CentroidsReferenceMatch=any(q)&&all(comparison.Match(q));
 idx=find(refFiles==string(z.file));
 if numel(idx)==1
  durations=values{idx,fields=="stoppingDurations"};row.ReferenceStoppedFrames=sum(durations(:));
  row.CorrectStopTotalMatch=isequaln(row.CorrectStoppedFrames,row.ReferenceStoppedFrames);
  comparison(end+1,:)={string(z.file),"correctStoppedFrames",row.CorrectStoppedFrames,row.ReferenceStoppedFrames, ...
   row.CorrectStoppedFrames-row.ReferenceStoppedFrames,row.CorrectStopTotalMatch,"from mask versus sum of reference stop-duration list"};
 end
 allComparisons{end+1}=comparison; %#ok<AGROW>
 if isfile([base '.profiles.mat'])
  row.ProfilesPresent=true;D=load([base '.profiles.mat']);P=D.P;clear D
  assert(isequal(size(P.unweighted),[C.decodedVideoSize(1),n])&&isequal(size(P.probabilityWeighted),size(P.unweighted)));
  assert(isequal(P.originalFrames,C.originalFrames)&&isequal(P.timeSeconds,C.timeSeconds));
  assert(isequal(P.tailBadFrames,C.tailBadFrames(:))&&all(isnan(P.unweighted(:,1)))&&all(isnan(P.probabilityWeighted(:,1))));
  invalid=P.invalidFramePairMask|P.weightedNoMotion;
  assert(all(isnan(P.weightedPosition(invalid)))&&all(isnan(P.weightedBelowBarFraction(invalid))));
  invalidU=P.invalidFramePairMask|P.unweightedNoMotion;
  assert(all(isnan(P.unweightedPosition(invalidU)))&&all(isnan(P.unweightedBelowBarFraction(invalidU))));
  Q=double(P.probabilityWeighted);total=sum(Q,1)';derived=sum(Q.*P.rowHeightRelativeToBar,1)'./total;
  valid=isfinite(P.weightedPosition);assert(all(abs(derived(valid)-P.weightedPosition(valid))<2e-4),'Compressed profile index differs');
  U=double(P.unweighted);totalU=sum(U,1)';derivedU=sum(U.*P.rowHeightRelativeToBar,1)'./totalU;
  validU=isfinite(P.unweightedPosition);assert(all(abs(derivedU(validU)-P.unweightedPosition(validU))<2e-4));
  row.ProfilesVerified=all(P.scalarReconstructionMatch);row.ValidWeightedHeightSamples=sum(valid);row.ValidUnweightedHeightSamples=sum(validU);
  clear P Q U total totalU derived derivedU
 end
 E=C.events;E.StartTimeSeconds=nan(height(E),1);E.EndTimeSeconds=nan(height(E),1);E.MidpointTimeSeconds=nan(height(E),1);
 E.DurationSecondsEncoded=nan(height(E),1);E.XEntryRightPixels=nan(height(E),1);E.PositionExtractionVerified=false(height(E),1);
 E.EntryDirectionConsistent=repmat(C.entryDirectionConsistent,height(E),1);
 rawTiming=jsondecode(fileread(fullfile(outputDir,'metadata',[z.file '.json'])));
 allTimes=rawTiming.timestampsSeconds(:);lastDuration=median(diff(allTimes));
 fullDurations=diff([allTimes;allTimes(end)+lastDuration]);durations=fullDurations(C.originalFrames);clear rawTiming allTimes fullDurations
 for k=1:height(E)
  a=E.StartTraversalFrame(k);b=E.EndTraversalFrame(k);m=E.SampledMidpointTraversalFrame(k);
  if a<1||b>n||m<1||m>n,continue;end
  assert(m==floor((a+b)/2));assert(E.StartOriginalFrame(k)==C.originalFrames(a)&&E.EndOriginalFrame(k)==C.originalFrames(b));
  E.PositionExtractionVerified(k)=isequaln(E.CentroidX(k),C.mouseCentroids(m,1))&&isequaln(E.XEntryRightFraction(k),C.xEntryRightFraction(m));
  assert(E.PositionExtractionVerified(k),'Saved event position differs from captured centroid');
  E.StartTimeSeconds(k)=C.timeSeconds(a);E.EndTimeSeconds(k)=C.timeSeconds(b);
  mid=(a+b)/2;E.MidpointTimeSeconds(k)=mean(C.timeSeconds([floor(mid),ceil(mid)]));
  E.DurationSecondsEncoded(k)=sum(durations(a:b));E.XEntryRightPixels(k)=C.xEntryRight(m);
 end
 row.EventsWithMissingPosition=sum(~E.PositionFinite);
 row.ValidSlipPlotCrossing=row.SlipsValidated&&row.SlipsReferenceMatch&&row.CentroidsReferenceMatch&&row.DirectionConsistent;
 row.ValidStopPlotCrossing=row.StopsValidated&&row.StopsReferenceMatch&&row.CentroidsReferenceMatch&&row.DirectionConsistent&&row.CorrectStopTotalMatch;
 E.EligibleForPositionPlot=(E.Type=="slip"&row.ValidSlipPlotCrossing)|(E.Type=="stop"&row.ValidStopPlotCrossing);
 E.EligibleForPositionPlot=E.EligibleForPositionPlot&E.PositionFinite&E.PositionExtractionVerified;
 % Denominator counts a crossing once in each camera-field bin actually visited.
 coverage(j,:)=histcounts(C.xEntryRightFraction(isfinite(C.xEntryRightFraction)),edges)>0;
 writetable(E,[base '.events.csv']);allEvents{end+1}=E;rows=[rows;row]; %#ok<AGROW>
 if mod(j,25)==0,fprintf('FINAL_VERIFY %d/%d\n',j,numel(M.files));end
 clear C E comparison
end
trials=struct2table(rows);events=vertcat(allEvents{:});comparison=vertcat(allComparisons{:});
writetable(trials,fullfile(outputDir,'trial_manifest.csv'));writetable(events,fullfile(outputDir,'events.csv'));
writetable(comparison,fullfile(outputDir,'comparison_by_file.csv'));
save(fullfile(outputDir,'dataset_index.mat'),'trials','events','comparison','coverage','edges','-v7');
missing=setdiff(refFiles,trials.File);extra=setdiff(trials.File,refFiles);
fid=fopen(fullfile(outputDir,'reference_coverage.txt'),'w');fprintf(fid,'Reference files absent from source manifest: %d\n',numel(missing));fprintf(fid,'%s\n',missing);fprintf(fid,'Source files absent from reference: %d\n',numel(extra));fprintf(fid,'%s\n',extra);fclose(fid);
auditSavedTaraBeamEvents(outputDir,events);
plotPositions(outputDir,trials,events,coverage,edges);
fprintf('FINAL COMPLETE %d/%d; profiles verified %d; slips eligible %d stops eligible %d\n',sum(trials.Status=="complete"),height(trials),sum(trials.ProfilesVerified),sum(trials.ValidSlipPlotCrossing),sum(trials.ValidStopPlotCrossing));
end

function plotPositions(outputDir,trials,events,coverage,edges)
% Descriptive counts per available crossing, not independent-event inference.
groups=["sedentary","walk","run"]; colors=[.35 .35 .35;.15 .55 .78;.86 .3 .2];
B=table('Size',[0 12],'VariableTypes',[{'string','string'},repmat({'double'},1,10)], ...
 'VariableNames',{'EventType','Group','Day','BinStart','BinEnd','BinCenter','Events','AvailableCrossings','EventsPerAvailableCrossing','EligibleCrossings','ExpectedCrossings','EligibleMice'});
N=table('Size',[0 10],'VariableTypes',[{'string','string'},repmat({'double'},1,8)], ...
 'VariableNames',{'EventType','Group','Day','ExpectedCrossings','EligibleCrossings','ExcludedCrossings','EligibleMice','EligibleCages','EventsWithPosition','EventsMissingPosition'});
f=figure('Visible','off','Color','w','Position',[80 80 1450 860]);t=tiledlayout(2,2,'TileSpacing','compact','Padding','compact');axesByPanel=gobjects(2,2);
for ti=1:2
 type=["slip","stop"];type=type(ti);
 for di=1:2
  day=[0 14];day=day(di);ax=nexttile;axesByPanel(ti,di)=ax;hold on
  for gi=1:3
   group=groups(gi);expected=trials.Day==day&trials.Group==group;
   if type=="slip",eligible=expected&trials.ValidSlipPlotCrossing;else,eligible=expected&trials.ValidStopPlotCrossing;end
   names=trials.File(eligible);e=events.Type==type&events.Day==day&events.Group==group&ismember(events.File,names);
   loc=e&events.EligibleForPositionPlot;counts=histcounts(events.XEntryRightFraction(loc),edges);
   exposure=sum(coverage(eligible,:),1);rate=counts./exposure;rate(exposure==0)=NaN;
   % A failed/mismatched subgroup must remain visible as unavailable, not zero.
   centers=(edges(1:end-1)+edges(2:end))/2;
   stairs([edges(1:end-1) edges(end)]*100,[rate rate(end)],'Color',colors(gi,:),'LineWidth',1.8, ...
    'DisplayName',sprintf('%s: %d/%d crossings, %d mice',group,sum(eligible),sum(expected),numel(unique(trials.MouseID(eligible)))));
   for k=1:20
    B(end+1,:)={type,group,day,edges(k),edges(k+1),centers(k),counts(k),exposure(k),rate(k),sum(eligible),sum(expected),numel(unique(trials.MouseID(eligible)))};
   end
   N(end+1,:)={type,group,day,sum(expected),sum(eligible),sum(expected)-sum(eligible),numel(unique(trials.MouseID(eligible))),numel(unique(trials.CageID(eligible))),sum(loc),sum(e&~events.PositionFinite)};
  end
  title(sprintf('D%d | %ss',day,type));xlabel('Aligned horizontal position (% camera field; entry on right)');ylabel('Events / crossing visiting bin');
  xlim([0 100]);ylim([0 inf]);grid on;legend('Location','best','FontSize',9);ax.FontSize=11;
 end
end
for ti=1:2
 limits=cell2mat(get(axesByPanel(ti,:), 'YLim')); upper=max(limits(:,2)); if upper<=0,upper=1;end
 set(axesByPanel(ti,:),'YLim',[0 upper]);
end
title(t,{'Exploratory event positions | 5% field-width bins','Algorithm-defined events; validated reference summaries and centroids; no manual onset ground truth'},'FontWeight','normal');
writetable(B,fullfile(outputDir,'position_bin_counts.csv'));writetable(N,fullfile(outputDir,'position_plot_denominators.csv'));
exportgraphics(f,fullfile(outputDir,'plots','D0_D14_event_positions.png'),'Resolution',170);
print(f,fullfile(outputDir,'plots','D0_D14_event_positions.svg'),'-dsvg');
% Portable FIG: save visible/normal with an on-open recenter callback.
set(f,'Visible','on','WindowStyle','normal','CreateFcn','movegui(gcbf,''center'')');movegui(f,'center');
figPath=fullfile(outputDir,'plots','D0_D14_event_positions.fig');savefig(f,figPath);close(f)
g=openfig(figPath,'new');assert(strcmp(g.Visible,'on')&&strcmp(g.WindowStyle,'normal'));assert(contains(g.CreateFcn,'movegui'));close(g)
end
