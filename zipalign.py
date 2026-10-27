import zipfile
import sys

def zipalign(in_apk, out_apk, alignment=4):
    with zipfile.ZipFile(in_apk, 'r') as zin, zipfile.ZipFile(out_apk, 'w') as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            # If stored uncompressed, align file offset
            if item.compress_type == zipfile.ZIP_STORED:
                # current position in output file
                pos = zout.fp.tell()
                # header overhead for zip is variable; standard local file header size:
                # 30 bytes + len(item.filename) + len(item.extra)
                # To align the data offset:
                header_size = 30 + len(item.filename.encode('utf-8'))
                extra_len = len(item.extra)
                data_offset = pos + header_size + extra_len
                pad = (alignment - (data_offset % alignment)) % alignment
                if pad != 0:
                    item.extra = item.extra + b'\x00' * pad
            zout.writestr(item, data, compress_type=item.compress_type)

if __name__ == '__main__':
    zipalign(sys.argv[1], sys.argv[2])
    print(f"Aligned {sys.argv[1]} -> {sys.argv[2]}")
