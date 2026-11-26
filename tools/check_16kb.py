#!/usr/bin/env python3
"""Google Play needs native libraries to work on 16 KB page-size devices.
Checks every 64-bit .so inside an APK or AAB for (1) ELF LOAD segments aligned
to at least 16 KB and (2) uncompressed libs stored at a 16 KB zip offset (APK).
Usage: python3 tools/check_16kb.py path/to/app.apk|app.aab
Exit code 1 if anything fails."""
import struct, sys, zipfile, re

def elf_aligns(d):
    if d[:4] != b'\x7fELF':
        return None
    is64 = d[4] == 2
    if is64:
        phoff = struct.unpack_from('<Q', d, 32)[0]
        ent, num = struct.unpack_from('<HH', d, 54)
    else:
        phoff = struct.unpack_from('<I', d, 28)[0]
        ent, num = struct.unpack_from('<HH', d, 42)
    out = []
    for i in range(num):
        o = phoff + i * ent
        if struct.unpack_from('<I', d, o)[0] == 1:
            out.append(struct.unpack_from('<Q', d, o + 48)[0] if is64
                       else struct.unpack_from('<I', d, o + 28)[0])
    return out

def main(path):
    z = zipfile.ZipFile(path)
    is_apk = path.endswith('.apk')
    bad = []
    n = 0
    for info in z.infolist():
        if not re.search(r'(^|/)lib/(arm64-v8a|x86_64)/[^/]+\.so$', info.filename):
            continue
        n += 1
        al = elf_aligns(z.read(info))
        if al is None or any(a < 16384 for a in al):
            bad.append(f'{info.filename}: ELF align {[hex(a) for a in (al or [])]} (< 0x4000)')
        if is_apk and info.compress_type == 0:
            with open(path, 'rb') as f:
                f.seek(info.header_offset + 26)
                nl, el = struct.unpack('<HH', f.read(4))
            off = info.header_offset + 30 + nl + el
            if off % 16384:
                bad.append(f'{info.filename}: stored at offset {off}, not 16 KB aligned')
    print(f'checked {n} 64-bit libraries in {path}')
    for b in bad:
        print('FAIL', b)
    if not bad:
        print('OK: all 64-bit native libraries are 16 KB compatible')
    return 1 if bad else 0

sys.exit(main(sys.argv[1]))
