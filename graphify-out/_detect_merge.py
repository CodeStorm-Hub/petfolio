import json, sys, os
from graphify.detect import detect
from pathlib import Path
sys.stdout.reconfigure(encoding='utf-8')

d_lib = detect(Path('lib'))
d_sup = detect(Path('supabase'))

merged_files = {}
for ftype in set(list(d_lib.get('files',{}).keys()) + list(d_sup.get('files',{}).keys())):
    merged_files[ftype] = list(d_lib.get('files',{}).get(ftype, [])) + list(d_sup.get('files',{}).get(ftype, []))

total_files = d_lib.get('total_files',0) + d_sup.get('total_files',0)
total_words = d_lib.get('total_words',0) + d_sup.get('total_words',0)

merged = {
    'scan_root': str(Path('.').resolve()),
    'total_files': total_files,
    'total_words': total_words,
    'files': merged_files,
    'skipped_sensitive': d_lib.get('skipped_sensitive',[]) + d_sup.get('skipped_sensitive',[]),
}
Path('graphify-out/.graphify_detect.json').write_text(json.dumps(merged, ensure_ascii=False), encoding='utf-8')

for ftype, flist in merged_files.items():
    if flist:
        exts = set(os.path.splitext(f)[1] for f in flist[:30] if os.path.splitext(f)[1])
        ext_str = ' '.join(sorted(exts)[:6])
        print(ftype + ': ' + str(len(flist)) + ' files (' + ext_str + ')')
print('Total: ' + str(total_files) + ' files, ~' + str(total_words) + ' words')
