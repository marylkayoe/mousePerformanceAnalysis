"""Exploratory outcome-specific contrasts; exact cage permutations within cohort.

Inputs are the audited mouse-level D14-D0 CSVs from plotAllMetricContrastPanels.py.
No primary endpoint is selected on the basis of its p-value. Original results survive.
"""
from pathlib import Path
import csv, json, itertools, statistics, collections, math
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1] / 'BEAMCROSS/DRAFTFIGS'
SRC = ROOT / 'contrast-layout-examples'
OUT = ROOT / 'outcome-specific-contrasts'
OUT.mkdir(exist_ok=True)
DOMAINS = {'Forward locomotion': [('speed', 'Locomoting speed'), ('time_stopped', 'Time stopped'), ('posture', 'Posture height')],
           'Slipping': [('slip_count', 'Slip count'), ('slip_score', 'Total slip score')],
           'Tail': [('motion_height', 'Motion height'), ('tail_score', 'Tail-motion score')]}
PAIRS = [('run', 'walk'), ('run', 'sedentary'), ('walk', 'sedentary')]

def holm(ps):
    out = [0.] * len(ps); running = 0.
    for rank, i in enumerate(sorted(range(len(ps)), key=ps.__getitem__)):
        running = max(running, (len(ps)-rank)*ps[i]); out[i] = min(1., running)
    return out

def exact(rows, a, b):
    cells = collections.defaultdict(list)
    for r in rows:
        if r['Group'] in (a, b): cells[r['Cohort'], r['CageID'], r['Group']].append(float(r['Value']))
    obs = []; nulls = []; counts = {}
    for co in ('TMCS2', 'TMCS3'):
        cages = sorted((g, statistics.mean(v)) for (c, ca, g), v in cells.items() if c == co)
        na = sum(g == a for g, v in cages); n = len(cages)
        counts[co] = {a: na, b: n-na}
        obs.append(statistics.mean(v for g,v in cages if g==a)-statistics.mean(v for g,v in cages if g==b))
        permutations = []
        for selected in itertools.combinations(range(n), na):
            s = set(selected)
            permutations.append(statistics.mean(v for i,(g,v) in enumerate(cages) if i in s)-statistics.mean(v for i,(g,v) in enumerate(cages) if i not in s))
        nulls.append(permutations)
    effect = statistics.mean(obs)
    null = [(x+y)/2 for x in nulls[0] for y in nulls[1]]
    return effect, sum(abs(v)>=abs(effect)-1e-12 for v in null)/len(null), len(null), counts, obs

results = []
for domain, metrics in DOMAINS.items():
    for key, label in metrics:
        stem = SRC / (key+'_baseline_changes_contrasts')
        old = json.loads(stem.with_suffix('.json').read_text())
        rows = [r for r in csv.DictReader(stem.with_suffix('.csv').open()) if r['Period']=='D14-D0']
        assert len(rows)==old['nPaired'] and all(math.isfinite(float(r['Value'])) for r in rows)
        for a,b in PAIRS:
            effect,p,n,counts,cohort_effects = exact(rows,a,b)
            prior = next(r for r in old['allThreePairTests'] if r['pair']==a+' minus '+b)
            assert abs(p-prior['p_raw'])<1e-12 and abs(effect-prior['difference_cage_cohort_balanced'])<1e-9
            results.append(dict(domain=domain,metric=key,label=label,role='primary' if b=='walk' else 'secondary',
                contrast=a+' minus '+b,unit='percentage points' if key=='time_stopped' else old['unit'],
                difference=effect,p_direct_two_sided=p,previous_holm_three_pairs=prior['p_holm_3_pairs'],
                n_mice=len(rows),n_permutations=n,cages=counts,cohort_differences=cohort_effects))
    primary = [r for r in results if r['domain']==domain and r['role']=='primary']
    for r,p in zip(primary,holm([r['p_direct_two_sided'] for r in primary])):
        r['sensitivity_holm_primary_outcomes_within_domain'] = p

# Updated editable triptychs retain measurements and descriptive intervals; labels
# now distinguish the primary contrast and secondary context. Never overwrite originals.
ET.register_namespace('', 'http://www.w3.org/2000/svg')
for domain,metrics in DOMAINS.items():
    for key,label in metrics:
        tree = ET.parse(SRC/(key+'_baseline_changes_contrasts.svg'))
        rs = [r for r in results if r['metric']==key]
        for el in tree.getroot().iter('{http://www.w3.org/2000/svg}text'):
            txt = el.text or ''; y=float(el.get('y','0'))
            if txt=='Beyond shared routine': el.text='PRIMARY: beyond shared routine'
            elif txt=='Overall procedure': el.text='SECONDARY: overall procedure'
            elif txt.startswith('Holm p ='):
                r=rs[0 if y<200 else 1]; el.text=f"Direct p = {r['p_direct_two_sided']:.3f}"
            elif y==344: el.text='Exploratory outcome-specific tests; direct two-sided p-values, without three-pair Holm adjustment.'
            elif y==361: el.text='95% cage-bootstrap intervals are descriptive and limited by sparse cages. Secondary WALK–SED results: report.'
        tree.write(OUT/(key+'_prioritized_contrasts.svg'),encoding='unicode',xml_declaration=True)

