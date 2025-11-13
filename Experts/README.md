# 📘 AI_Executor.mq5 - Expert Advisor Documentation

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
- [File Locations](#file-locations)
- [Input Parameters](#input-parameters)
- [Command Reference](#command-reference)
- [Snapshot Format](#snapshot-format)
- [Error Handling](#error-handling)
- [Trading Logic](#trading-logic)
- [Best Practices](#best-practices)

## Overview

**AI_Executor.mq5** is a fully autonomous Expert Advisor that serves as a low-level trading API for external AI systems. It provides complete trading freedom without any built-in limitations, filters, or risk management.

### Key Characteristics
- **Pure Execution Layer** - No decision-making logic
- **Command-Driven** - Reads commands from text file
- **Real-Time Snapshots** - Provides market data in JSON format
- **Universal Compatibility** - Works with any programming language
- **Minimal Overhead** - Timer-based, not tick-based

## Installation

### Step 1: Copy the EA
```
Copy AI_Executor.mq5 to:
[MT5_DATA_FOLDER]\MQL5\Experts\
```

### Step 2: Compile
1. Open MetaEditor (F4 in MT5)
2. Open AI_Executor.mq5
3. Click "Compile" (F7)
4. Check for zero errors

### Step 3: Attach to Chart
1. Open any chart in MT5
2. Drag AI_Executor from Navigator → Expert Advisors
3. Enable "Allow Algo Trading" in MT5
4. Click OK

### Step 4: Verify Files Created
The EA will automatically create:
- `AI_commands.txt` - Command input file
- `AI_snapshot.json` - Market data output file

**File Location:**
```
Windows: %APPDATA%\MetaQuotes\Terminal\Common\Files\
```

## File Locations

### Commands File
```
Full Path: [TERMINAL_COMMONDATA_PATH]\MQL5\Files\AI_commands.txt
```

### Snapshot File
```
Full Path: [TERMINAL_COMMONDATA_PATH]\MQL5\Files\AI_snapshot.json
```

### Finding Your Path
```mql5
Print(TerminalInfoString(TERMINAL_COMMONDATA_PATH));
```

## Input Parameters

### SnapshotInterval
- **Type:** Integer
- **Default:** 3 seconds
- **Description:** How often to update AI_snapshot.json
- **Range:** 1-3600 seconds
- **Recommendation:** 3-5 seconds for most AI systems

## Command Reference

### Command Format
```
<ID> <COMMAND> [parameters...]
```

### Rules
- EA processes **only the last line** of AI_commands.txt
- Commands are executed only if ID is greater than last processed ID
- Each command must have a unique, incrementing ID
- Parameters are space-separated

---

### Symbol Management

#### SET_SYMBOL
**Syntax:**
```
<ID> SET_SYMBOL <symbol>
```

**Example:**
```
15 SET_SYMBOL XAUUSD
16 SET_SYMBOL EURUSD
17 SET_SYMBOL BTCUSD
```

**Notes:**
- Symbol must exist in MarketWatch
- EA will attempt to add symbol if not visible
- All subsequent orders use this symbol until changed

---

### Market Orders

#### BUY
**Syntax:**
```
<ID> BUY <volume>
```

**Example:**
```
20 BUY 0.10
21 BUY 1.00
22 BUY 0.01
```

**Notes:**
- Opens market buy position at current ASK price
- Volume is in lots (not micro-lots)
- Executes immediately at best available price

#### SELL
**Syntax:**
```
<ID> SELL <volume>
```

**Example:**
```
25 SELL 0.10
26 SELL 0.50
```

**Notes:**
- Opens market sell position at current BID price
- Volume is in lots

---

### Pending Orders

#### BUY_LIMIT
**Syntax:**
```
<ID> BUY_LIMIT <volume> <price>
```

**Example:**
```
30 BUY_LIMIT 0.10 2390.50
```

**Notes:**
- Buy limit order (buy when price goes DOWN to price)
- Price must be below current ASK

#### SELL_LIMIT
**Syntax:**
```
<ID> SELL_LIMIT <volume> <price>
```

**Example:**
```
31 SELL_LIMIT 0.10 2410.50
```

**Notes:**
- Sell limit order (sell when price goes UP to price)
- Price must be above current BID

#### BUY_STOP
**Syntax:**
```
<ID> BUY_STOP <volume> <price>
```

**Example:**
```
32 BUY_STOP 0.10 2410.00
```

**Notes:**
- Buy stop order (buy when price goes UP to price)
- Price must be above current ASK

#### SELL_STOP
**Syntax:**
```
<ID> SELL_STOP <volume> <price>
```

**Example:**
```
33 SELL_STOP 0.10 2390.00
```

**Notes:**
- Sell stop order (sell when price goes DOWN to price)
- Price must be below current BID

---

### Position Management

#### CLOSE_TICKET
**Syntax:**
```
<ID> CLOSE_TICKET <ticket>
```

**Example:**
```
40 CLOSE_TICKET 12345678
```

**Notes:**
- Closes specific position by ticket number
- Get ticket from AI_snapshot.json positions array

#### CLOSE_SYMBOL
**Syntax:**
```
<ID> CLOSE_SYMBOL <symbol>
```

**Example:**
```
41 CLOSE_SYMBOL XAUUSD
42 CLOSE_SYMBOL EURUSD
```

**Notes:**
- Closes all positions for specified symbol
- Processes positions from last to first

#### CLOSE_ALL
**Syntax:**
```
<ID> CLOSE_ALL
```

**Example:**
```
50 CLOSE_ALL
```

**Notes:**
- Closes all open positions across all symbols
- Emergency command for portfolio liquidation

---

### Position Modification

#### SET_SL
**Syntax:**
```
<ID> SET_SL <ticket> <price>
```

**Example:**
```
60 SET_SL 12345678 2390.00
```

**Notes:**
- Sets Stop Loss for specified position
- Price of 0 removes SL
- Does not affect Take Profit

#### SET_TP
**Syntax:**
```
<ID> SET_TP <ticket> <price>
```

**Example:**
```
61 SET_TP 12345678 2430.00
```

**Notes:**
- Sets Take Profit for specified position
- Price of 0 removes TP
- Does not affect Stop Loss

#### MODIFY
**Syntax:**
```
<ID> MODIFY <ticket> <sl> <tp>
```

**Example:**
```
65 MODIFY 12345678 2390.00 2430.00
```

**Notes:**
- Modifies both SL and TP simultaneously
- Use 0 to leave current value unchanged
- More efficient than separate SET_SL and SET_TP

---

### Order Management

#### CANCEL_PENDING
**Syntax:**
```
<ID> CANCEL_PENDING <ticket>
```

**Example:**
```
70 CANCEL_PENDING 87654321
```

**Notes:**
- Cancels specific pending order
- Get ticket from AI_snapshot.json orders array

#### CANCEL_ALL_PENDING
**Syntax:**
```
<ID> CANCEL_ALL_PENDING
```

**Example:**
```
75 CANCEL_ALL_PENDING
```

**Notes:**
- Cancels all pending orders across all symbols
- Does not affect open positions

---

## Snapshot Format

### Structure
```json
{
  "server_time": "YYYY-MM-DD HH:MM:SS",
  "active_symbol": "SYMBOL",
  "account": {
    "balance": 0.00,
    "equity": 0.00,
    "margin": 0.00
  },
  "symbol_info": {
    "bid": 0.00000,
    "ask": 0.00000,
    "spread_points": 0
  },
  "positions": [...],
  "orders": [...]
}
```

### Account Object
- **balance** - Account balance (total deposits - withdrawals)
- **equity** - Current account value (balance + floating P/L)
- **margin** - Used margin for open positions

### Symbol Info Object
- **bid** - Current bid price (price to sell at)
- **ask** - Current ask price (price to buy at)
- **spread_points** - Spread in points

### Positions Array
Each position object contains:
```json
{
  "ticket": 12345678,
  "symbol": "XAUUSD",
  "type": "BUY",
  "volume": 0.10,
  "price_open": 2400.50,
  "sl": 2390.00,
  "tp": 2430.00,
  "profit": 4.75
}
```

### Orders Array
Each order object contains:
```json
{
  "ticket": 87654321,
  "symbol": "XAUUSD",
  "type": "SELL_LIMIT",
  "volume": 0.20,
  "price": 2420.00
}
```

## Error Handling

### Trade Errors
- Errors are logged to MT5 Experts tab
- EA continues running after errors
- Failed commands are skipped (not retried)

### Common Errors
- **Invalid symbol** - Symbol not in MarketWatch
- **Invalid volume** - Below broker minimum or above maximum
- **Invalid stops** - SL/TP too close to price
- **Not enough money** - Insufficient margin
- **Market closed** - Trading session ended

### Error Recovery
EA does not:
- Retry failed commands automatically
- Queue commands for later execution
- Stop on errors

AI must:
- Monitor snapshot for execution results
- Implement retry logic if needed
- Handle broker errors gracefully

## Trading Logic

### OnInit()
1. Set activeSymbol to current chart symbol
2. Create AI_commands.txt if not exists
3. Start timer with SnapshotInterval
4. Create initial snapshot

### OnTimer()
1. Read AI_commands.txt
2. Parse last line
3. Check if command ID is new
4. Execute command if ID > lastCommandID
5. Update AI_snapshot.json

### OnTick()
- Intentionally empty
- All logic runs on timer
- No tick-by-tick overhead

### OnDeinit()
- Kill timer
- Log shutdown reason

## Best Practices

### For AI Developers

1. **Always increment IDs**
   ```python
   command_id += 1
   write_command(f"{command_id} BUY 0.10")
   ```

2. **Read snapshot before commanding**
   ```python
   snapshot = read_snapshot()
   if snapshot['account']['equity'] > threshold:
       send_command("BUY 0.10")
   ```

3. **Verify execution**
   ```python
   old_positions = len(snapshot['positions'])
   send_buy_command()
   time.sleep(4)  # Wait for next snapshot
   new_snapshot = read_snapshot()
   assert len(new_snapshot['positions']) > old_positions
   ```

4. **Handle errors gracefully**
   ```python
   try:
       send_command("BUY 100.00")  # Too large
   except:
       pass  # EA logs error but continues
   ```

### For EA Users

1. **Use demo accounts only**
2. **Monitor the Experts tab** for execution logs
3. **Set appropriate snapshot interval** (3-5 seconds)
4. **Keep EA running** on stable connection
5. **Check file permissions** in Common\Files folder

### Command Timing

- Wait at least SnapshotInterval seconds between related commands
- Don't send multiple commands in same second
- Allow time for broker execution

### Volume Management

- Start with minimum lots (0.01)
- Check broker specifications
- Consider account size

## Troubleshooting

### EA Not Creating Files
**Solution:** Check file permissions in Common\Files folder

### Commands Not Executing
**Possible causes:**
- ID not incrementing
- Syntax error in command
- Broker restrictions
- Insufficient margin

**Solution:** Check Experts tab for error messages

### Snapshot Not Updating
**Possible causes:**
- Timer not started
- EA removed from chart
- MT5 not connected to server

**Solution:** Restart EA, check connection

### Orders Not Filling
**Possible causes:**
- Requote (price moved)
- Invalid stop levels
- Market closed
- Insufficient liquidity

**Solution:** Check symbol trading hours and specifications

## Technical Details

### File Operations
- Uses FILE_COMMON flag for shared file access
- Text mode for commands
- UTF-8 encoding supported

### Order Execution
- Tries FOK → IOC → RETURN filling modes
- 10 point deviation for market orders
- No deviation for pending orders

### Thread Safety
- All operations in timer thread
- No concurrent file access issues
- Command processing is sequential

## Support

For issues or questions:
1. Check MT5 Experts tab for error messages
2. Verify file paths are correct
3. Test on demo account first
4. Review example_ai_integration.py

---

**Last Updated:** 2025-11-13  
**Version:** 1.00  
**Compatibility:** MetaTrader 5 Build 3000+
