# ✅ Acceptance Criteria - AI_Executor.mq5

## Overview
This document defines the acceptance criteria for the AI_Executor Expert Advisor. All criteria must be met for the implementation to be considered complete and ready for use.

---

## 🔧 Compilation & Installation

- [ ] **EA compiles in MetaTrader 5 without errors**
  - Zero compilation errors in MetaEditor
  - Zero compilation warnings (or only acceptable warnings)
  - Compatible with MT5 build 3000+

- [ ] **EA can be attached to any chart**
  - Loads successfully on any symbol
  - Loads successfully on any timeframe
  - No initialization errors in Experts log

- [ ] **Required files are created automatically**
  - AI_commands.txt is created if it doesn't exist
  - AI_snapshot.json is created on first timer execution
  - Files are created in TERMINAL_COMMONDATA_PATH\MQL5\Files\

---

## 📁 File Management

- [ ] **AI_commands.txt handling**
  - EA creates file with "0 INIT" on first run
  - EA reads file without errors
  - EA processes only the last line
  - EA handles empty file gracefully
  - EA handles malformed lines gracefully

- [ ] **AI_snapshot.json creation**
  - File is valid JSON format
  - File is created every SnapshotInterval seconds
  - File contains all required fields
  - File is readable by external programs
  - File updates even when no trades are active

---

## 🎛️ Command Processing

### Symbol Management

- [ ] **SET_SYMBOL command works correctly**
  - Changes activeSymbol to specified symbol
  - Symbol must exist in MarketWatch
  - Subsequent orders use new symbol
  - Logs symbol change to Experts tab
  - Handles invalid symbols gracefully

### Market Orders

- [ ] **BUY command works correctly**
  - Opens buy position at market price
  - Uses correct volume from command
  - Uses activeSymbol
  - Returns ticket number in logs
  - Handles broker errors gracefully

- [ ] **SELL command works correctly**
  - Opens sell position at market price
  - Uses correct volume from command
  - Uses activeSymbol
  - Returns ticket number in logs
  - Handles broker errors gracefully

### Pending Orders

- [ ] **BUY_LIMIT command works correctly**
  - Places buy limit order at specified price
  - Order appears in orders array of snapshot
  - Price validation is handled by broker only
  - Logs order ticket number

- [ ] **SELL_LIMIT command works correctly**
  - Places sell limit order at specified price
  - Order appears in orders array of snapshot
  - Price validation is handled by broker only
  - Logs order ticket number

- [ ] **BUY_STOP command works correctly**
  - Places buy stop order at specified price
  - Order appears in orders array of snapshot
  - Price validation is handled by broker only
  - Logs order ticket number

- [ ] **SELL_STOP command works correctly**
  - Places sell stop order at specified price
  - Order appears in orders array of snapshot
  - Price validation is handled by broker only
  - Logs order ticket number

### Position Management

- [ ] **CLOSE_TICKET command works correctly**
  - Closes specified position by ticket
  - Position is removed from snapshot
  - Logs closure result
  - Handles invalid ticket gracefully

- [ ] **CLOSE_SYMBOL command works correctly**
  - Closes all positions for specified symbol
  - All matching positions are closed
  - Other symbols' positions remain open
  - Logs number of positions closed

- [ ] **CLOSE_ALL command works correctly**
  - Closes all open positions
  - Works across all symbols
  - Positions array in snapshot becomes empty
  - Logs total positions closed

### Position Modification

- [ ] **SET_SL command works correctly**
  - Sets stop loss for specified position
  - SL appears in snapshot
  - TP remains unchanged
  - Zero SL removes stop loss
  - Logs modification result

- [ ] **SET_TP command works correctly**
  - Sets take profit for specified position
  - TP appears in snapshot
  - SL remains unchanged
  - Zero TP removes take profit
  - Logs modification result

- [ ] **MODIFY command works correctly**
  - Modifies both SL and TP simultaneously
  - Both values appear in snapshot
  - Zero values keep current levels
  - More efficient than separate commands
  - Logs modification result

### Order Management

