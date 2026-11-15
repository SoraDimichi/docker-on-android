#!/usr/bin/env python3
"""Check that the NetHunter zip gets the same kernel and modules as boot-docker.img.

Usage: check-kernel.py <boot.img> <Image.gz-dtb> <signing_key.x509> <modules/KERNEL_RELEASE>

Checks:
- the kernel in the boot image (header v0-v2) is byte-identical to Image.gz-dtb
- the kernel release in Image.gz-dtb is the name of the modules folder
- the module signing certificate is built into the kernel
- every module is signed with that certificate and has the same vermagic
"""
import re
import struct
import subprocess
import sys
import zlib
from pathlib import Path

SIG_MAGIC = b"~Module signature appended~\n"
SIG_INFO_SIZE = 12  # struct module_signature


def fail(message):
    sys.exit(f"ERROR: {message}")


def boot_kernel(path):
    data = Path(path).read_bytes()
    if data[:8] != b"ANDROID!":
        fail(f"{path} is not an Android boot image")
    kernel_size, = struct.unpack_from("<I", data, 8)
    page_size, header_version = struct.unpack_from("<II", data, 36)
    if header_version > 2:
        fail(f"{path}: boot image header v{header_version} is not supported")
    return data[page_size:page_size + kernel_size]


def cert_serial(path):
    result = subprocess.run(
        ["openssl", "x509", "-inform", "DER", "-in", path, "-noout", "-serial"],
        check=True, capture_output=True, text=True,
    )
    serial = result.stdout.strip().split("=", 1)[1]
    return bytes.fromhex(serial.zfill(len(serial) + len(serial) % 2))


def kernel_release(kernel):
    match = re.search(rb"Linux version (\d\S*) \(", kernel)
    if not match:
        fail("no 'Linux version' string in the kernel image")
    return match.group(1).decode()


def check_module(ko, serial, release):
    data = ko.read_bytes()
    if not data.endswith(SIG_MAGIC):
        fail(f"{ko.name} is not signed")
    end = len(data) - len(SIG_MAGIC)
    sig_len, = struct.unpack(">I", data[end - 4:end])
    signature = data[end - SIG_INFO_SIZE - sig_len:end - SIG_INFO_SIZE]
    if serial not in signature:
        fail(f"{ko.name} is not signed with the key of this kernel")
    vermagic = re.search(rb"vermagic=(\S+)", data)
    if not vermagic or vermagic.group(1).decode() != release:
        fail(f"{ko.name}: vermagic is not {release}")


def main():
    if len(sys.argv) != 5:
        fail(__doc__)
    boot_img, image_path, cert_path, modules_dir = sys.argv[1:]

    image = Path(image_path).read_bytes()
    if boot_kernel(boot_img) != image:
        fail(f"the kernel in {boot_img} is not {image_path}. Use the files of one build.")

    kernel = zlib.decompressobj(16 + zlib.MAX_WBITS).decompress(image)
    release = kernel_release(kernel)
    modules = Path(modules_dir)
    if modules.name != release:
        fail(f"kernel release {release} is not the modules folder name {modules.name}")

    if Path(cert_path).read_bytes() not in kernel:
        fail(f"{cert_path} is not built into the kernel")
    serial = cert_serial(cert_path)

    kos = sorted(modules.rglob("*.ko"))
    if not kos:
        fail(f"no .ko files in {modules}")
    for ko in kos:
        check_module(ko, serial, release)

    print(f"OK: {boot_img} has kernel {release} == {image_path}")
    print(f"OK: {len(kos)} modules have vermagic {release} and the signing key of this kernel")


if __name__ == "__main__":
    main()
