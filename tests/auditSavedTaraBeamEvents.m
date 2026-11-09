function auditSavedTaraBeamEvents(outputDir,events)
% Deterministic original-frame registration checks, not biological onset ground truth.
cohorts=["TMCS2","TMCS3"];groups=["sedentary","walk","run"];
A=table('Size',[0 10],'VariableTypes',[repmat({'string'},1,5),repmat({'double'},1,5)], ...
 'VariableNames',{'Cohort','Group','Type','File','AuditImage','Day','Panel','OriginalFrame','CentroidX','CentroidYOriginal'});
for cohort=cohorts
 f=figure('Visible','off','Color','w','Position',[40 40 1500 1050]);layout=tiledlayout(4,3,'TileSpacing','compact','Padding','compact');panel=0;
 for day=[0 14]
  for type=["slip","stop"]
   for group=groups
    panel=panel+1;nexttile;
    selection=find(events.Cohort==cohort&events.Group==group&events.Day==day&events.Type==type&events.EligibleForPositionPlot,1);
    if isempty(selection),axis off;text(.1,.5,sprintf('%s D%d %s: no eligible event',group,day,type));continue;end
    E=events(selection,:);S=load(fullfile(outputDir,'trials',[char(E.File) '.mat']));C=S.C;
    frame=E.SampledMidpointOriginalFrame;relative=E.SampledMidpointTraversalFrame;
    reader=VideoReader(C.sourcePath);I=read(reader,frame);imshow(I);hold on
    yline(C.barTopCoordOriginal,'Color',[1 .8 .1],'LineWidth',.8);
    scatter(C.xOriginal(relative),C.yOriginal(relative),55,'o','MarkerEdgeColor',[0 .8 1],'LineWidth',1.8);
    title(sprintf('%s D%d %s | %s trial %d | f%d',group,day,type,C.identifiers.mouseID,C.identifiers.trialNumber,frame),'Interpreter','none','FontSize',9);
    name=sprintf('event_position_audit_%s.png',cohort);
    A(end+1,:)={cohort,group,type,E.File,string(name),day,panel,frame,C.xOriginal(relative),C.yOriginal(relative)};
    clear C S reader I
   end
  end
 end
 title(layout,{sprintf('%s event-position registration audit',cohort),'First eligible event per group/day/type; cyan circle = exported midpoint centroid; yellow = detected bar'},'FontWeight','normal');
 exportgraphics(f,fullfile(outputDir,'plots',sprintf('event_position_audit_%s.png',cohort)),'Resolution',150);close(f)
end
writetable(A,fullfile(outputDir,'event_position_audit_index.csv'));
end
