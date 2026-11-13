# Presentation-only SVG edit; preserve all content outside marker dimensions.
source=File.expand_path('../BEAMCROSS/DRAFTFIGS/within-session-diagnostics-20261112/supplied_first_last_speed.svg',__dir__)
out=File.expand_path('../BEAMCROSS/DRAFTFIGS/within-session-diagnostics-20261112/first_to_last_locomoting_speed_D0_D14_markers_matched.svg',__dir__)
s=File.read(source)
n=0
r=s.gsub(/<ellipse\b[^>]*\/>/) do |tag|
 n+=1
 tag.sub(/rx="[^"]*"/,'rx="1.3"').sub(/ry="[^"]*"/,'ry="1.3"')
end
m=0
r=r.gsub(/<polygon\b[^>]*\/>/) do |tag|
 m+=1
 points=tag[/points="([^"]*)"/,1].split.map(&:to_f).each_slice(2).to_a
 xs=points.map(&:first);ys=points.map(&:last);cx=(xs.min+xs.max)/2;cy=(ys.min+ys.max)/2
 pts=points.map{|x,y| [cx+(x-cx)*3.2/(xs.max-xs.min),cy+(y-cy)*4.03/(ys.max-ys.min)].map{|v|format('%.5f',v)}.join(' ')}.join(' ')
 tag.sub(/points="[^"]*"/,"points=\"#{pts}\"")
end
raise unless n==84 && m==30
strip=lambda{|x|x.gsub(/<ellipse\b[^>]*\/>/,'ELLIPSE').gsub(/<polygon\b[^>]*\/>/,'POLYGON')}
raise 'Non-marker content changed' unless strip.call(r)==strip.call(s)
File.write(out,r)
puts "#{out}\n84 mouse markers; 30 cage diamonds. All non-marker content unchanged."
# Explicit reference colours avoid Illustrator rgba() import differences.
r=r.sub('rgba(35, 35, 35, .4)','#a7a7a7').sub('rgba(0, 141, 63, .4)','#99d1b2').sub('rgba(8, 100, 207, .4)','#9cc1ec')
File.write(out,r)
