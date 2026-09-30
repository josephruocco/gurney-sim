#!/usr/bin/env python3
"""Serve the model preview and save its rendered PNGs. Open /scripts/render-art.html."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import os
import sys
ROOT=Path(__file__).resolve().parents[1]
os.chdir(ROOT)
OUTPUTS={
 '/render/title':ROOT/'assets/gurney-journey-art.png',
 '/render/icon':ROOT/'assets/gurney-journey-icon.png',
}
OUTPUTS.update({'/render/'+name:ROOT/('assets/'+name+'.png') for name in ['patient-florida','patient-geezer','patient-alien','patient-dummy']})
class Handler(SimpleHTTPRequestHandler):
 def do_POST(self):
  if self.path not in OUTPUTS:
   self.send_error(404);return
  length=int(self.headers.get('Content-Length','0'))
  if not 8<length<10_000_000:
   self.send_error(400);return
  data=self.rfile.read(length)
  if not data.startswith(b'\x89PNG\r\n\x1a\n'):
   self.send_error(400);return
  OUTPUTS[self.path].write_bytes(data)
  self.send_response(200);self.end_headers();self.wfile.write(b'Saved')
ThreadingHTTPServer(('127.0.0.1',int(sys.argv[1]) if len(sys.argv)>1 else 8765),Handler).serve_forever()
