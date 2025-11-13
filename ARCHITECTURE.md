# System Architecture

This document explains the architecture and design decisions of the EA-AI trading system.

## Overview

EA-AI is a file-based, AI-controlled trading system where all intelligence resides outside the trading platform. The Expert Advisor (EA) is a "dumb executor" that provides a simple API to MetaTrader 5.

## Core Principles

1. **Separation of Concerns**: Trading logic (AI) is completely separate from execution (EA)
2. **No Built-in Logic**: EA has zero trading decisions - it's pure API
3. **File-based Communication**: Simple, debuggable, works across different systems
4. **AI-First Design**: System designed for AI control, not human control

## Components

### 1. AI_Executor.mq5 (Expert Advisor)

**Purpose**: Pure executor - the "hands" of the system

**Responsibilities**:
- Read commands from file
- Execute trading operations via MT5 API
- Write market state to file
- Handle MT5-specific requirements (error codes, order types, etc.)

**Does NOT**:
- Make trading decisions
- Filter or validate trading logic
- Implement risk management
- Calculate indicators (though could be extended to)

**Key Functions**:
```
OnInit()           → Initialize EA, start timer
OnTimer()          → Every N seconds: read commands + write snapshot
ReadAndExecuteCommands() → Parse and execute from AI_commands.txt
WriteSnapshot()    → Write market state to AI_snapshot.json
Execute*()         → Individual command executors (BUY, SELL, etc.)
```

**Design Decisions**:
- Timer-based (not tick-based) for predictable, controllable execution
- Reads last command only (not all commands) for efficiency
- Uses command ID to prevent re-execution
- Writes to Common\Files for cross-platform file access
- No magic numbers, no filters, no automation - pure manual control via AI

### 2. ai_agent.py (AI Agent)

**Purpose**: The "brain" - decision maker

**Responsibilities**:
- Read market snapshot
- Analyze market conditions
- Make trading decisions
- Generate and write commands
- Monitor safety limits

**Key Functions**:
```
read_snapshot()      → Load AI_snapshot.json
write_command()      → Append to AI_commands.txt
analyze_market()     → Process market data
make_ai_decision()   → Generate trading decision (to be implemented by user)
run()                → Main execution loop
```

**Design Decisions**:
- Python for ease of AI/ML integration
- Append-only commands file for audit trail
- Auto-detection of MT5 files location
- Pluggable architecture for different AI backends

### 3. ai_agent_with_llm.py (Advanced Agent)

**Purpose**: Production-ready agent with safety features

**Additional Features**:
- LLM integration template (OpenAI, Claude)
- Circuit breaker for emergency stops
- Command validation before execution
- Comprehensive prompt engineering
- Trading history tracking

**Safety Mechanisms**:
```
check_safety_circuit_breaker()  → Stop on excessive drawdown
validate_command()              → Verify command validity
build_llm_prompt()              → Structure data for LLM
```

## Data Flow

### Normal Operation Cycle

```
┌─────────────────────────────────────────────────────────────┐
│                    EXECUTION CYCLE                          │
└─────────────────────────────────────────────────────────────┘

1. EA Timer Tick (every N seconds)
   │
   ├─► Read AI_commands.txt
   │   └─► Parse last line
   │       └─► Check if command ID is new
   │           ├─► YES: Execute command
   │           └─► NO:  Skip
   │
   └─► Write AI_snapshot.json
       └─► Account state
       └─► Current prices
       └─► Open positions
       └─► Pending orders

2. AI Agent Loop (every N seconds)
   │
   ├─► Read AI_snapshot.json
   │   └─► Parse market state
   │
   ├─► Analyze (via AI/LLM)
   │   └─► Consider positions
   │   └─► Consider prices
   │   └─► Consider account state
   │   └─► Make decision
   │
   └─► Write AI_commands.txt (if action needed)
       └─► Append: <ID> <COMMAND> <params>
```

### File Format Details

**AI_commands.txt** (Commands from AI to EA):
```
Format: <ID> <COMMAND> [param1] [param2] ...
Example:
1 BUY 0.10
2 SET_SYMBOL GBPUSD
3 CLOSE_ALL

Properties:
- Append-only (history preserved)
- EA reads last line only
- ID must increment
- Space-separated
```

