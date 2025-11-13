# 🚀 Quick Start Guide - AI_Executor EA

This guide will help you get the AI_Executor Expert Advisor up and running in minutes.

---

## 📋 Prerequisites

### Required Software
- **MetaTrader 5** (Build 3000 or higher)
  - Download from: https://www.metatrader5.com/
- **Demo Trading Account** (REQUIRED - do not use live account)
- **Python 3.7+** (for AI integration example)

### Optional Tools
- **MetaEditor** (included with MT5)
- **Text Editor** (VS Code, Notepad++, etc.)
- **JSON Viewer** (for debugging snapshots)

---

## 🔧 Installation

### Step 1: Download the EA

Clone or download this repository:
```bash
git clone https://github.com/mirrexxx/EA-AI.git
cd EA-AI
```

### Step 2: Copy to MT5

1. Open MetaTrader 5
2. Click **File → Open Data Folder**
3. Navigate to `MQL5\Experts\`
4. Copy `Experts/AI_Executor.mq5` to this folder

**Full path example:**
```
C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\[INSTANCE_ID]\MQL5\Experts\AI_Executor.mq5
```

### Step 3: Compile the EA

1. Press **F4** to open MetaEditor
2. In Navigator, expand **Experts**
3. Double-click **AI_Executor.mq5**
4. Press **F7** to compile
5. Check the **Errors** tab - should show "0 errors"

✅ If compilation successful, you'll see:
```
0 error(s), 0 warning(s)
AI_Executor.ex5 compiled successfully
```

---

## 🎯 First Run

### Step 1: Attach EA to Chart

1. In MT5, open any chart (e.g., EURUSD, M5)
2. In **Navigator**, expand **Expert Advisors**
3. Drag **AI_Executor** onto the chart
4. A settings dialog will appear

### Step 2: Configure Settings

**Input Parameters:**
- `SnapshotInterval`: 3 (recommended for testing)

**Common Tab:**
- ✅ Enable "Allow Algo Trading" (must be checked!)
- ✅ Enable "Allow DLL imports" (if required by broker)

Click **OK**

### Step 3: Verify EA is Running

Check the **Experts** tab (View → Toolbox → Experts):

You should see:
```
AI_Executor initialized successfully
Active symbol: EURUSD
Snapshot interval: 3 seconds
Command file: C:\Users\...\AI_commands.txt
Snapshot file: C:\Users\...\AI_snapshot.json
```

### Step 4: Locate Runtime Files

The EA creates two files in the **Common Files** folder:

**Windows:**
```
C:\Users\[YourName]\AppData\Roaming\MetaQuotes\Terminal\Common\Files\
```

**To find this folder:**
1. In MT5, open MetaEditor (F4)
2. Click **File → Open Data Folder**
3. Go UP one level to **Terminal** folder
4. Open **Common\Files\**

You should see:
- ✅ `AI_commands.txt` - Created with "0 INIT"
- ✅ `AI_snapshot.json` - Updated every 3 seconds

---

## 💡 Your First Command

### Method 1: Manual Test (No Code)

1. Open `AI_commands.txt` in a text editor
2. Add a new line at the end:
   ```
   1 BUY 0.01
   ```
3. Save the file
4. Wait 3-5 seconds
5. Check MT5 **Experts** tab for execution log
6. Check **Trade** tab for new position

### Method 2: Python Script

Create a file `test_command.py`:

```python
import time
import os

# Path to command file (UPDATE THIS PATH!)
COMMANDS_FILE = r"C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\Common\Files\AI_commands.txt"

def send_command(command_id, command):
    """Append command to AI_commands.txt"""
    with open(COMMANDS_FILE, 'a') as f:
        f.write(f"{command_id} {command}\n")
    print(f"Sent: {command_id} {command}")

# Send a buy command
send_command(1, "BUY 0.01")

print("Command sent! Check MT5 Experts tab in 3-5 seconds.")
```

Run it:
```bash
python test_command.py
```

---

## 📊 Reading Snapshots

### View Snapshot Manually

1. Open `AI_snapshot.json` in a text editor or JSON viewer
2. You'll see current market state:

```json
{
  "server_time": "2025-11-13 15:30:00",
  "active_symbol": "EURUSD",
  "account": {
    "balance": 10000.00,
    "equity": 10005.50,
    "margin": 10.20
  },
  "symbol_info": {
    "bid": 1.08345,
    "ask": 1.08355,
    "spread_points": 10
  },
  "positions": [
    {
      "ticket": 12345678,
      "symbol": "EURUSD",
      "type": "BUY",
      "volume": 0.01,
      "price_open": 1.08350,
      "sl": 0.0,
      "tp": 0.0,
      "profit": 0.05
    }
  ],
  "orders": []
}
```

### Read Snapshot with Python

```python
import json
import os

