# Dota 2 Post-Game Analyzer

An AI-powered Dota 2 performance analysis tool that provides personalized coaching advice after each match. Instead of just showing stats, this app acts like a virtual coach answering: "What could I do better in my next match?"

## Features

### 🎯 Core Functionality
- **Match Data Collection**: Fetches detailed match data from OpenDota API including KDA, net worth graphs, lane performance, item timings, and map deaths
- **Performance Analysis**: Compares player data to high-tier benchmarks and identifies weak points
- **AI Coaching**: Uses OpenAI GPT-4 to generate personalized recommendations
- **Shareable Cards**: Creates beautiful performance cards for social media sharing

### 📊 Analysis Categories
1. **Farming Efficiency**: Last-hit accuracy, CS per minute, deny efficiency
2. **Combat Performance**: KDA ratio, kill participation, survival rate
3. **Economic Development**: GPM, XPM, gold efficiency
4. **Itemization**: Core items, situational builds, timing optimization
5. **Map Awareness**: Death frequency, positioning, team fight participation

### 🤖 AI Coaching Features
- **Specific Recommendations**: "Buy BKB before 25 mins to survive team fights"
- **Measurable Goals**: "Focus on CS efficiency; aim for 50 CS at 10 minutes"
- **Actionable Advice**: "Improve map awareness to reduce split-push deaths"
- **Performance Trends**: Track improvement over time
- **Hero-Specific Tips**: Tailored advice based on hero selection

## Architecture

### Data Models (`Models/DotaModels.swift`)
- **Match**: Complete match data with players and statistics
- **Player**: Individual player performance metrics
- **PerformanceAnalysis**: Analyzed results with scores and recommendations
- **AICoachingResponse**: AI-generated advice and tips

### Services
- **OpenDotaService**: API integration for match and player data
- **OpenAIService**: AI coaching advice generation
- **PerformanceAnalyzer**: Core analysis logic and scoring algorithms
- **ShareService**: Performance card generation and sharing

### User Interface
- **PlayerSearchView**: Search and select Dota 2 players
- **PlayerDetailView**: Player profile with recent matches
- **MatchAnalysisView**: Detailed match breakdown with AI coaching
- **AnalysisView**: Performance trends and hero statistics
- **ProfileView**: User profile and settings

## Setup Instructions

### Prerequisites
1. Xcode 15.0 or later
2. iOS 17.0 or later
3. OpenAI API key (for AI coaching features)

### Installation
1. Clone the repository
2. Open `DotaA.xcodeproj` in Xcode
3. Configure your OpenAI API key:
   - Open `Services/OpenAIService.swift`
   - Replace `"YOUR_OPENAI_API_KEY"` with your actual API key
   - Or configure it through the app's settings after installation

### Configuration
1. **OpenAI API Key**: 
   - Get your API key from [OpenAI Platform](https://platform.openai.com/)
   - Add it in the app's Profile > Settings > OpenAI API Key
   
2. **Rate Limiting**: 
   - OpenDota API has rate limits (consider implementing caching)
   - OpenAI API usage will incur costs based on your plan

## Usage

### 1. Search for Players
- Enter player name or Steam ID in the search tab
- Select your player from the results
- View player profile and recent matches

### 2. Analyze Matches
- Tap any recent match to start analysis
- Wait for AI processing (usually 10-30 seconds)
- Review performance scores and recommendations

### 3. Track Progress
- Use the Analysis tab to view performance trends
- Monitor hero-specific statistics
- Track goal achievement progress

### 4. Share Results
- Generate performance cards from match analysis
- Share on social media or save to photos
- Include AI coaching tips in shares

## API Integration

### OpenDota API
- **Base URL**: `https://api.opendota.com/api`
- **Endpoints Used**:
  - `/search` - Player search
  - `/players/{id}/recentMatches` - Recent matches
  - `/matches/{id}` - Detailed match data
  - `/heroes` - Hero information
  - `/constants/items` - Item data

### OpenAI API
- **Model**: GPT-4o
- **Usage**: Performance analysis and coaching advice
- **Estimated Cost**: ~$0.01-0.03 per analysis

## Performance Scoring Algorithm

### Overall Score Calculation
```
Overall Score = (
  Farming Efficiency × 0.25 +
  Combat Performance × 0.25 +
  Economy Score × 0.20 +
  Itemization Score × 0.15 +
  Map Awareness × 0.15
)
```

### Grading System
- **S+ (90-100)**: Exceptional performance
- **S (85-89)**: Outstanding
- **A+ (80-84)**: Excellent
- **A (75-79)**: Very good
- **B+ (70-74)**: Good
- **B (65-69)**: Above average
- **C+ (60-64)**: Average
- **C (55-59)**: Below average
- **D+ (50-54)**: Needs improvement
- **D (0-49)**: Requires significant work

## Customization

### Adding New Metrics
1. Extend the `KeyMetrics` struct in `DotaModels.swift`
2. Update scoring algorithm in `PerformanceAnalyzer.swift`
3. Modify UI components to display new metrics

### Custom AI Prompts
1. Edit prompt templates in `OpenAIService.swift`
2. Adjust coaching categories in `RecommendationCategory` enum
3. Customize advice templates for different skill levels

### UI Themes
1. Modify color schemes in individual views
2. Update score color mappings in `PerformanceAnalyzer.swift`
3. Customize performance card designs in `ShareService.swift`

## Data Privacy

- **Local Processing**: All analysis happens on-device
- **API Calls**: Only necessary data sent to OpenDota and OpenAI
- **No User Tracking**: App doesn't collect personal information
- **Optional Sharing**: Users control what data is shared

## Future Enhancements

### Planned Features
- [ ] Team analysis for 5-stack matches
- [ ] Machine learning model for prediction
- [ ] Integration with Steam Workshop guides
- [ ] Real-time coaching during matches
- [ ] Tournament bracket analysis
- [ ] Voice coaching summaries
- [ ] Widget for iOS home screen

### Technical Improvements
- [ ] Core Data for local storage
- [ ] Background processing for batch analysis
- [ ] CloudKit sync across devices
- [ ] Watch app for quick stats
- [ ] Shortcuts app integration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests for new functionality
5. Submit a pull request

### Code Style
- Follow Swift conventions
- Use meaningful variable names
- Add comments for complex algorithms
- Keep functions focused and small

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Acknowledgments

- **OpenDota**: For providing comprehensive Dota 2 match data
- **OpenAI**: For powering the AI coaching features
- **Valve Corporation**: For creating Dota 2
- **Swift Community**: For excellent development resources

## Support

For issues, questions, or feature requests:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include device info and iOS version
4. Provide steps to reproduce any bugs

---

**Disclaimer**: This app is not affiliated with Valve Corporation or Dota 2. It's a third-party analysis tool created for educational and improvement purposes.