#!/usr/bin/env python3
"""Simple test server - just returns !"""

from flask import Flask

app = Flask(__name__)

@app.route('/')
@app.route('/<path:path>')
def hello(path=None):
    return '!'

if __name__ == '__main__':
    print("Starting test server on port 80...")
    app.run(host='0.0.0.0', port=80)