# Path to snapshot file (UPDATE THIS PATH!)
SNAPSHOT_FILE = r"C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\Common\Files\AI_snapshot.json"

def read_snapshot():
    """Read and parse AI_snapshot.json"""
    with open(SNAPSHOT_FILE, 'r') as f:
        return json.load(f)

# Read current market state
snapshot = read_snapshot()

print(f"Server Time: {snapshot['server_time']}")
print(f"Symbol: {snapshot['active_symbol']}")
print(f"Balance: ${snapshot['account']['balance']:.2f}")
print(f"Equity: ${snapshot['account']['equity']:.2f}")
print(f"Bid: {snapshot['symbol_info']['bid']}")
print(f"Ask: {snapshot['symbol_info']['ask']}")
print(f"Open Positions: {len(snapshot['positions'])}")
```

---

## 🎮 Complete Trading Cycle

### Test All Basic Commands

Create `full_test.py`:

```python
import json
import time
import os

# UPDATE THESE PATHS!
COMMANDS_FILE = r"C:\path\to\AI_commands.txt"
SNAPSHOT_FILE = r"C:\path\to\AI_snapshot.json"

class AITrader:
    def __init__(self):
        self.command_id = 1
    
    def send_command(self, command):
        """Send command to EA"""
        with open(COMMANDS_FILE, 'a') as f:
            f.write(f"{self.command_id} {command}\n")
        print(f"[{self.command_id}] {command}")
        self.command_id += 1
    
    def read_snapshot(self):
        """Read current market snapshot"""
        with open(SNAPSHOT_FILE, 'r') as f:
            return json.load(f)
    
    def wait_and_show_status(self, seconds=5):
        """Wait and display account status"""
        time.sleep(seconds)
        snapshot = self.read_snapshot()
        print(f"  Balance: ${snapshot['account']['balance']:.2f}")
        print(f"  Equity: ${snapshot['account']['equity']:.2f}")
        print(f"  Positions: {len(snapshot['positions'])}")
        print(f"  Orders: {len(snapshot['orders'])}")
        return snapshot

# Initialize trader
trader = AITrader()

print("=== AI Trading Test Sequence ===\n")

# 1. Change symbol to XAUUSD (Gold)
print("Step 1: Set symbol to XAUUSD")
trader.send_command("SET_SYMBOL XAUUSD")
trader.wait_and_show_status()

# 2. Open a buy position
print("\nStep 2: Open buy position (0.01 lots)")
trader.send_command("BUY 0.01")
snapshot = trader.wait_and_show_status()

# Get ticket of position we just opened
if snapshot['positions']:
    ticket = snapshot['positions'][0]['ticket']
    print(f"  Opened ticket: {ticket}")
    
    # 3. Set stop loss and take profit
    print(f"\nStep 3: Modify position {ticket}")
    current_price = snapshot['symbol_info']['ask']
    sl_price = current_price - 10  # 10 points below
    tp_price = current_price + 20  # 20 points above
    trader.send_command(f"MODIFY {ticket} {sl_price} {tp_price}")
    trader.wait_and_show_status()
    
    # 4. Close the position
    print(f"\nStep 4: Close position {ticket}")
    trader.send_command(f"CLOSE_TICKET {ticket}")
    trader.wait_and_show_status()

# 5. Place a pending order
print("\nStep 5: Place BUY_LIMIT order")
snapshot = trader.read_snapshot()
limit_price = snapshot['symbol_info']['bid'] - 50  # 50 points below current
trader.send_command(f"BUY_LIMIT 0.01 {limit_price}")
snapshot = trader.wait_and_show_status()

# 6. Cancel pending orders
if snapshot['orders']:
    print("\nStep 6: Cancel all pending orders")
    trader.send_command("CANCEL_ALL_PENDING")
    trader.wait_and_show_status()

