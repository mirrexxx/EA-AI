# Quick Start Guide

Get your AI trading system up and running in 5 minutes.

## Prerequisites

- MetaTrader 5 installed
- Python 3.7+ installed
- Demo trading account (DO NOT use real account for testing!)

## Step 1: Install the EA

1. Locate your MT5 data folder:
   - Open MT5
   - File → Open Data Folder
   - Navigate to `MQL5\Experts\`

2. Copy `AI_Executor.mq5` to the Experts folder

3. Compile the EA:
   - Press F4 in MT5 to open MetaEditor
   - Open `AI_Executor.mq5`
   - Press F7 to compile
   - You should see "0 error(s), 0 warning(s)"

4. Attach EA to chart:
   - In MT5, drag `AI_Executor` from Navigator → Expert Advisors onto any chart
   - In the dialog:
     - Check "Allow Algo Trading"
     - Keep default settings or adjust:
       - `TimerIntervalSeconds`: 5 (check for commands every 5 seconds)
       - `CommandFile`: AI_commands.txt
       - `SnapshotFile`: AI_snapshot.json
   - Click OK

5. Enable AutoTrading:
   - Click the "AutoTrading" button in MT5 toolbar (should turn green)

✅ EA is now running! It will create `AI_snapshot.json` in:
```
C:\Users\<USERNAME>\AppData\Roaming\MetaQuotes\Terminal\Common\Files\
```

## Step 2: Test the EA Manually

Before running the AI agent, test that the EA works:

1. Navigate to MT5 Common Files folder:
   ```
   C:\Users\<USERNAME>\AppData\Roaming\MetaQuotes\Terminal\Common\Files\
   ```

2. Check that `AI_snapshot.json` exists and contains data

3. Create `AI_commands.txt` in the same folder with this content:
   ```
   1 BUY 0.01
   ```

4. Wait 5 seconds (one timer interval)

5. Check MT5:
   - Look at the Experts log (Toolbox → Experts tab)
   - You should see: "Executing command ID 1: BUY"
   - Check your open positions - you should have a 0.01 lot buy position

6. Close the position by appending to `AI_commands.txt`:
   ```
   1 BUY 0.01
   2 CLOSE_ALL
   ```

7. Wait 5 seconds - all positions should close

✅ EA is working correctly!

## Step 3: Run the AI Agent

Now let's run the Python agent that will automate command generation.

1. Open terminal/command prompt

2. Navigate to the project folder:
   ```bash
   cd /path/to/EA-AI
   ```

3. Run the basic agent:
   ```bash
   python ai_agent.py
   ```

4. You should see:
   ```
   AI Trading Agent started
   Snapshot file: C:\Users\...\AI_snapshot.json
   Commands file: C:\Users\...\AI_commands.txt
   Check interval: 5 seconds
   
   Waiting for snapshot file from EA...
   ```

5. The agent will:
   - Read `AI_snapshot.json` every 5 seconds
   - Display current market state
   - Make decisions (currently no action - placeholder)
   - Write commands to `AI_commands.txt`

✅ Basic agent is running!

## Step 4: Add AI Intelligence

The basic agent doesn't actually trade - it just monitors. To add real AI:

### Option A: Use the Advanced Example

1. Open `examples/ai_agent_with_llm.py`

2. Uncomment the LLM integration you want to use:
   - OpenAI GPT
   - Anthropic Claude
   - Or add your own

3. Set your API key:
   ```bash
   # Linux/Mac
   export OPENAI_API_KEY="your-key-here"
   
   # Windows
   set OPENAI_API_KEY=your-key-here
   ```

4. Run the advanced agent:
   ```bash
   python examples/ai_agent_with_llm.py
   ```

### Option B: Modify ai_agent.py

Edit the `make_ai_decision()` function in `ai_agent.py`:

```python
def make_ai_decision(self, snapshot):
    # Your AI logic here
    # Return a command string like "BUY 0.10" or None
    
    # Example: Simple moving average strategy
    account = snapshot['account']
    symbol = snapshot['current_symbol']
    
    # Only trade if we have no positions
    if len(snapshot['positions']) == 0:
        # Simple example: buy if spread is low
        if symbol['spread'] < 15:
            return "BUY 0.01"
    
    return None
```

## Safety Checklist

Before running with AI:

- [ ] Using DEMO account (check MT5 account number)
- [ ] Start with minimum lot size (0.01)
- [ ] Monitor the first few trades manually
- [ ] Circuit breaker is enabled (in advanced agent)
- [ ] You understand all commands in API_REFERENCE.md
- [ ] You can stop the agent with Ctrl+C
- [ ] You can disable EA by clicking AutoTrading button in MT5

## Common Issues

### Issue: "Snapshot file not found"
**Solution:** Make sure EA is running on a chart in MT5 and AutoTrading is enabled.

### Issue: Commands not executing
**Solution:** 
1. Check MT5 Experts log for errors
2. Verify command format (see API_REFERENCE.md)
3. Make sure command ID is incrementing
4. Check that AutoTrading is enabled

### Issue: "Invalid volume" error
**Solution:** Check your broker's minimum lot size. Use 0.01 or higher.

### Issue: Agent path error on Windows
**Solution:** Set MT5_COMMON_PATH manually in the script:
```python
MT5_COMMON_PATH = r"C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\Common\Files"
```

### Issue: Trades losing money
**Solution:** 
1. This is expected in testing - markets are unpredictable
2. Review your AI logic
3. Add stop losses: `MODIFY_SLTP <ticket> <sl> <tp>`
4. Implement better risk management in your AI

## Next Steps

1. **Read the API Reference**: Understand all available commands
   - [API_REFERENCE.md](API_REFERENCE.md)

2. **Study the Examples**:
   - `examples/ai_agent_with_llm.py` - Full-featured agent with safety
   - `examples/example_commands.txt` - Command examples
   - `examples/example_snapshot.json` - Data structure

3. **Customize Your AI**:
   - Add technical indicators
   - Integrate with TradingView signals
   - Connect to your own ML models
   - Add risk management rules

4. **Monitor and Improve**:
   - Keep logs of all trades
   - Analyze performance
   - Adjust AI prompts/logic
   - Add more safety checks

## Architecture Overview

```
┌─────────────────────────────────────────┐
│          Your AI Logic                  │
│   (LLM, ML Model, Strategy, etc.)      │
└──────────────┬──────────────────────────┘
               │
               ▼
       ┌───────────────┐
       │  ai_agent.py  │ ◄─── reads ─── AI_snapshot.json
       └───────┬───────┘
               │
               └──── writes ───► AI_commands.txt
                                      │
                                      ▼
                              ┌───────────────┐
                              │ AI_Executor   │
                              │    (EA)       │
                              └───────┬───────┘
                                      │
                                      ▼
                              ┌───────────────┐
                              │ MetaTrader 5  │
                              │ Demo Account  │
                              └───────────────┘
```

## Resources

- **Full Documentation**: [README.md](README.md) | [README_RU.md](README_RU.md)
- **Command Reference**: [API_REFERENCE.md](API_REFERENCE.md)
- **Examples**: `examples/` folder

## Support

Having issues? Check:
1. MT5 Experts log for EA errors
2. Python console for agent errors
3. Verify file permissions in Common\Files folder
4. Make sure files are in the correct location

## Remember

⚠️ **This gives AI full control over trading!**
- Always use DEMO account first
- Start with small position sizes
- Monitor closely
- Add safety limits in your AI logic
- Never leave it running unattended until thoroughly tested

---

Happy automated trading! 🤖📈
