//
//  ShareService.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import SwiftUI
import UIKit

class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    // MARK: - Generate Performance Card
    func generatePerformanceCard(
        match: Match,
        player: Player,
        analysis: PerformanceAnalysis,
        heroName: String
    ) -> UIImage? {
        
        let cardSize = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: cardSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background gradient
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            cgContext.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 0, y: cardSize.height), options: [])
            
            // White content area
            let contentRect = CGRect(x: 20, y: 20, width: cardSize.width - 40, height: cardSize.height - 40)
            cgContext.setFillColor(UIColor.white.cgColor)
            
            let path = UIBezierPath(roundedRect: contentRect, cornerRadius: 16)
            path.fill()
            
            // Draw content
            drawCardContent(
                in: contentRect,
                match: match,
                player: player,
                analysis: analysis,
                heroName: heroName
            )
        }
    }
    
    private func drawCardContent(
        in rect: CGRect,
        match: Match,
        player: Player,
        analysis: PerformanceAnalysis,
        heroName: String
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let title = "Dota 2 Performance Analysis"
        let titleRect = CGRect(x: rect.minX + 20, y: rect.minY + 30, width: rect.width - 40, height: 40)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Hero name
        let heroAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]
        
        let heroRect = CGRect(x: rect.minX + 20, y: titleRect.maxY + 10, width: rect.width - 40, height: 30)
        heroName.draw(in: heroRect, withAttributes: heroAttributes)
        
        // Score circle
        let scoreCenter = CGPoint(x: rect.midX, y: heroRect.maxY + 80)
        drawScoreCircle(at: scoreCenter, score: analysis.overallScore, grade: PerformanceAnalyzer.shared.getPerformanceGrade(score: analysis.overallScore))
        
        // Match result
        let resultY = scoreCenter.y + 70
        let resultText = (player.isRadiant == match.radiantWin) ? "VICTORY" : "DEFEAT"
        let resultColor = (player.isRadiant == match.radiantWin) ? UIColor.systemGreen : UIColor.systemRed
        
        let resultAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: resultColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let resultRect = CGRect(x: rect.minX + 20, y: resultY, width: rect.width - 40, height: 25)
        resultText.draw(in: resultRect, withAttributes: resultAttributes)
        
        // Stats grid
        let statsY = resultY + 40
        drawStatsGrid(in: CGRect(x: rect.minX + 20, y: statsY, width: rect.width - 40, height: 120), player: player, match: match)
        
        // Key recommendation
        let adviceY = statsY + 140
        drawKeyRecommendation(in: CGRect(x: rect.minX + 20, y: adviceY, width: rect.width - 40, height: 60), analysis: analysis)
        
        // Footer
        drawFooter(in: CGRect(x: rect.minX + 20, y: rect.maxY - 50, width: rect.width - 40, height: 30))
    }
    
    private func drawScoreCircle(at center: CGPoint, score: Double, grade: String) {
        let radius: CGFloat = 50
        let lineWidth: CGFloat = 8
        
        // Background circle
        let backgroundPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        UIColor.lightGray.setStroke()
        backgroundPath.lineWidth = lineWidth
        backgroundPath.stroke()
        
        // Progress circle
        let progressPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi/2, endAngle: -.pi/2 + .pi * 2 * score / 100, clockwise: true)
        getScoreColor(score).setStroke()
        progressPath.lineWidth = lineWidth
        progressPath.stroke()
        
        // Score text
        let scoreText = "\(Int(score))"
        let scoreAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        
        let scoreSize = scoreText.size(withAttributes: scoreAttributes)
        let scoreRect = CGRect(
            x: center.x - scoreSize.width / 2,
            y: center.y - scoreSize.height / 2 - 5,
            width: scoreSize.width,
            height: scoreSize.height
        )
        scoreText.draw(in: scoreRect, withAttributes: scoreAttributes)
        
        // Grade text
        let gradeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: getScoreColor(score)
        ]
        
        let gradeSize = grade.size(withAttributes: gradeAttributes)
        let gradeRect = CGRect(
            x: center.x - gradeSize.width / 2,
            y: center.y + 8,
            width: gradeSize.width,
            height: gradeSize.height
        )
        grade.draw(in: gradeRect, withAttributes: gradeAttributes)
    }
    
    private func getScoreColor(_ score: Double) -> UIColor {
        if score >= 80 {
            return .systemGreen
        } else if score >= 60 {
            return .systemYellow
        } else {
            return .systemRed
        }
    }
    
    private func drawStatsGrid(in rect: CGRect, player: Player, match: Match) {
        let statsData = [
            ("KDA", "\(player.kills)/\(player.deaths)/\(player.assists)"),
            ("GPM", "\(player.goldPerMin)"),
            ("XPM", "\(player.xpPerMin)"),
            ("Last Hits", "\(player.lastHits)")
        ]
        
        let itemWidth = rect.width / 2
        let itemHeight = rect.height / 2
        
        for (index, (title, value)) in statsData.enumerated() {
            let col = index % 2
            let row = index / 2
            let itemRect = CGRect(
                x: rect.minX + CGFloat(col) * itemWidth,
                y: rect.minY + CGFloat(row) * itemHeight,
                width: itemWidth - 5,
                height: itemHeight - 5
            )
            
            drawStatItem(in: itemRect, title: title, value: value)
        }
    }
    
    private func drawStatItem(in rect: CGRect, title: String, value: String) {
        // Background
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        UIColor.systemGray6.setFill()
        bgPath.fill()
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.systemGray
        ]
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        
        let titleRect = CGRect(x: rect.minX + 8, y: rect.minY + 8, width: rect.width - 16, height: 15)
        let valueRect = CGRect(x: rect.minX + 8, y: titleRect.maxY + 2, width: rect.width - 16, height: 20)
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        value.draw(in: valueRect, withAttributes: valueAttributes)
    }
    
    private func drawKeyRecommendation(in rect: CGRect, analysis: PerformanceAnalysis) {
        let recommendation = analysis.recommendations.first?.actionable ?? "Keep improving your gameplay!"
        
        let recommendationText = "💡 " + recommendation
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributedText = NSAttributedString(string: recommendationText, attributes: attributes)
        attributedText.draw(in: rect)
    }
    
    private func drawFooter(in rect: CGRect) {
        let footerText = "Dota 2 Post-Game Analyzer • \(formatDate(Date()))"
        
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.lightGray
        ]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        footerText.draw(in: rect, withAttributes: footerAttributes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Share Performance Card
    func sharePerformanceCard(
        match: Match,
        player: Player,
        analysis: PerformanceAnalysis,
        heroName: String,
        from viewController: UIViewController?
    ) {
        // Generate image
        guard let cardImage = generatePerformanceCard(
            match: match,
            player: player,
            analysis: analysis,
            heroName: heroName
        ) else {
            print("Failed to generate performance card")
            return
        }
        
        // Create share text
        let shareText = createShareText(player: player, analysis: analysis, heroName: heroName, match: match)
        
        // Share
        let activityViewController = UIActivityViewController(
            activityItems: [cardImage, shareText],
            applicationActivities: nil
        )
        
        // iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController?.view
            popover.sourceRect = CGRect(x: 100, y: 100, width: 200, height: 200)
        }
        
        viewController?.present(activityViewController, animated: true)
    }
    
    private func createShareText(player: Player, analysis: PerformanceAnalysis, heroName: String, match: Match) -> String {
        let matchResult = (player.isRadiant == match.radiantWin) ? "Victory" : "Defeat"
        let matchDuration = match.duration / 60
        
        return """
        🎮 My Dota 2 Match Analysis:
        
        🦸‍♂️ Hero: \(heroName)
        🏆 Result: \(matchResult) (\(matchDuration) minutes)
        📊 Performance Score: \(Int(analysis.overallScore))/100 (\(PerformanceAnalyzer.shared.getPerformanceGrade(score: analysis.overallScore)))
        ⚔️ KDA: \(player.kills)/\(player.deaths)/\(player.assists) (Ratio: \(String(format: "%.2f", player.kda)))
        💰 GPM: \(player.goldPerMin)
        📈 XPM: \(player.xpPerMin)
        🗡️ Last Hits: \(player.lastHits)
        
        Get AI-powered coaching with Dota 2 Post-Game Analyzer!
        #Dota2 #Gaming #Esports #PerformanceAnalysis
        """
    }
    
    // MARK: - Quick Share Text
    func generateQuickShareText(player: Player, heroName: String, matchResult: Bool) -> String {
        let result = matchResult ? "Victory" : "Defeat"
        let kdaText = "\(player.kills)/\(player.deaths)/\(player.assists)"
        
        if player.kda >= 3.0 {
            return "🎉 Dominated with \(heroName)! \(result) - KDA \(kdaText). AI coaching helped me improve! #Dota2"
        } else if player.kda >= 2.0 {
            return "💪 Solid performance with \(heroName)! \(result) - KDA \(kdaText). Getting better with AI coaching! #Dota2"
        } else {
            return "📈 Learning from \(heroName) match! \(result) - KDA \(kdaText). AI coaching shows areas to improve! #Dota2"
        }
    }
    
    // MARK: - Save to Photos
    func savePerformanceCard(
        match: Match,
        player: Player,
        analysis: PerformanceAnalysis,
        heroName: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard let cardImage = generatePerformanceCard(
            match: match,
            player: player,
            analysis: analysis,
            heroName: heroName
        ) else {
            completion(false, "Failed to generate performance card")
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(cardImage, nil, nil, nil)
        completion(true, "Performance card saved to Photos")
    }
    
    // MARK: - Generate Performance Summary
    func generatePerformanceSummary(analysis: PerformanceAnalysis) -> String {
        let grade = PerformanceAnalyzer.shared.getPerformanceGrade(score: analysis.overallScore)
        let description = PerformanceAnalyzer.shared.getScoreDescription(score: analysis.overallScore)
        
        var summary = "Performance Grade: \(grade) (\(description))\n\n"
        
        if !analysis.strengths.isEmpty {
            summary += "Strengths:\n"
            for strength in analysis.strengths {
                summary += "✅ \(strength)\n"
            }
            summary += "\n"
        }
        
        if !analysis.weaknesses.isEmpty {
            summary += "Areas for Improvement:\n"
            for weakness in analysis.weaknesses {
                summary += "🔄 \(weakness)\n"
            }
            summary += "\n"
        }
        
        if !analysis.recommendations.isEmpty {
            summary += "Top Recommendations:\n"
            for (index, recommendation) in analysis.recommendations.prefix(3).enumerated() {
                summary += "\(index + 1). \(recommendation.actionable)\n"
            }
        }
        
        return summary
    }
}