- [ ] **CANCEL_PENDING command works correctly**
  - Cancels specified pending order
  - Order is removed from orders array
  - Logs cancellation result
  - Handles invalid ticket gracefully

- [ ] **CANCEL_ALL_PENDING command works correctly**
  - Cancels all pending orders
  - Works across all symbols
  - Orders array in snapshot becomes empty
  - Logs number of orders cancelled

---

## 📊 Snapshot Generation

### JSON Structure

- [ ] **server_time field**
  - Present in every snapshot
  - Format: "YYYY-MM-DD HH:MM:SS"
  - Shows current server time

- [ ] **active_symbol field**
  - Present in every snapshot
  - Shows currently selected symbol
  - Updates when SET_SYMBOL is used

- [ ] **account object**
  - Contains balance field
  - Contains equity field
  - Contains margin field
  - All values are numbers with 2 decimal places

- [ ] **symbol_info object**
  - Contains bid field (current bid price)
  - Contains ask field (current ask price)
  - Contains spread_points field
  - Prices have correct number of digits for symbol

- [ ] **positions array**
  - Contains all open positions
  - Each position has ticket field
  - Each position has symbol field
  - Each position has type field ("BUY" or "SELL")
  - Each position has volume field
  - Each position has price_open field
  - Each position has sl field
  - Each position has tp field
  - Each position has profit field

- [ ] **orders array**
  - Contains all pending orders
  - Each order has ticket field
  - Each order has symbol field
  - Each order has type field (BUY_LIMIT, SELL_LIMIT, etc.)
  - Each order has volume field
  - Each order has price field

### Update Frequency

- [ ] **Snapshot updates on timer**
  - Updates every SnapshotInterval seconds
  - Updates regardless of trading activity
  - Updates even when market is closed
  - File write is atomic (no partial writes)

---

## 🚫 No Limitations Policy

- [ ] **EA does NOT validate lot size**
  - Accepts any volume value from command
  - Only broker limits apply
  - No minimum/maximum volume checks

- [ ] **EA does NOT validate risk**
  - No position sizing logic
  - No max loss checks
  - No max drawdown checks
  - No equity percentage limits

- [ ] **EA does NOT validate time/session**
  - No trading hours restrictions
  - No day-of-week filters
  - No news event filters
  - Executes commands 24/7 (when market open)

- [ ] **EA does NOT limit number of trades**
  - No max positions per symbol
  - No max total positions
  - No max pending orders
  - No daily/weekly trade limits

- [ ] **EA does NOT restrict symbols**
  - Works with any symbol in MarketWatch
  - No symbol whitelist/blacklist
  - No asset class restrictions
  - Switches symbols freely

- [ ] **EA does NOT validate volatility**
  - No spread checks
  - No volatility filters
  - No slippage checks
  - Executes in any market conditions

- [ ] **EA does NOT validate margin**
  - No margin level checks
  - No free margin validation
  - Only broker's stop out applies
  - AI is responsible for margin management

---

## 🔄 Command ID Processing

- [ ] **Commands are processed by ID**
  - EA tracks last processed command ID
  - Only commands with new (higher) ID are executed
  - Same ID is ignored (not re-executed)
  - IDs can skip numbers (1, 5, 10 is valid)

- [ ] **Only last line is processed**
  - EA reads entire file
  - EA processes only the last non-empty line
  - Previous lines are ignored
  - File can grow indefinitely

---

## 📝 Logging

- [ ] **All commands are logged**
  - Each executed command is logged to Experts tab
  - Log includes command ID
  - Log includes command type
  - Log includes key parameters

- [ ] **Execution results are logged**
  - Success/failure status
  - Ticket numbers for new orders/positions
  - Error codes and messages for failures
  - Number of positions/orders affected

- [ ] **File operations are logged**
  - File creation events
  - File read/write errors
  - File paths on initialization

---

## ⚙️ EA Behavior

- [ ] **OnInit behavior**
  - Sets activeSymbol to _Symbol
  - Creates AI_commands.txt if needed
  - Starts timer successfully
  - Creates initial snapshot
  - Logs initialization details

