import sys, json
from pathlib import Path

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ast = json.loads(Path('graphify-out/.graphify_ast.json').read_text(encoding='utf-8'))

    merged = {
        'nodes': ast['nodes'],
        'edges': ast['edges'],
        'hyperedges': [],
        'input_tokens': 0,
        'output_tokens': 0,
    }
    Path('graphify-out/.graphify_extract.json').write_text(
        json.dumps(merged, indent=2, ensure_ascii=False), encoding='utf-8'
    )
    print('Merged: ' + str(len(merged['nodes'])) + ' nodes, ' + str(len(merged['edges'])) + ' edges (AST only)')

if __name__ == '__main__':
    main()
