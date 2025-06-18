#!/usr/bin/env python3
import os
import subprocess
import time
import signal
import threading
import sys

server_process = None

def signal_handler(sig, frame):
    print('Shutting down server...')
    if server_process:
        server_process.terminate()
    exit(0)

def output_reader(pipe, prefix):
    for line in iter(pipe.readline, b''):
        print(f'{prefix}: {line.decode().strip()}')

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

print('Starting BitNet server...')

# Start the server
server_process = subprocess.Popen([
    '/app/bin/llama-server',
    '-m', '/app/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf',
    '-c', '2048',
    '-t', '2',
    '--host', '0.0.0.0',
    '--port', '8080',
    '-ngl', '0'
], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

# Start threads to read output
stdout_thread = threading.Thread(target=output_reader, args=(server_process.stdout, 'STDOUT'))
stderr_thread = threading.Thread(target=output_reader, args=(server_process.stderr, 'STDERR'))
stdout_thread.daemon = True
stderr_thread.daemon = True
stdout_thread.start()
stderr_thread.start()

print('BitNet server started')

try:
    # Wait for the process to finish
    server_process.wait()
except KeyboardInterrupt:
    print('Shutting down server...')
    server_process.terminate()