- [ ] **OnTimer behavior**
  - Calls ProcessCommands()
  - Calls CreateSnapshot()
  - Executes every SnapshotInterval seconds
  - Handles errors without stopping

- [ ] **OnTick behavior**
  - Function exists but is empty
  - No logic runs on every tick
  - Minimal CPU usage

- [ ] **OnDeinit behavior**
  - Kills timer
  - Logs deinit reason
  - Cleans up resources

---

## 🛡️ Error Handling

- [ ] **EA continues after trade errors**
  - Invalid volume doesn't stop EA
  - Invalid symbol doesn't stop EA
  - Requotes don't stop EA
  - Network errors don't stop EA

- [ ] **EA continues after file errors**
  - Missing files don't stop EA
  - File read errors don't stop EA
  - File write errors don't stop EA
  - Permission errors are logged

- [ ] **EA handles malformed commands**
  - Missing parameters are ignored
  - Invalid syntax is logged
  - Typos don't crash EA
  - Empty lines are skipped

---

## 🧪 Testing Scenarios

### Basic Functionality

- [ ] **Test on multiple symbols**
  - Test on EURUSD (Forex)
  - Test on XAUUSD (Metal)
  - Test on US30 (Index)
  - Test on BTCUSD (Crypto)

- [ ] **Test all order types**
  - Market buy and sell
  - All 4 pending order types
  - Position modifications
  - Order cancellations

- [ ] **Test edge cases**
  - Zero volume commands
  - Negative volumes
  - Extremely large volumes
  - Invalid ticket numbers
  - Non-existent symbols

### Integration Testing

- [ ] **Test with external AI**
  - Python script can write commands
  - Python script can read snapshot
  - Commands execute correctly
  - Snapshot updates properly

- [ ] **Test rapid commands**
  - Multiple commands in sequence
  - Commands faster than SnapshotInterval
  - ID increments work correctly
  - No commands are lost

### Stress Testing

- [ ] **Test with many positions**
  - 10+ open positions
  - 10+ pending orders
  - CLOSE_ALL works correctly
  - Snapshot remains valid JSON

- [ ] **Test long-running**
  - EA runs for 1+ hours
  - No memory leaks
  - No file handle leaks
  - Performance remains stable

---

## 📋 Documentation

- [ ] **README.md is complete**
  - Project overview
  - Feature list
  - Quick start guide
  - Command reference
  - Safety warnings

- [ ] **Experts/README.md is complete**
  - Detailed EA documentation
  - All commands explained with examples
  - Snapshot format documented
  - Error handling explained
  - Troubleshooting guide

- [ ] **IMPLEMENTATION_SUMMARY.md is complete**
  - Architecture description
  - Design decisions explained
  - File structure documented
  - Technical details included

- [ ] **QUICK_START.md is complete**
  - Step-by-step installation
  - Configuration instructions
  - First command walkthrough
  - Common issues addressed

- [ ] **example_ai_integration.py is complete**
  - Working Python example
  - Command sending demonstrated
  - Snapshot reading demonstrated
  - Error handling included
  - Comments explain logic

---

## ✅ Final Checklist

- [ ] All source code is properly formatted
- [ ] All files use consistent naming conventions
- [ ] No hardcoded paths (uses terminal functions)
- [ ] No debug code left in production
- [ ] All public functions are documented
- [ ] Code follows MQL5 best practices
- [ ] Repository structure is clean
- [ ] All documentation is accurate
- [ ] Example code is tested and working
- [ ] README links are valid

---

## 🎯 Definition of Done

The AI_Executor EA is considered complete when:

1. ✅ All acceptance criteria above are met
2. ✅ EA compiles with zero errors
3. ✅ All commands execute correctly on demo account
4. ✅ All documentation is complete and accurate
5. ✅ Example Python integration works end-to-end
6. ✅ No critical bugs or issues remain
7. ✅ Code is ready for public release

---

**Status:** This checklist should be verified by testing on MT5 demo account.

**Last Updated:** 2025-11-13  
**Version:** 1.00
