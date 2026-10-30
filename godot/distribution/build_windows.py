"""Build a Windows x64 test ZIP using the matching official Godot runtime.
Usage: python3 build_windows.py /path/to/Godot_v4.7.2-stable_win64.exe.zip
"""
import hashlib
from pathlib import Path
import shutil
import sys
import tempfile
import zipfile

RUNTIME_SHA256 = '731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953'
runtime = Path(sys.argv[1])
if hashlib.sha256(runtime.read_bytes()).hexdigest() != RUNTIME_SHA256:
    raise SystemExit('Runtime checksum differs from official GitHub release digest')
distribution = Path(__file__).resolve().parent
project = distribution.parent
with tempfile.TemporaryDirectory(prefix='gurney-windows-') as work:
    package = Path(work) / 'Gurney-Simulator-Windows'
    package.mkdir()
    with zipfile.ZipFile(runtime) as archive:
        for name in ('Godot_v4.7.2-stable_win64.exe', 'Godot_v4.7.2-stable_win64_console.exe'):
            (package / name).write_bytes(archive.read(name))
    shutil.copytree(project, package / 'game', ignore=shutil.ignore_patterns('.godot', 'tests', 'distribution', '.DS_Store'))
    shutil.copy2(distribution / 'README-WINDOWS.txt', package / 'README.txt')
    launcher = '''@echo off
cd /d "%~dp0"
echo Preparing Gurney Simulator...
"%~dp0Godot_v4.7.2-stable_win64_console.exe" --headless --editor --path "%~dp0game" --import --quit
if errorlevel 1 (
  echo Game preparation failed. Please share the error above.
  pause
  exit /b 1
)
start "" "%~dp0Godot_v4.7.2-stable_win64.exe" --path "%~dp0game"
'''
    (package / 'Start.bat').write_bytes(launcher.replace('\n', '\r\n').encode('ascii'))
    output = distribution / 'Gurney-Simulator-Windows-Test.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(package.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(work))
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert b'wss://gurney-relay.onrender.com' in archive.read('Gurney-Simulator-Windows/game/scripts/ui/hud.gd')
    print(output)
    print(f'{output.stat().st_size / 1024**2:.1f} MiB; archive integrity verified')
