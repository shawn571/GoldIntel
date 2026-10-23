#!/usr/bin/env python3
"""Builds and VERIFIES the GoldIntel Phase 1 delivery packages.

Why this exists: in sessions S-002 and S-003 individual files were delivered one by one and some
(GIMin/Sub/*.lua, GoldIntelDiag/SrcV*.lua) never reached the user, which caused "Error loading".
Packages are built as zip archives and every file named in a TOC is checked before zipping.

Usage:  python3 tools/build_package.py        (run from the folder that contains GoldIntel/)
Output: GoldIntel_Phase2_AddOns.zip          (extract into the game's AddOns folder)
        GoldIntel_Phase2_Dev.zip             (source + tests + docs + tools, for developers)
"""
import hashlib, os, re, sys, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDONS = ['GoldIntel', 'GIMin', 'GoldIntelDiag']
LONG = '=' * 5

def toc_files(addon):
    path = os.path.join(ROOT, addon, addon + '.toc')
    files = []
    for line in open(path, encoding='ascii').read().splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            files.append(line.replace('\\', '/'))
    return files

def fail(msg):
    print('PACKAGE ERROR:', msg)
    sys.exit(1)

def verify():
    for addon in ADDONS:
        for f in toc_files(addon):
            p = os.path.join(ROOT, addon, f)
            if not os.path.isfile(p):
                fail('%s.toc lists %s but the file does not exist' % (addon, f))
            if f.endswith('.lua') or f.endswith('.toc'):
                raw = open(p, 'rb').read()
                if b'\r' in raw: fail(p + ' contains CR')
                if any(c > 127 for c in raw): fail(p + ' contains non-ASCII bytes')
    print('TOC check: every file listed in every TOC exists (GoldIntel, GIMin, GoldIntelDiag)')

def generate_sources():
    files = [f for f in toc_files('GoldIntel') if f.endswith('.lua')]
    version = re.search(r"P.VERSION = '([^']+)'", open(os.path.join(ROOT, 'GoldIntel', 'Platform', 'Platform.lua'), encoding='ascii').read()).group(1)
    out = ['-- Generated embedded copy of every GoldIntel Lua file in TOC order (do not edit; see tools/build_package.py).',
           'local _, ns = ...', 'ns.sources = ns.sources or {}', 'ns.sources.version = "%s"' % version,
           'ns.sources.current = {']
    for f in files:
        txt = open(os.path.join(ROOT, 'GoldIntel', f), encoding='ascii').read()
        if (']' + LONG + ']') in txt or ('[' + LONG + '[') in txt: fail('long-bracket clash in ' + f)
        out.append('{ path = "%s", src = [%s[\n%s]%s] },' % (f, LONG, txt, LONG))
    out.append('}\n')
    for old in ('SrcV012.lua', 'SrcV011.lua', 'SrcV010.lua'):
        op = os.path.join(ROOT, 'GoldIntelDiag', old)
        if os.path.exists(op): os.remove(op)
    open(os.path.join(ROOT, 'GoldIntelDiag', 'SrcCurrent.lua'), 'w', newline='\n').write('\n'.join(out))

def manifest():
    lines = ['GoldIntel package manifest. Verify the files you installed against this list.',
             'Windows:    certutil -hashfile <file> SHA256',
             'PowerShell: Get-FileHash <file> -Algorithm SHA256', '']
    for addon in ADDONS:
        lines.append('== %s ==' % addon)
        base = os.path.join(ROOT, addon)
        names = []
        for dp, dn, fn in os.walk(base):
            if os.path.relpath(dp, base).split(os.sep)[0] == 'Tests': continue
            for n in fn:
                if n == 'MANIFEST.txt': continue
                names.append(os.path.relpath(os.path.join(dp, n), base).replace(os.sep, '/'))
        for n in sorted(names):
            data = open(os.path.join(base, n), 'rb').read()
            lines.append('%-26s %7d bytes  sha256 %s' % (n, len(data), hashlib.sha256(data).hexdigest()))
        lines.append('')
    open(os.path.join(ROOT, 'GoldIntelDiag', 'MANIFEST.txt'), 'w', newline='\n').write('\n'.join(lines))

def zip_addons(zpath):
    with zipfile.ZipFile(zpath, 'w', zipfile.ZIP_DEFLATED) as z:
        for addon in ADDONS:
            base = os.path.join(ROOT, addon)
            for dp, dn, fn in sorted(os.walk(base)):
                rel = os.path.relpath(dp, base)
                if rel.split(os.sep)[0] == 'Tests': continue
                for n in sorted(fn):
                    z.write(os.path.join(dp, n), arcname=addon + '/' + os.path.normpath(os.path.join(rel, n)).replace(os.sep, '/'))

def zip_dev(zpath):
    with zipfile.ZipFile(zpath, 'w', zipfile.ZIP_DEFLATED) as z:
        for top in ADDONS + ['GoldIntel_Docs', 'tools']:
            base = os.path.join(ROOT, top)
            for dp, dn, fn in sorted(os.walk(base)):
                for n in sorted(fn):
                    z.write(os.path.join(dp, n), arcname=os.path.relpath(os.path.join(dp, n), ROOT).replace(os.sep, '/'))

def check_zip(zpath, addon_only):
    names = zipfile.ZipFile(zpath).namelist()
    for addon in ADDONS:
        for f in toc_files(addon):
            want = addon + '/' + f
            if want not in names: fail('%s is missing %s' % (os.path.basename(zpath), want))
        if addon + '/' + addon + '.toc' not in names: fail('toc missing for ' + addon)
    if addon_only and any(n.split('/')[1:2] == ['Tests'] for n in names): fail('Tests folder leaked into AddOns zip')
    return names

if __name__ == '__main__':
    generate_sources(); verify(); manifest(); verify()
    a = os.path.join(ROOT, 'GoldIntel_Phase2_AddOns.zip'); d = os.path.join(ROOT, 'GoldIntel_Phase2_Dev.zip')
    zip_addons(a); zip_dev(d)
    names = check_zip(a, True); check_zip(d, False)
    print('\nGoldIntel_Phase2_AddOns.zip contains %d files:' % len(names))
    for n in names: print('   ' + n)
    print('\nGoldIntel_Phase2_Dev.zip contains %d files' % len(zipfile.ZipFile(d).namelist()))
    print('ZIP check: every TOC-listed file of all three addons is inside both archives')
