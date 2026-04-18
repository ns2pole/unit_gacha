#!/bin/bash

# Git操作をまとめて実行するスクリプト
# 使用方法: ./git.sh "コミットメッセージ"

# 引数チェック
if [ $# -eq 0 ]; then
    echo "使用方法: $0 \"コミットメッセージ\""
    echo "例: $0 \"問題追加\""
    exit 1
fi

COMMIT_MESSAGE="$1"

echo "Git操作を開始します..."
echo "コミットメッセージ: $COMMIT_MESSAGE"
echo ""

# 現在の状態を表示
echo "=== 現在の状態 ==="
git status --short
echo ""

# すべての変更をステージング
echo "=== 変更をステージング ==="
git add --all
if [ $? -eq 0 ]; then
    echo "✓ ステージング完了"
else
    echo "✗ ステージングに失敗しました"
    exit 1
fi
echo ""

# コミット
echo "=== コミット ==="
git commit -m "$COMMIT_MESSAGE"
if [ $? -eq 0 ]; then
    echo "✓ コミット完了"
else
    echo "✗ コミットに失敗しました"
    exit 1
fi
echo ""

# プッシュ
echo "=== プッシュ ==="
git push
if [ $? -eq 0 ]; then
    echo "✓ プッシュ完了"
    echo ""
    echo "🎉 すべての操作が正常に完了しました！"
else
    echo "✗ プッシュに失敗しました"
    exit 1
fi











