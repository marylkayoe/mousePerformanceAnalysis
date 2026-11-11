"""D14-only counterpart to the exploratory prioritized change comparisons."""
from pathlib import Path
import csv, json, runpy, math

ROOT = Path(__file__).resolve().parents[1] / 'BEAMCROSS/DRAFTFIGS'
OUT = ROOT / 'outcome-specific-contrasts/D14-only'
OUT.mkdir(exist_ok=True)
test = runpy.run_path(str(ROOT/'tail-metrics/whole-motion-reweighted/cage_tests.py'))['test']
domains = {'Forward locomotion': [('speed','Locomoting speed'),('time_stopped','Time stopped'),('posture','Posture height')],
           'Slipping': [('slip_count','Slip count'),('slip_score','Total slip score')],
           'Tail': [('motion_height','Motion height'),('tail_score','Tail-motion score')]}
results=[]; inputs=[]
for domain,metrics in domains.items():
    for key,label in metrics:
        provenance=json.loads((ROOT/'contrast-layout-examples'/f'{key}_baseline_changes_contrasts.json').read_text())
        rows=list(csv.DictReader((ROOT/provenance['source']).open()))
        rows=[dict(r,value=float(r[provenance['field']])*provenance['conversion']) for r in rows
              if r['day']=='D14' and (key not in ('slip_count','slip_score') or int(r['nRuns'])==3)]
        assert len(rows)==42 and len({r['mouseID'] for r in rows})==42
        assert all(math.isfinite(r['value']) for r in rows)
        omnibus,pairs=test(rows)
        for a,b in [('run','walk'),('run','sedentary'),('walk','sedentary')]:
            p=next(r for r in pairs if r['pair']==f'{a} minus {b}')
            results.append(dict(domain=domain,metric=key,label=label,period='D14',
                role='primary' if b=='walk' else 'secondary',contrast=p['pair'],unit=provenance['unit'],
                difference=p['difference_cage_cohort_balanced'],p_direct_two_sided=p['p_raw'],
                previous_holm_three_pairs=p['p_holm_3_pairs'],n_mice=len(rows),
                n_cages=len({(r['cohort'],r['cageID']) for r in rows}),source=provenance['source'],
                source_field=provenance['field'],conversion=provenance['conversion']))
        for r in rows:
            inputs.append(dict(metric=key,mouseID=r['mouseID'],cohort=r['cohort'],cageID=r['cageID'],group=r['group'],value=r['value']))
for name,rows in [('results',results),('mouse_values',inputs)]:
    with (OUT/(name+'.csv')).open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
(OUT/'results.json').write_text(json.dumps(results,indent=2))
report='''# D14-only outcome-specific comparisons

Same exploratory question priority as ../REPORT.md: RUN–WALK primary per outcome; RUN–SED and WALK–SED secondary context. Direct two-sided exact cage-permutation p-values, without a three-pair adjustment or across-outcome error-control claim. Previous Holm values retained in results.csv/json. No omnibus gate or selection of favorable comparisons.

These are D14 levels, not paired changes and not baseline-adjusted estimates. All seven outcomes have 42 mice (12 SED,12 WALK,18 RUN), 15 cages, two cohorts; the three-crossing filter is retained for slip outcomes and the stopped-percentage source. Unlike the change analysis, D14 slipping/stopping includes the mouse with only two D0 crossings. Calculations use within-cage mouse means, group cage-mean differences within each cohort, and equal averaging across cohorts. Permutations preserve cage counts within each cohort and compare only the two groups. Nonrandom allocation leaves exchangeability uncertain. Outcome definitions/units and original input files are recorded in results.csv/json. Negative difference means lower D14 value in the first named group.

| Domain | Metric | RUN–WALK difference | Unit | RUN–WALK p, primary | RUN–SED p, secondary | WALK–SED p, secondary |
|---|---|---:|---|---:|---:|---:|
'''
for domain,metrics in domains.items():
    for key,label in metrics:
        a,b,c=[r for r in results if r['metric']==key]
        report+=f"| {domain} | {label} | {a['difference']:.4g} | {a['unit']} | {a['p_direct_two_sided']:.4f} | {b['p_direct_two_sided']:.4f} | {c['p_direct_two_sided']:.4f} |\n"
report+='\nReproduce: tests/analyzeD14OutcomeSpecificContrasts.py. Existing outputs preserved; no canonical data modified. Do not select D14 rather than change because its p-value is smaller: the former asks about final levels, the latter about differences in changes. Nonsignificance does not establish equivalence.\n'
(OUT/'REPORT.md').write_text(report)
print(report)
