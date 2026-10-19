#!/usr/bin/env python3
"""List Kubernetes pod-spec container images from rendered multi-document YAML."""
import sys
import yaml
images = set()

def walk(item):
    if isinstance(item, dict):
        for k, v in item.items():
            if k == 'image' and isinstance(v, str) and '/' in v:
                images.add(v)
            walk(v)
    elif isinstance(item, list):
        for v in item:
            walk(v)

for filename in sys.argv[1:]:
    with open(filename, encoding='utf-8') as f:
        for doc in yaml.safe_load_all(f):
            walk(doc)
# The built-in Agent custom resources may cause the controller to create
# runtime pods dynamically, so include the Go agent runtime explicitly.
images.add('ghcr.io/kagent-dev/kagent/golang-adk:0.10.3')
for image in sorted(images):
    print(image)