print("\n=== Test Complete ===")
```

Run it:
```bash
python full_test.py
```

---

## 🔍 Troubleshooting

### EA Not Starting

**Problem:** EA shows "Expert Advisors disabled"  
**Solution:** Click the **Algo Trading** button in MT5 toolbar (should be green)

**Problem:** EA removed from chart immediately  
**Solution:** 
1. Check that "Allow Algo Trading" is enabled in EA settings
2. Verify you're using a demo account
3. Check Experts tab for error messages

### Files Not Created

**Problem:** AI_commands.txt or AI_snapshot.json not found  
**Solution:**
1. Verify EA is running (check chart corner for smiley face)
2. Check Experts tab for file path
3. Verify folder permissions
4. Try running MT5 as administrator

### Commands Not Executing

**Problem:** Commands written but nothing happens  
**Solution:**
1. Check command ID is incrementing (must be > last ID)
2. Verify command syntax (uppercase, correct parameters)
3. Check Experts tab for execution logs
4. Wait at least SnapshotInterval seconds

**Problem:** "Invalid symbol" error  
**Solution:**
1. Open Market Watch (Ctrl+M)
2. Right-click → Show All
3. Find your symbol and ensure it's visible
4. Try symbol again

### Trading Errors

**Problem:** "Not enough money" error  
**Solution:**
1. Reduce position size (try 0.01 lots)
2. Check account balance in snapshot
3. Close existing positions to free margin

**Problem:** "Invalid stops" error  
**Solution:**
1. Check broker's stop level requirement
2. Place SL/TP further from current price
3. Use 0 for SL/TP to disable

---

## 📚 Next Steps

### Learn More
- Read [Experts/README.md](Experts/README.md) for detailed command reference
- Study [example_ai_integration.py](example_ai_integration.py) for complete AI example
- Review [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for architecture details

### Build Your AI
1. Start with simple strategy (e.g., moving average crossover)
2. Read snapshot every 3-5 seconds
3. Analyze market conditions
4. Send trading commands
5. Monitor results
6. Iterate and improve

### Example Simple AI Strategy

```python
def simple_trading_logic(snapshot):
    """Example: Buy when ask < 2400, sell when bid > 2410"""
    
    ask = snapshot['symbol_info']['ask']
    bid = snapshot['symbol_info']['bid']
    positions = len(snapshot['positions'])
    
    # No positions - look to enter
    if positions == 0:
        if ask < 2400:
            return "BUY 0.01"
    
    # Have position - look to exit
    else:
        if bid > 2410:
            return "CLOSE_ALL"
    
    return None  # No action

# Main loop
while True:
    snapshot = read_snapshot()
    command = simple_trading_logic(snapshot)
    
    if command:
        send_command(command)
    
    time.sleep(5)
```

---

## ⚠️ Important Reminders

### Safety First
- ✅ **Always use demo account**
- ✅ Test thoroughly before any live trading
- ✅ Implement proper risk management in your AI
- ✅ Monitor EA logs regularly
- ✅ Keep MT5 running and connected

### Best Practices
- Start with small position sizes (0.01 lots)
- Wait for snapshot updates between commands
- Increment command IDs properly
- Log all AI decisions for debugging
- Test each command type individually first

### Performance Tips
- Use SnapshotInterval = 3-5 seconds
- Don't read snapshot more than once per interval
- Batch related commands when possible
- Close positions you're not actively managing
- Monitor EA performance in Task Manager

---

## 🆘 Getting Help

### Resources
- **Documentation:** See README.md and Experts/README.md
- **Examples:** Check example_ai_integration.py
- **Logs:** Always check MT5 Experts tab first
- **Community:** GitHub Issues for bug reports

### Common Issues
Most problems are resolved by:
1. Checking Experts tab for errors
2. Verifying file paths are correct
3. Ensuring command IDs increment
4. Waiting for snapshot updates
5. Using correct command syntax

---

## ✅ Verification Checklist

Before building your AI, verify:

- [ ] EA compiles with 0 errors
- [ ] EA runs on chart (smiley face visible)
- [ ] AI_commands.txt exists and is writable
- [ ] AI_snapshot.json exists and updates
- [ ] Manual command test works (BUY 0.01)
- [ ] Python can read snapshot file
- [ ] Python can write command file
- [ ] Commands execute within 5 seconds
- [ ] Positions appear in snapshot
- [ ] Orders can be closed via command

---

## 🎉 You're Ready!

Congratulations! You now have a fully functional AI trading executor.

**What to do next:**
1. Experiment with different commands
2. Build your trading AI
3. Test extensively on demo
4. Iterate and improve
5. Share your results!

**Remember:** This EA gives your AI complete freedom. With great power comes great responsibility. Always use proper risk management and test thoroughly.

Happy trading! 🚀

---

**Last Updated:** 2025-11-13  
**Version:** 1.00  
**Support:** Open an issue on GitHub