**AI_snapshot.json** (Market state from EA to AI):
```json
{
  "account": { /* balance, equity, margin, etc. */ },
  "current_symbol": { /* bid, ask, spread */ },
  "positions": [ /* array of open positions */ ],
  "pending_orders": [ /* array of pending orders */ ],
  "timestamp": "2025.11.13 14:30:00"
}

Properties:
- Complete overwrite each cycle
- Structured JSON for easy parsing
- Contains all information needed for decisions
```

## Communication Protocol

### Why Files?

1. **Simplicity**: No network, no APIs, no authentication
2. **Debuggability**: Can inspect/modify files manually
3. **Reliability**: No connection issues
4. **Platform Independence**: Works on any OS
5. **Auditability**: Full command history preserved

### Synchronization

The system is **eventually consistent**:
- EA and Agent run independently
- No locks or synchronization needed
- Agent writes, EA reads (commands)
- EA writes, Agent reads (snapshot)
- Command execution confirmed in next snapshot

### Timing

Default timing (adjustable):
- EA timer: 5 seconds
- Agent loop: 5 seconds

This means:
- Worst case: 10 seconds from decision to execution confirmation
- Typical case: 5-7 seconds round trip

For faster execution:
- Reduce timer intervals (minimum: 1 second recommended)
- Consider tick-based EA execution (would need modification)

## Command Execution Flow

```
AI Agent                    AI_commands.txt              EA
   │                              │                       │
   │  1. Append command           │                       │
   ├──────────────────────────────►                       │
   │     "5 BUY 0.10"             │                       │
   │                              │                       │
   │                              │  2. Timer tick        │
   │                              ◄───────────────────────┤
   │                              │  3. Read last line    │
   │                              │     Parse ID=5, BUY   │
   │                              │                       │
   │                              │  4. Execute OrderSend()
   │                              │                       │
   │                              │  5. Write snapshot    │
   │                              ├──────────────────────►│
   │                              │                   AI_snapshot.json
   │  6. Read snapshot            │                       │
   ◄──────────────────────────────┤                       │
   │  7. Verify execution         │                       │
   │     (check positions array)  │                       │
```

## Extension Points

### Adding New Commands

1. Add to EA:
   ```mql5
   else if(command == "NEW_COMMAND")
   {
       if(count >= 3)
       {
           param = parts[2];
           ExecuteNewCommand(param);
       }
   }
   
   void ExecuteNewCommand(string param) {
       // Implementation
   }
   ```

2. Document in API_REFERENCE.md

3. Update AI agent to use new command

### Adding Indicators to Snapshot

1. In EA `WriteSnapshot()`:
   ```mql5
   // Calculate indicator
   double ma = iMA(currentSymbol, PERIOD_H1, 20, 0, MODE_SMA, PRICE_CLOSE);
   
   // Add to JSON
   FileWriteString(fileHandle, "  \"indicators\": {\n");
   FileWriteString(fileHandle, "    \"ma20\": " + DoubleToString(ma, 5) + "\n");
   FileWriteString(fileHandle, "  },\n");
   ```

2. AI agent can now use this data

### Adding Different AI Backends

The `make_ai_decision()` function is the integration point:

**Traditional ML Model**:
```python
def make_ai_decision(self, snapshot):
    # Extract features
    features = self.extract_features(snapshot)
    
    # Predict with your model
    prediction = self.model.predict(features)
    
    # Convert to command
    if prediction == 1:
        return "BUY 0.10"
    elif prediction == -1:
        return "SELL 0.10"
    
    return None
```

**External Signal Service**:
```python
def make_ai_decision(self, snapshot):
    # Call external API
    signal = requests.get('https://signals.example.com/api/forex').json()
    
    # Convert to command
    if signal['action'] == 'buy':
        return f"BUY {signal['volume']}"
    
    return None
```

**LLM with Context**:
```python
def make_ai_decision(self, snapshot):
    # Build prompt with historical context
    prompt = self.build_prompt_with_history(snapshot, self.trading_history)
    
    # Call LLM
    response = self.llm.generate(prompt)
    
    # Parse and validate
    command = self.parse_llm_response(response)
    
    return command if self.validate_command(command) else None
```

## Scalability Considerations

### Current Limitations

1. **Single Symbol Focus**: EA tracks one "current" symbol
   - Solution: Use SET_SYMBOL to switch, or modify EA to be multi-symbol

2. **File I/O Overhead**: Reading/writing files each cycle
   - Impact: Negligible for 5-second intervals
   - For sub-second trading: Consider socket/API communication

