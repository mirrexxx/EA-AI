# EA-AI: Universal Executor for AI Trading

A system for automated trading on MetaTrader 5 where **all decisions are made by Artificial Intelligence**.

[Russian documentation](README_RU.md) | [English documentation](README.md)

## Concept

The EA (Expert Advisor) is a **dumb executor** with no built-in logic. All the "brain" resides externally in the AI agent.

```
AI Agent (Python + LLM) ←→ EA (MQL5) ←→ MT5 Terminal
```

### How it works:

1. **EA** every N seconds:
   - Reads commands from `AI_commands.txt`
   - Executes trading operations
   - Writes account state to `AI_snapshot.json`

2. **AI Agent** (Python script):
   - Reads `AI_snapshot.json`
   - Analyzes market through LLM (ChatGPT, Claude, etc.)
   - Generates trading commands
   - Writes commands to `AI_commands.txt`

3. **EA reads commands → executes → cycle repeats**

## EA Capabilities

The EA is a pure API to MetaTrader 5. No built-in risk management, filters, or logic.

### Commands (primitives):

#### 1. Trading
- `BUY <volume>` - Open a buy position
- `SELL <volume>` - Open a sell position
- `BUY_LIMIT <volume> <price>` - Place a Buy Limit pending order
- `SELL_LIMIT <volume> <price>` - Place a Sell Limit pending order
- `BUY_STOP <volume> <price>` - Place a Buy Stop pending order
- `SELL_STOP <volume> <price>` - Place a Sell Stop pending order

#### 2. Position Management
- `MODIFY_SLTP <ticket> <sl> <tp>` - Modify Stop Loss and Take Profit
- `CLOSE_TICKET <ticket>` - Close position by ticket
- `CLOSE_SYMBOL <symbol>` - Close all positions for a symbol
- `CLOSE_ALL` - Close all positions

#### 3. Settings
- `SET_SYMBOL <symbol>` - Switch active symbol

### What the EA does NOT have:

- ❌ Built-in risk management
- ❌ Position count limits
- ❌ Lot size limits (except broker constraints)
- ❌ Spread/time/session filters
- ❌ Any trading logic

**Only constraints** are those imposed by the broker (minimum lot, margin call, stop out).

## Installation

### 1. Install EA in MetaTrader 5

1. Copy `AI_Executor.mq5` to folder:
   ```
   C:\Users\<USERNAME>\AppData\Roaming\MetaQuotes\Terminal\<ID>\MQL5\Experts\
   ```

2. Open MetaEditor (F4 in MT5)

3. Compile `AI_Executor.mq5`

4. Drag EA onto a chart in MT5

5. In EA settings:
   - `TimerIntervalSeconds` - command check interval (default 5 sec)
   - `CommandFile` - command file name (default AI_commands.txt)
   - `SnapshotFile` - market snapshot file name (default AI_snapshot.json)

6. Enable automated trading (AutoTrading button in MT5)

### 2. Setup AI Agent

1. Install Python 3.7+

2. Run the agent:
   ```bash
   python ai_agent.py
   ```

3. Agent will automatically find MT5 files or use current directory

### 3. LLM Integration

In `ai_agent.py`, find the `make_ai_decision()` function and add your AI integration:

```python
def make_ai_decision(self, snapshot):
    # Prepare data for LLM
    prompt = f"""
    You are a trading AI. Analyze the market:
    
    Balance: {snapshot['account']['balance']}
    Equity: {snapshot['account']['equity']}
    Positions: {len(snapshot['positions'])}
    
    Current symbol: {snapshot['current_symbol']['name']}
    Bid: {snapshot['current_symbol']['bid']}
    Ask: {snapshot['current_symbol']['ask']}
    
    Available commands:
    - BUY <volume>
    - SELL <volume>
    - CLOSE_ALL
    
    Return ONLY a command or NO_ACTION
    """
    
    # Call LLM API (OpenAI, Claude, etc.)
    response = your_llm_api_call(prompt)
    
    if response != "NO_ACTION":
        return response
    
    return None
```

