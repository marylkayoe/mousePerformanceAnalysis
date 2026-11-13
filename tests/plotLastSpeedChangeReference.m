function plotLastSpeedChangeReference
% Presentation only: reuse saved last-retained-trial spatial summaries.
root=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(root,'BEAMCROSS','DRAFTFIGS','last-crossing-spatial');
ref=fullfile(out,'speed_change_reference_template.svg');
s=fileread(ref);
opts=detectImportOptions(fullfile(out,'group_profiles.csv')); opts=setvartype(opts,{'metric','period','group'},'string'); T=readtable(fullfile(out,'group_profiles.csv'),opts);
opts=detectImportOptions(fullfile(out,'mouse_profiles.csv')); opts=setvartype(opts,{'metric','period','group'},'string'); M=readtable(fullfile(out,'mouse_profiles.csv'),opts);
S=readtable(fullfile(out,'selected_crossings.csv'),'TextType','string');
assert(height(S)==84 && numel(unique(S.MouseID))==42);
groups=["sedentary","walk","run"]; bands=[8 13 14]; lines=[6 7 5]; counts=[12 12 18];
for g=1:3
 t=T(T.metric=="speed" & T.period=="change" & T.group==groups(g),:);
 t=sortrows(t,'positionMM');
 assert(numel(unique(S.MouseID(S.Group==groups(g))))==counts(g));
 for j=1:height(t)
  v=M.value(M.metric=="speed" & M.period=="change" & M.group==groups(g) & abs(M.positionMM-t.positionMM(j))<1e-8);
  v=v(isfinite(v)); assert(numel(v)==t.nMice(j));
  assert(abs(mean(v)-t.mean(j))<1e-9);
  assert(abs(std(v)/sqrt(numel(v))-t.SEM(j))<1e-9);
 end
 x=1.67+t.positionMM/700*160; y=70-t.mean*.5;
 good=isfinite(y)&isfinite(t.SEM)&t.nMice>=counts(g)/2;
 edges=diff([false;good;false]); a=find(edges==1); b=find(edges==-1)-1;
 poly=''; path='';
 for k=1:numel(a)
  ix=a(k):b(k); xx=x(ix); yy=y(ix); e=t.SEM(ix)*.5;
  pts=sprintf('%.5f,%.5f ',[ [xx;flipud(xx)] [yy-e;flipud(yy+e)] ]');
  poly=[poly sprintf('<polygon class="cls-%d" points="%s"/>',bands(g),pts)]; %#ok<AGROW>
  d=['M' sprintf('%.5f,%.5f ',[xx yy]')];
  path=[path sprintf('<path class="cls-%d" d="%s"/>',lines(g),d)]; %#ok<AGROW>
 end
 s=regexprep(s,sprintf('<polygon class="cls-%d"[^>]*/>',bands(g)),poly);
 s=regexprep(s,sprintf('<path class="cls-%d"[^>]*/>',lines(g)),path);
 fprintf('%s: %d mice; displayed %d/%d bins; mean+/-SEM range %.3f to %.3f mm/s\n',groups(g),counts(g),sum(good),height(t),min(t.mean(good)-t.SEM(good)),max(t.mean(good)+t.SEM(good)));
end
s=strrep(s,'fill: rgba(35, 35, 35, .16);','fill: #232323; fill-opacity: .16;');
s=strrep(s,'fill: rgba(0, 178, 38, .16);','fill: #00b226; fill-opacity: .16;');
s=strrep(s,'fill: rgba(0, 43, 255, .16);','fill: #002bff; fill-opacity: .16;');
% Extend bottom space for negative changes; preserve vertical mm/s scaling.
s=strrep(s,'161.99 84.57','161.99 103');
s=strrep(s,'M1.67,19v59','M1.67,19v72');
s=strrep(s,'M161.67,19v59','M161.67,19v72');
s=strrep(s,'5.81 80.08','5.81 93.08');
s=strrep(s,'160.02 84.57','160.02 97.57');
s=strrep(s,'104.32 75','104.32 90');
s=strrep(s,'M70.42,77h22.5','M70.42,95h22.85714');
s=strrep(s,'74.72 82.15','74.72 100.15');
s=strrep(s,'</svg>','<desc>Last retained crossing selected independently on D0 and D14. Equal-mouse paired D14 minus D0 mean and SEM. SED grey, WALK green, RUN blue. Spatial speed includes stops. No additional smoothing or inference.</desc></svg>');
fid=fopen(fullfile(out,'speed_change_D14_minus_D0_last_retained_reference.svg'),'w'); fwrite(fid,s,'char'); fclose(fid);
fprintf('Verified saved means and SEM against per-mouse profiles; 42 mice, %d cages.\n',numel(unique(S.CageID)));
end