(OUT/'results.json').write_text(json.dumps(results,indent=2))
with (OUT/'results.csv').open('w',newline='') as f:
    fields=[k for k in results[0] if k not in ('cages','cohort_differences')]+['sensitivity_holm_primary_outcomes_within_domain']
    w=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');w.writeheader();w.writerows(results)

report = '''# Outcome-specific, prioritized balance-beam comparisons — 2026-11-11

## Questions and scope

RUN–WALK is the primary comparison for each outcome: the additional demanding running protocol beyond the shared daily treadmill/control routine. RUN–SED describes the overall protocol difference; WALK–SED characterizes the control routine. Neither contrast isolates coordination learning from exertion, stress, or other protocol differences.

This exploratory prioritization was specified after inspecting results, motivated by the user's original active-control rationale. It is not a retrospective claim of a prespecified testing hierarchy. No gatekeeping procedure is used. All comparisons are reported, regardless of p-value. The main direct p-values have no three-pair or seven-outcome adjustment. They do not control the chance of any false positive across the study. Secondary findings cannot substitute for failure of the primary comparison. No effect is established as absent or equivalent by a nonsignificant test.

## Calculation and verification

Within-mouse D14 minus D0 changes; mean within each cage; difference between group cage means within each cohort; equal average across the two cohorts. Exact, two-sided permutations relabel whole cages between only the two compared groups within cohort, preserving group cage counts. All 21 direct p-values and estimates independently recomputed from the saved mouse-level CSVs match the previous analysis to numerical tolerance. The new analysis changes the inferential priority and multiplicity reporting, not the underlying estimates or permutation distributions. No global ANOVA gate is required for the chosen contrast.

42 paired mice for speed/posture/tail and 41 for slipping/stopped percentage (three-crossing requirement). Each domain still has 15 cages: SED 4, WALK 4, RUN 7. Cohort TMCS3 has just one WALK cage. Since allocation was not randomized, exchangeability is an assumption, not guaranteed by the experimental design; preserving cage/cohort structure does not eliminate confounding.

Outcome definitions remain those of the current figure. Speed is the locomoting-speed mean, posture is centroid height, slip score is accumulated above-threshold detector score (not anatomical slip severity), stopped time is percent traversal duration, motion height is the motion-weighted height index, and tail score is the corrected whole-range Legacy scalar. Tail height is not direct stationary-tail position. Original source definitions and provenance remain in contrast-layout-examples/*.json and FIGURE_HANDOFF_20261111.md.

## Results: direct two-sided p-values

Negative differences indicate RUN (or WALK in WALK–SED) decreased more/increased less.

| Domain | Outcome | RUN–WALK difference | Unit | RUN–WALK p (primary) | RUN–SED p (secondary) | WALK–SED p (secondary) |
|---|---|---:|---|---:|---:|---:|
'''
for domain,metrics in DOMAINS.items():
    for key,label in metrics:
        rs=[r for r in results if r['metric']==key];r=rs[0]
        report+=f"| {domain} | {label} | {r['difference']:.4g} | {r['unit']} | {rs[0]['p_direct_two_sided']:.4f} | {rs[1]['p_direct_two_sided']:.4f} | {rs[2]['p_direct_two_sided']:.4f} |\n"
report+='''
## Domain-level sensitivity, not the main outcome-specific analysis

The user's three domains are locomotion (speed, stopping, posture), slipping (count, score), and tail (height, score). If a claim is that *at least one outcome within a domain* changes, there are respectively three, two, and two opportunities for that claim. As a sensitivity calculation only, the CSV supplies Holm across RUN–WALK outcomes within each domain. This is NOT Holm across the three group contrasts, NOT correction across seven endpoints, and NOT a joint multivariate domain test. None of the direct primary tests is below .05, so this sensitivity does not change that conclusion. Outcomes need not measure the same quantity for a family-level claim to create multiplicity. The domain grouping alone does not imply statistical independence or authorize selecting the best p-value.

## Figures and interpretation

The seven *_prioritized_contrasts.svg files retain D0, change scatters, and descriptive effect intervals, replacing the old Holm labels with direct p-values and explicit PRIMARY/SECONDARY roles. WALK–SED estimates are in results.csv/json. Bootstrap intervals were retained from the prototype (100,000 cage resamples within cohort/group); sparse cages can make them too narrow, they are unadjusted, and they are not inverted exact-permutation confidence intervals. Do not interpret interval exclusion of zero as significance of the displayed permutation test. Original figures remain untouched.

Reproduce: tests/analyzeOutcomeSpecificContrasts.py, after tests/plotAllMetricContrastPanels.py. No videos or canonical results modified; only small repository figure/report outputs created. General background on grouping/ordering endpoints: https://www.fda.gov/regulatory-information/search-fda-guidance-documents/multiple-endpoints-clinical-trials (clinical-trial guidance used for the general multiplicity principle, not as a regulatory requirement for this animal study).
'''
(OUT/'REPORT.md').write_text(report)
print(report[report.index('| Domain'):report.index('## Domain-level')])
print('Verified all 21 contrasts; wrote',OUT)
