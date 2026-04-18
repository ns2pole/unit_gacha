#!/usr/bin/env python3
"""
shortExplanation/shortExplanationEnがSymbolDefの情報と重複している場合、nullにするスクリプト
"""

import re
import os

def extract_text_from_latex(latex_str):
    """LaTeX文字列からテキスト部分を抽出"""
    if not latex_str:
        return ""
    # \text{...}の中身を抽出
    text_matches = re.findall(r'\\text\{([^}]+)\}', latex_str)
    if text_matches:
        return ' '.join(text_matches)
    return latex_str

def check_duplication(explanation, defs, is_en=False):
    """explanationがdefsの情報と重複しているかチェック"""
    if not explanation:
        return False
    
    # LaTeXからテキストを抽出
    explanation_text = extract_text_from_latex(explanation)
    
    # 各defをチェック
    for def_item in defs:
        if is_en:
            # 英語版: nameEnやmeaningEnと比較
            name = def_item.get('nameEn') or def_item.get('nameJa', '')
            meaning = def_item.get('meaningEn') or def_item.get('meaning', '')
        else:
            # 日本語版: nameJaやmeaningと比較
            name = def_item.get('nameJa', '')
            meaning = def_item.get('meaning', '')
        
        # explanationにnameやmeaningが含まれているかチェック
        if name and name in explanation_text:
            return True
        if meaning and meaning in explanation_text:
            return True
        
        # より厳密なチェック: 「Pは電力」のような形式
        # explanationが「記号はname」の形式かチェック
        symbol = def_item.get('symbol', '')
        if symbol:
            # 「symbolはname」のパターン
            pattern1 = rf'{re.escape(symbol)}\s*(は|is)\s*{re.escape(name)}'
            if re.search(pattern1, explanation_text, re.IGNORECASE):
                return True
            # 「symbol is name」のパターン（英語）
            if is_en:
                pattern2 = rf'{re.escape(symbol)}\s*is\s*{re.escape(name)}'
                if re.search(pattern2, explanation_text, re.IGNORECASE):
                    return True
    
    return False

def process_file(filepath):
    """ファイルを処理して重複しているshortExplanationをnullにする"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # UnitProblemのブロックを抽出
    # パターン: UnitProblem(...) の形式
    pattern = r'UnitProblem\s*\([^)]*(?:\([^)]*\)[^)]*)*\)'
    
    def process_problem_block(match):
        block = match.group(0)
        original_block = block
        
        # defsを抽出
        defs_match = re.search(r'defs:\s*\[(.*?)\]', block, re.DOTALL)
        if not defs_match:
            return block
        
        defs_text = defs_match.group(1)
        
        # 各SymbolDefを抽出
        symbol_defs = []
        symbol_def_pattern = r'SymbolDef\s*\(([^)]+)\)'
        for def_match in re.finditer(symbol_def_pattern, defs_text):
            def_params = def_match.group(1)
            # パラメータを抽出
            def_dict = {}
            # symbol: "P"
            symbol_match = re.search(r'symbol:\s*"([^"]+)"', def_params)
            if symbol_match:
                def_dict['symbol'] = symbol_match.group(1)
            # nameJa: "電力"
            name_ja_match = re.search(r'nameJa:\s*"([^"]+)"', def_params)
            if name_ja_match:
                def_dict['nameJa'] = name_ja_match.group(1)
            # nameEn: "power" (オプショナル)
            name_en_match = re.search(r'nameEn:\s*"([^"]+)"', def_params)
            if name_en_match:
                def_dict['nameEn'] = name_en_match.group(1)
            # meaning: "単位時間あたりのエネルギー"
            meaning_match = re.search(r'meaning:\s*"([^"]+)"', def_params)
            if meaning_match:
                def_dict['meaning'] = meaning_match.group(1)
            # meaningEn: "energy per unit time" (オプショナル)
            meaning_en_match = re.search(r'meaningEn:\s*"([^"]+)"', def_params)
            if meaning_en_match:
                def_dict['meaningEn'] = meaning_en_match.group(1)
            
            symbol_defs.append(def_dict)
        
        # shortExplanationをチェック
        short_explanation_match = re.search(r'shortExplanation:\s*(r?"[^"]*"|null)', block)
        if short_explanation_match:
            short_explanation = short_explanation_match.group(1)
            if short_explanation != 'null':
                # 重複チェック
                if check_duplication(short_explanation, symbol_defs, is_en=False):
                    # nullに置換
                    block = block.replace(short_explanation_match.group(0), 'shortExplanation: null')
        
        # shortExplanationEnをチェック
        short_explanation_en_match = re.search(r'shortExplanationEn:\s*(r?"[^"]*"|null)', block)
        if short_explanation_en_match:
            short_explanation_en = short_explanation_en_match.group(1)
            if short_explanation_en != 'null':
                # 重複チェック
                if check_duplication(short_explanation_en, symbol_defs, is_en=True):
                    # nullに置換
                    block = block.replace(short_explanation_en_match.group(0), 'shortExplanationEn: null')
        
        return block
    
    # UnitProblemブロックを処理
    content = re.sub(pattern, process_problem_block, content, flags=re.DOTALL)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
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