3. **Command History Growth**: AI_commands.txt grows indefinitely
   - Solution: Periodic cleanup (keep only last N commands)
   - Or use log rotation

4. **Single EA Instance**: One EA per chart
   - Solution: Run multiple charts with different EAs
   - Or modify EA to manage multiple strategies

### Scaling Up

**Multiple Symbols**:
```python
# AI Agent managing multiple symbols
for symbol in ['EURUSD', 'GBPUSD', 'XAUUSD']:
    self.write_command(f"SET_SYMBOL {symbol}")
    time.sleep(5)
    self.write_command("BUY 0.01")
```

**Multiple Strategies**:
- Run multiple agent instances with different logic
- Use command ID ranges to prevent conflicts
- Or use multiple command/snapshot files

**Production Deployment**:
```
MT5 Server
├── EA Instance 1 (EURUSD) ←→ Agent 1 (Scalping)
├── EA Instance 2 (GBPUSD) ←→ Agent 2 (Swing)
└── EA Instance 3 (XAUUSD) ←→ Agent 3 (Trend)
```

## Security Considerations

### File Access
- Files in Common\Files are accessible to all MT5 instances
- Consider file permissions in production
- Encrypt sensitive parameters if needed

### Command Validation
- EA trusts all commands (by design)
- Validation should be in AI agent
- Consider adding optional EA-side limits for production

### API Keys
- Never commit API keys to code
- Use environment variables
- Consider key rotation for production

### Circuit Breakers
- Essential for production use
- Implement at AI agent level
- Monitor external systems for failures

## Testing Strategy

### Unit Testing EA
- Test in Strategy Tester with manual commands file
- Verify each command type
- Check error handling

### Testing AI Agent
- Use example_snapshot.json for offline testing
- Mock LLM responses
- Verify command generation logic

### Integration Testing
1. Run EA on demo account
2. Manually create command file
3. Verify execution and snapshot updates

### Live Testing
1. Start with minimum lot sizes
2. Monitor for several days
3. Gradually increase position sizes
4. Always maintain circuit breakers

## Performance Characteristics

**Latency**:
- Command to execution: 0-5 seconds (one timer interval)
- Total decision loop: 5-10 seconds

**Throughput**:
- Limited by timer interval
- Practical max: 12 decisions/minute (5-second interval)
- Not suitable for HFT

**Resource Usage**:
- EA: Minimal CPU, tiny memory footprint
- Agent: Depends on AI backend
- File I/O: Negligible on modern systems

## Comparison with Alternatives

### vs. Native MQL5 EA
**EA-AI Advantages**:
- ✅ Use any programming language for logic
- ✅ Easy LLM/ML integration
- ✅ Rapid iteration without recompilation
- ✅ Better debugging and logging

**Native EA Advantages**:
- ✅ Lower latency
- ✅ Direct API access
- ✅ No file I/O overhead

### vs. REST API Integration
**File-based Advantages**:
- ✅ Simpler setup
- ✅ No network configuration
- ✅ Works offline
- ✅ Built-in audit trail

**REST API Advantages**:
- ✅ Lower latency
- ✅ Real-time bidirectional communication
- ✅ Better for high-frequency trading

### vs. Broker API (e.g., MetaTrader 5 Python package)
**EA-AI Advantages**:
- ✅ Works with any broker
- ✅ No broker-specific integration
- ✅ Stays within MT5 ecosystem

**Broker API Advantages**:
- ✅ Direct Python control
- ✅ No intermediate EA needed
- ✅ Better for algorithmic trading

## Future Enhancements

Potential improvements:

1. **Real-time Communication**: Add WebSocket support
2. **Multi-Symbol**: Extend EA to manage multiple symbols simultaneously
3. **Historical Data**: Add backtesting data to snapshot
4. **Advanced Orders**: Support for trailing stops, breakeven
5. **Risk Management**: Optional EA-side position limits
6. **Monitoring Dashboard**: Web UI to monitor agent performance
7. **Strategy Versioning**: Track which AI version made which trades

## Conclusion

This architecture prioritizes:
- **Simplicity** over performance
- **Flexibility** over optimization
- **Debuggability** over sophistication

It's designed for AI experimentation and learning, not high-frequency production trading. The separation of concerns allows you to focus on AI logic without dealing with MT5 API complexity.

For production use, consider additional safety layers, monitoring, and potentially migrating to a more robust communication protocol.
