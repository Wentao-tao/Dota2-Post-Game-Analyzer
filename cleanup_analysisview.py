#!/usr/bin/env python3
"""
清理 AnalysisView.swift 中的重复 getHeroName 方法
"""

import re

def cleanup_analysis_view():
    file_path = '/Users/wentao/Projects/Apple academy/Challenge 4/DotaA/DotaA/Views/AnalysisView.swift'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 定义要删除的方法模式
    patterns_to_remove = [
        # getHeroName 方法
        r'private func getHeroName\(heroId: Int\) -> String \{[^}]*?switch heroId \{.*?default: return.*?\n    \}',
        # getHeroNamePart2 方法  
        r'private func getHeroNamePart2\(heroId: Int\) -> String \{[^}]*?switch heroId \{.*?default: return.*?\n    \}',
        # getHeroNamePart3 方法
        r'private func getHeroNamePart3\(heroId: Int\) -> String \{[^}]*?switch heroId \{.*?default: return.*?\n    \}',
    ]
    
    # 删除重复的方法
    for pattern in patterns_to_remove:
        # 使用 DOTALL 标志让 . 匹配换行符
        content = re.sub(pattern, '    // getHeroName 方法已移动到 HeroService.shared.getHeroName()', content, flags=re.DOTALL)
    
    # 清理多余的空行
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    
    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ AnalysisView.swift 清理完成！")
    print("🔧 已删除重复的 getHeroName 相关方法")
    print("📦 已替换为 HeroService.shared.getHeroName() 的引用")

if __name__ == '__main__':
    cleanup_analysis_view()