# 🧠 EA-AI: Full Autonomous AI Trading Executor for MetaTrader 5

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MQL5](https://img.shields.io/badge/MQL5-Compatible-blue.svg)](https://www.mql5.com/)

## 📌 Overview

**EA-AI** is a fully autonomous Expert Advisor (EA) for MetaTrader 5 designed to serve as a low-level trading API for external Artificial Intelligence systems. This EA acts as the "hands" of an autonomous AI, executing all trading commands without built-in limitations, risk management, or decision-making logic.

The AI has **complete freedom** to make all trading decisions independently. The human does not make trading decisions, write commands, or intervene in the process.

## 🎯 Key Features

- **Full AI Autonomy** - No built-in limitations or filters
- **Command-Based Control** - Simple text file interface for AI commands
- **Real-Time Market Snapshots** - JSON-formatted market and account data
- **Universal Trading Operations** - All order types and position management
- **Symbol Switching** - Dynamic symbol selection from MarketWatch
- **Zero Risk Management** - Pure execution layer (risk handled by AI)
- **Multi-Platform Ready** - Works with Python, Node.js, or any AI framework

## 🏗️ Architecture

The EA communicates with external AI through two files in the MT5 terminal's common data folder:

### 1. **AI_commands.txt** (AI → EA)
- Source of commands from the external AI
- EA reads **only the last line**
- Commands include ID + action + parameters
- If ID doesn't change, command is skipped

### 2. **AI_snapshot.json** (EA → AI)
- EA creates this file every N seconds (default: 3)
- AI reads it to analyze market and make decisions
- Contains account info, positions, orders, and market data

## 🚀 Quick Start

See [QUICK_START.md](QUICK_START.md) for detailed installation and setup instructions.

### Basic Setup
1. Copy `Experts/AI_Executor.mq5` to your MT5 `Experts` folder
2. Compile in MetaEditor
3. Attach to any chart
4. Files will be created in: `%APPDATA%\MetaQuotes\Terminal\Common\Files\`

### Example AI Integration
See [example_ai_integration.py](example_ai_integration.py) for a working Python example.

## 📋 Supported Commands

### Symbol Management
- `SET_SYMBOL <symbol>` - Change active trading symbol

### Market Orders
- `BUY <volume>` - Open buy position
- `SELL <volume>` - Open sell position

### Pending Orders
- `BUY_LIMIT <volume> <price>`
- `SELL_LIMIT <volume> <price>`
- `BUY_STOP <volume> <price>`
- `SELL_STOP <volume> <price>`

### Position Management
- `CLOSE_TICKET <ticket>` - Close specific position
- `CLOSE_SYMBOL <symbol>` - Close all positions for symbol
- `CLOSE_ALL` - Close all positions

### Position Modification
- `SET_SL <ticket> <price>` - Set stop loss
- `SET_TP <ticket> <price>` - Set take profit
- `MODIFY <ticket> <sl> <tp>` - Modify both SL and TP

### Order Management
- `CANCEL_PENDING <ticket>` - Cancel pending order
- `CANCEL_ALL_PENDING` - Cancel all pending orders

## 📚 Documentation

- [QUICK_START.md](QUICK_START.md) - Installation and usage guide
- [Experts/README.md](Experts/README.md) - Detailed EA documentation
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Technical architecture
- [ACCEPTANCE_CRITERIA.md](ACCEPTANCE_CRITERIA.md) - Feature checklist

## ⚠️ Important Limitations

The EA intentionally does **NOT** include:
- Volume/lot size validation
- Risk checks
- Time/session filters
- Trade count limits
- Symbol restrictions
- Volatility checks
- Margin verification

**Only broker-imposed limits apply** (minimum lot, stop level, stop out).

## 🔒 Safety Notice

**⚠️ USE ONLY ON DEMO ACCOUNTS ⚠️**

This EA is designed for fully autonomous AI trading research. It has no safety mechanisms or risk management. **Never use on a live account** without proper oversight and risk controls.

## 🛠️ Technology Stack

- **MQL5** - MetaTrader 5 native language
- **JSON** - Data interchange format
- **Text Files** - Command interface
- **Python** - Example AI integration (any language supported)

## 📊 Use Cases

- AI Trading Research
- Reinforcement Learning for Trading
- Automated Strategy Development
- Algorithm Testing
- Market Making Bots
- High-Frequency Trading Research

## 🔮 Future Extensions

Planned features for future releases:
- Trailing Stop functionality
- Grid Builder
- Hedge Mode
- Batch command execution
- Trading history export
- Multi-timeframe analysis
- Auto-add symbols from MarketWatch

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check the documentation in the `docs/` folder
- Review example implementations

## ⚡ Performance

- Snapshot updates: Every 3 seconds (configurable)
- Command processing: Real-time via timer
- No OnTick overhead: All logic in OnTimer
- Minimal latency: Direct MT5 API calls

## 🎓 Learn More

- [MQL5 Documentation](https://www.mql5.com/en/docs)
- [MetaTrader 5 Download](https://www.metatrader5.com/)
- [Python Integration Guide](example_ai_integration.py)

---

**Built for the future of autonomous AI trading** 🚀