## Command Examples

Command format in `AI_commands.txt`:

```
<ID> <COMMAND> [parameters]
```

Examples:

```
1 BUY 0.10
2 SELL 0.05
3 SET_SYMBOL EURUSD
4 BUY_LIMIT 0.10 1.2000
5 MODIFY_SLTP 123456 1.1950 1.2050
6 CLOSE_TICKET 123456
7 CLOSE_ALL
```

**Important**: ID must be unique and increasing. EA only executes commands with a new ID.

## AI_snapshot.json Format

EA creates a JSON file with full account state:

```json
{
  "account": {
    "balance": 10000.00,
    "equity": 10050.00,
    "margin": 100.00,
    "free_margin": 9950.00,
    "margin_level": 10050.00,
    "profit": 50.00
  },
  "current_symbol": {
    "name": "EURUSD",
    "bid": 1.12345,
    "ask": 1.12355,
    "spread": 10
  },
  "positions": [
    {
      "ticket": 123456,
      "symbol": "EURUSD",
      "type": "BUY",
      "volume": 0.10,
      "open_price": 1.12300,
      "sl": 1.12000,
      "tp": 1.12500,
      "profit": 50.00
    }
  ],
  "pending_orders": [],
  "timestamp": "2025.11.13 14:30:00"
}
```

## Safety

⚠️ **IMPORTANT**: This system gives AI full control over the account!

### Recommendations:

1. **USE ONLY DEMO ACCOUNT** for experiments
2. Start with minimum volumes
3. Monitor EA and agent logs
4. Set constraints in the AI itself (prompt engineering)
5. Add circuit breaker system in AI agent

### Example Circuit Breaker:

```python
def check_safety_limits(self, snapshot):
    """Check safety before executing command"""
    account = snapshot['account']
    
    # Maximum drawdown
    if account['equity'] < account['balance'] * 0.9:
        print("STOP: Drawdown exceeds 10%")
        return False
    
    # Maximum number of positions
    if len(snapshot['positions']) > 5:
        print("STOP: Too many open positions")
        return False
    
    return True
```

## Architecture

```
┌─────────────────┐
│   AI Agent      │ ← System brain (LLM, logic)
│   (Python)      │
└────────┬────────┘
         │
         │ AI_snapshot.json (reads)
         │ AI_commands.txt (writes)
         │
┌────────▼────────┐
│   EA Executor   │ ← Dumb executor (MT5 API)
│   (MQL5)        │
└────────┬────────┘
         │
         │ OrderSend(), PositionClose()
         │
┌────────▼────────┐
│   MT5 Terminal  │ ← Broker, demo account
└─────────────────┘
```

## Development

### Testing EA without AI

You can manually create `AI_commands.txt` in MT5 folder:
```
C:\Users\<USERNAME>\AppData\Roaming\MetaQuotes\Terminal\Common\Files\AI_commands.txt
```

And write a command:
```
1 BUY 0.01
```

EA will execute the command on next timer tick.

### Logs

EA outputs all actions to MT5 journal (Experts tab in Toolbox).

AI Agent outputs analysis to Python console.

## FAQ

**Q: Why commands through files instead of API?**  
A: This is the simplest and most reliable way for MVP. Files work locally, require no network interaction, easy to debug.

**Q: Can it be used on a real account?**  
A: Technically yes, but **highly not recommended**. This is an experimental system. Test on demo for several months first.

**Q: How to add indicators?**  
A: You can extend `WriteSnapshot()` in EA by adding indicator calculations (MA, RSI, ATR, etc.) and writing them to JSON.

**Q: Is MT4 supported?**  
A: No, only MT5. MT4 has different API for position management.

## License

MIT License - use at your own risk.

## Contributing

Pull requests are welcome! Especially:
- Examples of integrations with different LLMs
- Security improvements
- Additional commands
- Tests

---

**Remember**: AI makes ALL decisions. You only create the tool
