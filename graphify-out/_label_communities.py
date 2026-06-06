import sys, json
from graphify.build import build_from_json
from graphify.cluster import score_all
from graphify.analyze import god_nodes, surprising_connections, suggest_questions
from graphify.report import generate
from pathlib import Path

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    extraction = json.loads(Path('graphify-out/.graphify_extract.json').read_text(encoding='utf-8'))
    detection  = json.loads(Path('graphify-out/.graphify_detect.json').read_text(encoding='utf-8'))
    analysis   = json.loads(Path('graphify-out/.graphify_analysis.json').read_text(encoding='utf-8'))

    G = build_from_json(extraction)
    communities = {int(k): v for k, v in analysis['communities'].items()}
    cohesion = {int(k): v for k, v in analysis['cohesion'].items()}
    tokens = {'input': extraction.get('input_tokens', 0), 'output': extraction.get('output_tokens', 0)}

    # Hand-labeled top 30; smaller communities get generic names
    named = {
        0: 'Color Design Tokens',
        1: 'Care Feature UI',
        2: 'App Theme & Spacing',
        3: 'Pet & Discovery Controllers',
        4: 'Social Feed UI',
        5: 'Care Gamification',
        6: 'App Navigation (Router)',
        7: 'Location & Matching',
        8: 'Pet Profile Editing',
        9: 'Medical Vault',
        10: 'Vendor Shop Management',
        11: 'Matching Data Layer',
        12: 'Social Post Creation',
        13: 'Chat System',
        14: 'Marketplace Products',
        15: 'Social Posts & Reactions',
        16: 'Web / JS Interop',
        17: 'Social Profiles & Follow',
        18: 'Vendor Dashboard',
        19: 'Order Management',
        20: 'Marketplace Browse',
        21: 'Auth & Discovery State',
        22: 'Nutrition & Weight Tracking',
        23: 'Error Handling',
        24: 'Onboarding Flow',
        25: 'Core Button Widget',
        26: 'Care Streaks & XP',
        27: 'Buyer Orders',
        28: 'Care Data Layer',
        29: 'Vendor KYC',
    }
    labels = {}
    for cid in communities:
        labels[cid] = named.get(cid, 'Module ' + str(cid))

    questions = suggest_questions(G, communities, labels)
    report = generate(G, communities, cohesion, labels, analysis['gods'], analysis['surprises'],
                      detection, tokens, '.', suggested_questions=questions)
    Path('graphify-out/GRAPH_REPORT.md').write_text(report, encoding='utf-8')
    Path('graphify-out/.graphify_labels.json').write_text(
        json.dumps({str(k): v for k, v in labels.items()}, ensure_ascii=False), encoding='utf-8'
    )
    print('Report updated with ' + str(len(named)) + ' hand-labeled communities')

if __name__ == '__main__':
    main()
