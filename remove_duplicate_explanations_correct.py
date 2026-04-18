#!/usr/bin/env python3
"""
shortExplanation/shortExplanationEnがSymbolDefの情報（nameJa/nameEn/meaning/meaningEn）と重複している場合、nullにするスクリプト
"""

import re
import os

def extract_text_from_latex(latex_str):
    """LaTeX文字列からテキスト部分を抽出"""
    if not latex_str:
        return ""
    # r"..." の形式から文字列を抽出
    match = re.search(r'r?"([^"]+)"', latex_str)
    if match:
        text = match.group(1)
        # \text{...}の中身を抽出
        text_matches = re.findall(r'\\text\{([^}]+)\}', text)
        if text_matches:
            return ' '.join(text_matches)
        return text
    return latex_str

def check_if_explanation_duplicates_defs(explanation, defs_info, is_en=False):
    """explanationがdefsの情報（nameJa/nameEn/meaning/meaningEn）と重複しているかチェック"""
    if not explanation or explanation == 'null':
        return False
    
    # LaTeXからテキストを抽出
    explanation_text = extract_text_from_latex(explanation)
    explanation_text_lower = explanation_text.lower()
    
    # 各defの情報をチェック
    for def_info in defs_info:
        if is_en:
            # 英語版: nameEnやmeaningEnと比較
            name = (def_info.get('nameEn') or def_info.get('nameJa', '')).lower()
            meaning = (def_info.get('meaningEn') or def_info.get('meaning', '')).lower()
        else:
            # 日本語版: nameJaやmeaningと比較
            name = def_info.get('nameJa', '').lower()
            meaning = def_info.get('meaning', '').lower()
        
        symbol = def_info.get('symbol', '').lower()
        
        # パターン1: 「symbolはname」または「symbol is name」
        if symbol and name:
            pattern1 = rf'{re.escape(symbol)}\s*(は|is)\s*{re.escape(name)}'
            if re.search(pattern1, explanation_text_lower):
                return True
        
        # パターン2: explanationにnameが含まれている（単純な重複）
        # ただし、nameが短すぎる場合は除外（例: "m"）
        if name and len(name) > 1 and name in explanation_text_lower:
            # 「symbolはname」の形式で含まれている場合のみ
            if symbol:
                pattern2 = rf'{re.escape(symbol)}\s*(は|is)\s*{re.escape(name)}'
                if re.search(pattern2, explanation_text_lower):
                    return True
        
        # パターン3: explanationがmeaningと完全に一致
        if meaning and meaning == explanation_text_lower:
            return True
    
    return False

def process_file(filepath):
    """ファイルを処理して重複しているshortExplanationをnullにする"""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    i = 0
    changed = False
    
    while i < len(lines):
        line = lines[i]
        
        # UnitProblemの開始を検出
        if 'UnitProblem(' in line:
            # このUnitProblemブロック全体を収集
            problem_lines = [line]
            brace_count = line.count('(') - line.count(')')
            i += 1
            
            # ブロックの終わりまで読み込む
            while i < len(lines) and brace_count > 0:
                problem_lines.append(lines[i])
                brace_count += lines[i].count('(') - lines[i].count(')')
                i += 1
            
            # defsを抽出
            problem_text = ''.join(problem_lines)
            defs_info = []
            
            # defs: [...] の部分を抽出
            defs_match = re.search(r'defs:\s*\[(.*?)\]', problem_text, re.DOTALL)
            if defs_match:
                defs_text = defs_match.group(1)
                # 各SymbolDefを抽出
                for def_match in re.finditer(r'SymbolDef\s*\(([^)]+)\)', defs_text):
                    def_params = def_match.group(1)
                    def_dict = {}
                    
                    # パラメータを抽出
                    symbol_match = re.search(r'symbol:\s*"([^"]+)"', def_params)
                    if symbol_match:
                        def_dict['symbol'] = symbol_match.group(1)
                    
                    name_ja_match = re.search(r'nameJa:\s*"([^"]+)"', def_params)
                    if name_ja_match:
                        def_dict['nameJa'] = name_ja_match.group(1)
                    
                    name_en_match = re.search(r'nameEn:\s*"([^"]+)"', def_params)
                    if name_en_match:
                        def_dict['nameEn'] = name_en_match.group(1)
                    
                    meaning_match = re.search(r'meaning:\s*"([^"]+)"', def_params)
                    if meaning_match:
                        def_dict['meaning'] = meaning_match.group(1)
                    
                    meaning_en_match = re.search(r'meaningEn:\s*"([^"]+)"', def_params)
                    if meaning_en_match:
                        def_dict['meaningEn'] = meaning_en_match.group(1)
                    
                    defs_info.append(def_dict)
            
            # shortExplanationとshortExplanationEnをチェック
            modified_problem_lines = []
            for pline in problem_lines:
                # shortExplanationをチェック
                if 'shortExplanation:' in pline and 'null' not in pline:
                    expl_match = re.search(r'shortExplanation:\s*(r?"[^"]*")', pline)
                    if expl_match:
                        explanation = expl_match.group(1)
                        if check_if_explanation_duplicates_defs(explanation, defs_info, is_en=False):
                            pline = re.sub(r'shortExplanation:\s*r?"[^"]*"', 'shortExplanation: null', pline)
                            changed = True
                
                # shortExplanationEnをチェック
                if 'shortExplanationEn:' in pline and 'null' not in pline:
                    expl_en_match = re.search(r'shortExplanationEn:\s*(r?"[^"]*")', pline)
                    if expl_en_match:
                        explanation_en = expl_en_match.group(1)
                        if check_if_explanation_duplicates_defs(explanation_en, defs_info, is_en=True):
                            pline = re.sub(r'shortExplanationEn:\s*r?"[^"]*"', 'shortExplanationEn: null', pline)
                            changed = True
                
                modified_problem_lines.append(pline)
            
            new_lines.extend(modified_problem_lines)
        else:
            new_lines.append(line)
            i += 1
    
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"Updated: {filepath}")
        return True
    else:
        print(f"No changes: {filepath}")
        return False

if __name__ == '__main__':
    base_dir = '/Users/nakamurashunsuke/Documents/tmp/unitGacha/lib/problems/unit'
    files = [
        'electromagnetism_problems.dart',
        'mechanics_problems.dart',
        'thermodynamics_problems.dart',
        'waves_problems.dart',
    ]
    
    for filename in files:
        filepath = os.path.join(base_dir, filename)
        if os.path.exists(filepath):
            process_file(filepath)
        else:
            print(f"File not found: {filepath}")






