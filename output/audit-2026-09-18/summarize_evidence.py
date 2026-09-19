from pathlib import Path
from collections import Counter,defaultdict
import json,hashlib
root=Path(__file__).resolve().parents[2]
out=Path(__file__).resolve().parent

def summarize(file):
 tests={};suites={};results={};errors=defaultdict(list);prints=defaultdict(list);done=None
 for line in file.read_text().splitlines():
  try:e=json.loads(line)
  except ValueError:continue
  t=e.get('type')
  if t=='suite':suites[e['suite']['id']]=e['suite']['path']
  if t=='testStart':tests[e['test']['id']]=e['test']
  if t=='testDone':results[e['testID']]=e
  if t=='error':errors[e['testID']].append(e.get('error',''))
  if t=='print':prints[e.get('testID')].append(e.get('message',''))
  if t=='done':done=e
 counts=Counter();failures=[];loaders=[];skips=[]
 for tid,r in results.items():
  test=tests.get(tid,{}); loading=test.get('name','').startswith('loading ')
  row={'name':test.get('name'),'file':suites.get(test.get('suiteID')),'result':r['result'],'errors':errors[tid],
       'diagnostics':[s for s in prints[tid] if 'EXCEPTION' in s or 'Error' in s or 'overflow' in s]}
  if loading:
   if r['result']!='success':loaders.append(row)
   continue
  if r.get('skipped'):
   skips.append(row);counts['skipped']+=1
  elif r.get('hidden'):counts['hidden']+=1
  else:counts[r['result']]+=1
  if r['result']!='success':failures.append(row)
 expected={str(p.resolve()) for p in (root/'test').rglob('*_test.dart')}
 observed=set(suites.values())
 return {'counts_excluding_suite_loaders':dict(counts),'suite_files_observed':len(observed),'protocol_done':done,
         'missing_test_files':sorted(expected-observed) if file.name=='flutter-tests.jsonl' else [],
         'unfinished_test_names':[t['name'] for tid,t in tests.items() if tid not in results],
         'failed_suite_loaders':loaders,'failures':failures,'skips':skips}
full=summarize(out/'flutter-tests.jsonl'); probes=summarize(out/'audit-probes.jsonl')
(out/'test-failures.json').write_text(json.dumps(full,indent=2))
manifest=json.loads((out/'source-manifest.json').read_text())
changed=[]
for entry in manifest['files']:
 p=root/entry['path']
 if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=entry['sha256']:changed.append(entry['path'])
summary={'full_suite':{k:v for k,v in full.items() if k not in ['failures','skips','failed_suite_loaders']},
         'failed_suite_loaders':len(full['failed_suite_loaders']),
         'independent_probes':probes,'source_files_changed_since_manifest':changed,
         'analyzer':{'errors':1,'informational':7,'log':'flutter-analyze.log'},
         'storage_harness_python_tests':{'passed':22,'log':'storage-harness-tests.log'},
         'limitations':['No physical device or simulator UI acceptance','No native process power-loss validation',
           'No production account isolation or cloud service verification','Catalog semantic accuracy not validated',
           'Full suite regenerates output/pdf artifacts, including previously dirty preview PDFs']}
(out/'verification-summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps({k:v for k,v in summary.items() if k not in ['independent_probes','limitations']},indent=2))
