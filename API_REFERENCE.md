# API Reference: EA Executor Commands

Complete reference for all commands supported by AI_Executor EA.

## Command Format

All commands follow the format:
```
<ID> <COMMAND> [param1] [param2] ...
```

- **ID**: Unique, incrementing integer. EA only executes commands with ID > last executed ID.
- **COMMAND**: Command name (case-sensitive)
- **Parameters**: Space-separated parameters specific to each command

## Trading Commands

### BUY
Open a market buy position on the current symbol.

**Syntax:**
```
<ID> BUY <volume>
```

**Parameters:**
- `volume`: Lot size (e.g., 0.01, 0.10, 1.00)

**Example:**
```
1 BUY 0.10
```

Opens a 0.10 lot buy position at current ask price.

---

### SELL
Open a market sell position on the current symbol.

**Syntax:**
```
<ID> SELL <volume>
```

**Parameters:**
- `volume`: Lot size (e.g., 0.01, 0.10, 1.00)

**Example:**
```
2 SELL 0.05
```

Opens a 0.05 lot sell position at current bid price.

---

### BUY_LIMIT
Place a pending buy limit order.

**Syntax:**
```
<ID> BUY_LIMIT <volume> <price>
```

**Parameters:**
- `volume`: Lot size
- `price`: Limit price (must be below current ask)

**Example:**
```
3 BUY_LIMIT 0.10 1.12000
```

Places a buy limit order at 1.12000 for 0.10 lots.

---

### SELL_LIMIT
Place a pending sell limit order.

**Syntax:**
```
<ID> SELL_LIMIT <volume> <price>
```

**Parameters:**
- `volume`: Lot size
- `price`: Limit price (must be above current bid)

**Example:**
```
4 SELL_LIMIT 0.10 1.12500
```

Places a sell limit order at 1.12500 for 0.10 lots.

---

### BUY_STOP
Place a pending buy stop order.

**Syntax:**
```
<ID> BUY_STOP <volume> <price>
```

**Parameters:**
- `volume`: Lot size
- `price`: Stop price (must be above current ask)

**Example:**
```
5 BUY_STOP 0.10 1.12800
```

Places a buy stop order at 1.12800 for 0.10 lots.

---

### SELL_STOP
Place a pending sell stop order.

**Syntax:**
```
<ID> SELL_STOP <volume> <price>
```

**Parameters:**
- `volume`: Lot size
- `price`: Stop price (must be below current bid)

**Example:**
```
6 SELL_STOP 0.10 1.11800
```

Places a sell stop order at 1.11800 for 0.10 lots.

---

## Position Management Commands

### MODIFY_SLTP
Modify stop loss and take profit for an open position.

**Syntax:**
```
<ID> MODIFY_SLTP <ticket> <sl> <tp>
```

**Parameters:**
- `ticket`: Position ticket number
- `sl`: New stop loss price (0 = no stop loss)
- `tp`: New take profit price (0 = no take profit)

**Example:**
```
7 MODIFY_SLTP 123456 1.11500 1.12800
```

Sets SL to 1.11500 and TP to 1.12800 for position #123456.

---

### CLOSE_TICKET
Close a specific position by ticket number.

**Syntax:**
```
<ID> CLOSE_TICKET <ticket>
```

**Parameters:**
- `ticket`: Position ticket number to close

**Example:**
```
8 CLOSE_TICKET 123456
```

Closes position #123456.

---

### CLOSE_SYMBOL
Close all positions for a specific symbol.

**Syntax:**
```
<ID> CLOSE_SYMBOL <symbol>
```

**Parameters:**
- `symbol`: Symbol name (e.g., EURUSD, GBPUSD)

**Example:**
```
9 CLOSE_SYMBOL EURUSD
```

Closes all open EURUSD positions.

---

### CLOSE_ALL
Close all open positions across all symbols.

**Syntax:**
```
<ID> CLOSE_ALL
```

**Parameters:** None

**Example:**
```
10 CLOSE_ALL
```

Closes all open positions.

---

## Configuration Commands

### SET_SYMBOL
Change the active symbol for subsequent trading commands.

**Syntax:**
```
<ID> SET_SYMBOL <symbol>
```

**Parameters:**
- `symbol`: Symbol name (must be available in Market Watch)

**Example:**
```
11 SET_SYMBOL XAUUSD
```

Changes active symbol to Gold (XAUUSD). Subsequent BUY/SELL commands will trade this symbol.

---

## Snapshot File Format

EA writes market state to `AI_snapshot.json` every timer interval.

### JSON Structure

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
  "pending_orders": [
    {
      "ticket": 123458,
      "symbol": "EURUSD",
      "type": "BUY_LIMIT",
      "volume": 0.10,
      "price": 1.12000,
      "sl": 1.11800,
      "tp": 1.12300
    }
  ],
  "timestamp": "2025.11.13 14:30:00"
}
```

### Field Descriptions

#### Account Object
- `balance`: Account balance in deposit currency
- `equity`: Current equity (balance + floating profit/loss)
- `margin`: Margin used by open positions
- `free_margin`: Available margin for new positions
- `margin_level`: Margin level percentage (equity/margin * 100)
- `profit`: Total floating profit/loss

#### Current Symbol Object
- `name`: Symbol name
- `bid`: Current bid price
- `ask`: Current ask price
- `spread`: Current spread in points

#### Position Object
- `ticket`: Unique position identifier
- `symbol`: Symbol being traded
- `type`: "BUY" or "SELL"
- `volume`: Position size in lots
- `open_price`: Entry price
- `sl`: Stop loss price (0 if not set)
- `tp`: Take profit price (0 if not set)
- `profit`: Current profit/loss

#### Pending Order Object
- `ticket`: Unique order identifier
- `symbol`: Symbol for the order
- `type`: Order type ("BUY_LIMIT", "SELL_LIMIT", "BUY_STOP", "SELL_STOP")
- `volume`: Order size in lots
- `price`: Order trigger price
- `sl`: Stop loss price (0 if not set)
- `tp`: Take profit price (0 if not set)

---

## Error Handling

EA logs all actions and errors to MT5 Expert journal. Check the journal for:
- Command execution results
- Order placement confirmations
- Error messages and codes

Common error codes:
- `10004`: Requote
- `10006`: Request rejected
- `10007`: Request cancelled
- `10013`: Invalid request
- `10014`: Invalid volume
- `10015`: Invalid price
- `10016`: Invalid stops

---

## Best Practices

1. **Command IDs**: Always increment IDs. Reusing an ID will cause the command to be ignored.

2. **Volume Validation**: Check broker's minimum lot size and lot step before sending commands.

3. **Price Validation**: Ensure limit/stop prices are valid:
   - Buy Limit: price < current ask
   - Sell Limit: price > current bid
   - Buy Stop: price > current ask
   - Sell Stop: price < current bid

4. **Stop Levels**: Respect broker's stop level (minimum distance from current price for SL/TP).

5. **Margin Checks**: Monitor `free_margin` before opening new positions.

6. **Error Recovery**: Check snapshot file to verify command execution before sending next command.

7. **Rate Limiting**: Don't send commands too frequently. Wait at least 1 timer interval between commands.

---

## Example Trading Sequence

```
# Switch to EURUSD
1 SET_SYMBOL EURUSD

# Open buy position
2 BUY 0.10

# Wait for position to open (check snapshot for ticket number)

# Set stop loss and take profit
3 MODIFY_SLTP 123456 1.11500 1.12800

# If profit target reached or stop hit, position closes automatically
# Or close manually
4 CLOSE_TICKET 123456

# Emergency: close everything
5 CLOSE_ALL
```

---

## Integration Notes

When building an AI agent:

1. Read `AI_snapshot.json` to get current state
2. Analyze market conditions
3. Make trading decision
4. Append command to `AI_commands.txt` with next ID
5. Wait for EA to execute (check next snapshot)
6. Repeat cycle

**Important**: Each command execution is atomic. Wait for confirmation in snapshot before sending dependent commands.
