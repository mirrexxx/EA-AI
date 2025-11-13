#!/usr/bin/env python3
"""
AI Trading Integration Example for AI_Executor EA
==================================================

This example demonstrates how to integrate an external AI system with the
AI_Executor Expert Advisor for MetaTrader 5.

Features:
- Read market snapshots from EA
- Analyze market conditions
- Make trading decisions
- Send commands to EA
- Monitor position performance
- Implement basic risk management

Requirements:
- Python 3.7+
- AI_Executor.mq5 running in MT5
- Demo trading account

Usage:
1. Update the FILE_PATH_BASE variable with your MT5 Common Files path
2. Ensure AI_Executor EA is running in MT5
3. Run: python example_ai_integration.py

WARNING: This is a basic example for educational purposes.
         Do NOT use on live accounts without proper risk management!
"""

import json
import time
import os
from datetime import datetime
from typing import Dict, Optional, List

# =============================================================================
# CONFIGURATION
# =============================================================================

# Update this path to your MT5 Common Files folder!
# Windows example: r"C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\Common\Files"
FILE_PATH_BASE = r"C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\Common\Files"

COMMANDS_FILE = os.path.join(FILE_PATH_BASE, "AI_commands.txt")
SNAPSHOT_FILE = os.path.join(FILE_PATH_BASE, "AI_snapshot.json")

# Trading parameters
SYMBOL = "XAUUSD"              # Trading symbol
POSITION_SIZE = 0.01           # Lot size per trade
UPDATE_INTERVAL = 5            # Seconds between AI decisions
MAX_POSITIONS = 3              # Maximum simultaneous positions
TAKE_PROFIT_POINTS = 200       # Take profit distance in points
STOP_LOSS_POINTS = 100         # Stop loss distance in points

# =============================================================================
# AI TRADER CLASS
# =============================================================================

class AITrader:
    """
    AI Trading System that interfaces with AI_Executor EA.
    
    This class handles:
    - Reading market snapshots
    - Making trading decisions
    - Sending commands to EA
    - Position management
    - Risk control
    """
    
    def __init__(self, commands_file: str, snapshot_file: str):
        """
        Initialize AI Trader.
        
        Args:
            commands_file: Path to AI_commands.txt
            snapshot_file: Path to AI_snapshot.json
        """
        self.commands_file = commands_file
        self.snapshot_file = snapshot_file
        self.command_id = self._get_last_command_id() + 1
        self.last_snapshot = None
        self.running = False
        
        print("=" * 70)
        print("AI Trading System Initialized")
        print("=" * 70)
        print(f"Commands file: {commands_file}")
        print(f"Snapshot file: {snapshot_file}")
        print(f"Starting command ID: {self.command_id}")
        print("=" * 70)
    
    def _get_last_command_id(self) -> int:
        """Get the last command ID from commands file."""
        try:
            if os.path.exists(self.commands_file):
                with open(self.commands_file, 'r') as f:
                    lines = f.readlines()
                    if lines:
                        last_line = lines[-1].strip()
                        if last_line:
                            parts = last_line.split()
                            if parts:
                                return int(parts[0])
        except Exception as e:
            print(f"Warning: Could not read last command ID: {e}")
        return 0
    
    def read_snapshot(self) -> Optional[Dict]:
        """
        Read current market snapshot from EA.
        
        Returns:
            Dictionary with market data or None if error
        """
        try:
            with open(self.snapshot_file, 'r') as f:
                snapshot = json.load(f)
                self.last_snapshot = snapshot
                return snapshot
        except FileNotFoundError:
            print(f"Error: Snapshot file not found. Is EA running?")
            return None
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in snapshot: {e}")
            return None
        except Exception as e:
            print(f"Error reading snapshot: {e}")
            return None
    
    def send_command(self, command: str) -> bool:
        """
        Send a command to the EA.
        
        Args:
            command: Command string (without ID)
            
        Returns:
            True if command sent successfully
        """
        try:
            full_command = f"{self.command_id} {command}\n"
            with open(self.commands_file, 'a') as f:
                f.write(full_command)
            
            print(f"[{datetime.now().strftime('%H:%M:%S')}] CMD #{self.command_id}: {command}")
            self.command_id += 1
            return True
        except Exception as e:
            print(f"Error sending command: {e}")
            return False
    
    def set_symbol(self, symbol: str) -> bool:
        """Change the active trading symbol."""
        return self.send_command(f"SET_SYMBOL {symbol}")
    
    def open_buy(self, volume: float) -> bool:
        """Open a buy position."""
        return self.send_command(f"BUY {volume}")
    
    def open_sell(self, volume: float) -> bool:
        """Open a sell position."""
        return self.send_command(f"SELL {volume}")
    
    def close_position(self, ticket: int) -> bool:
        """Close a specific position by ticket."""
        return self.send_command(f"CLOSE_TICKET {ticket}")
    
    def close_all(self) -> bool:
        """Close all open positions."""
        return self.send_command("CLOSE_ALL")
    
    def modify_position(self, ticket: int, sl: float, tp: float) -> bool:
        """Modify position's stop loss and take profit."""
        return self.send_command(f"MODIFY {ticket} {sl} {tp}")
    
    def get_positions(self, snapshot: Dict) -> List[Dict]:
        """Extract positions list from snapshot."""
        return snapshot.get('positions', [])
    
    def get_account_info(self, snapshot: Dict) -> Dict:
        """Extract account information from snapshot."""
        return snapshot.get('account', {})
    
    def get_symbol_info(self, snapshot: Dict) -> Dict:
        """Extract symbol information from snapshot."""
        return snapshot.get('symbol_info', {})
    
    def display_status(self, snapshot: Dict):
        """Display current account and market status."""
        account = self.get_account_info(snapshot)
        symbol_info = self.get_symbol_info(snapshot)
        positions = self.get_positions(snapshot)
        
        print(f"\n{'─' * 70}")
        print(f"Time: {snapshot.get('server_time', 'N/A')}")
        print(f"Symbol: {snapshot.get('active_symbol', 'N/A')}")
        print(f"{'─' * 70}")
        print(f"Account Balance: ${account.get('balance', 0):.2f}")
        print(f"Account Equity:  ${account.get('equity', 0):.2f}")
        print(f"Used Margin:     ${account.get('margin', 0):.2f}")
        print(f"Floating P/L:    ${account.get('equity', 0) - account.get('balance', 0):.2f}")
        print(f"{'─' * 70}")
        print(f"Bid: {symbol_info.get('bid', 0):.5f}")
        print(f"Ask: {symbol_info.get('ask', 0):.5f}")
        print(f"Spread: {symbol_info.get('spread_points', 0)} points")
        print(f"{'─' * 70}")
        print(f"Open Positions: {len(positions)}")
        
        for pos in positions:
            pnl_symbol = "+" if pos['profit'] >= 0 else ""
            print(f"  #{pos['ticket']}: {pos['type']} {pos['volume']} @ {pos['price_open']:.5f}")
            print(f"    SL: {pos['sl']:.5f} | TP: {pos['tp']:.5f} | P/L: {pnl_symbol}${pos['profit']:.2f}")
        
        print(f"{'─' * 70}\n")

# =============================================================================
# SIMPLE AI TRADING STRATEGY
# =============================================================================

class SimpleAIStrategy:
    """
    Example AI trading strategy using simple moving average logic.
    
    This is a basic example for demonstration purposes.
    Real AI strategies would use machine learning, neural networks,
    reinforcement learning, or other advanced techniques.
    """
    
    def __init__(self, trader: AITrader):
        self.trader = trader
        self.price_history = []
        self.max_history = 20
    
    def analyze_market(self, snapshot: Dict) -> Optional[str]:
        """
        Analyze market conditions and make trading decision.
        
        Args:
            snapshot: Current market snapshot
            
        Returns:
            Trading decision: "BUY", "SELL", "CLOSE_ALL", or None
        """
        symbol_info = snapshot.get('symbol_info', {})
        positions = snapshot.get('positions', [])
        account = snapshot.get('account', {})
        
        bid = symbol_info.get('bid', 0)
        ask = symbol_info.get('ask', 0)
        
        if bid == 0 or ask == 0:
            return None
        
        # Update price history
        mid_price = (bid + ask) / 2
        self.price_history.append(mid_price)
        if len(self.price_history) > self.max_history:
            self.price_history.pop(0)
        
        # Need enough history
        if len(self.price_history) < 10:
            return None
        
        # Calculate simple moving averages
        sma_short = sum(self.price_history[-5:]) / 5
        sma_long = sum(self.price_history[-10:]) / 10
        
        # Check position limit
        if len(positions) >= MAX_POSITIONS:
            return None
        
        # Simple strategy: Buy when short MA crosses above long MA
        if len(self.price_history) >= 2:
            prev_short = sum(self.price_history[-6:-1]) / 5
            prev_long = sum(self.price_history[-11:-1]) / 10
            
            # Bullish crossover
            if prev_short <= prev_long and sma_short > sma_long:
                if len(positions) == 0:
                    return "BUY"
            
            # Bearish crossover
            elif prev_short >= prev_long and sma_short < sma_long:
                if len(positions) > 0:
                    return "CLOSE_ALL"
        
        return None
    
    def manage_positions(self, snapshot: Dict):
        """
        Manage existing positions (set SL/TP, close losing trades, etc.)
        
        Args:
            snapshot: Current market snapshot
        """
        positions = snapshot.get('positions', [])
        symbol_info = snapshot.get('symbol_info', {})
        
        bid = symbol_info.get('bid', 0)
        ask = symbol_info.get('ask', 0)
        
        for pos in positions:
            ticket = pos['ticket']
            pos_type = pos['type']
            open_price = pos['price_open']
            current_sl = pos['sl']
            current_tp = pos['tp']
            
            # Set SL/TP if not already set
            if current_sl == 0 or current_tp == 0:
                if pos_type == "BUY":
                    sl = open_price - (STOP_LOSS_POINTS * 0.0001)  # Adjust point value per symbol
                    tp = open_price + (TAKE_PROFIT_POINTS * 0.0001)
                else:  # SELL
                    sl = open_price + (STOP_LOSS_POINTS * 0.0001)
                    tp = open_price - (TAKE_PROFIT_POINTS * 0.0001)
                
                print(f"Setting SL/TP for position #{ticket}")
                self.trader.modify_position(ticket, sl, tp)

# =============================================================================
# MAIN EXECUTION
# =============================================================================

def main():
    """Main execution function."""
    
    # Verify files exist
    if not os.path.exists(SNAPSHOT_FILE):
        print("=" * 70)
        print("ERROR: Snapshot file not found!")
        print("=" * 70)
        print(f"Expected location: {SNAPSHOT_FILE}")
        print("\nPlease ensure:")
        print("1. AI_Executor EA is running in MetaTrader 5")
        print("2. FILE_PATH_BASE variable is set correctly")
        print("3. MT5 terminal is connected to server")
        print("=" * 70)
        return
    
    # Initialize AI trader
    trader = AITrader(COMMANDS_FILE, SNAPSHOT_FILE)
    strategy = SimpleAIStrategy(trader)
    
    # Set initial symbol
    print(f"\nSetting active symbol to {SYMBOL}...")
    trader.set_symbol(SYMBOL)
    time.sleep(3)
    
    print(f"\nStarting AI trading loop...")
    print(f"Update interval: {UPDATE_INTERVAL} seconds")
    print(f"Position size: {POSITION_SIZE} lots")
    print(f"Max positions: {MAX_POSITIONS}")
    print(f"Press Ctrl+C to stop\n")
    
    iteration = 0
    
    try:
        while True:
            iteration += 1
            
            # Read current market state
            snapshot = trader.read_snapshot()
            if not snapshot:
                print("Warning: Could not read snapshot, retrying...")
                time.sleep(UPDATE_INTERVAL)
                continue
            
            # Display status every 5 iterations
            if iteration % 5 == 1:
                trader.display_status(snapshot)
            
            # Manage existing positions
            strategy.manage_positions(snapshot)
            
            # Make trading decision
            decision = strategy.analyze_market(snapshot)
            
            if decision == "BUY":
                print(f"[AI DECISION] Opening BUY position ({POSITION_SIZE} lots)")
                trader.open_buy(POSITION_SIZE)
            
            elif decision == "SELL":
                print(f"[AI DECISION] Opening SELL position ({POSITION_SIZE} lots)")
                trader.open_sell(POSITION_SIZE)
            
            elif decision == "CLOSE_ALL":
                print(f"[AI DECISION] Closing all positions")
                trader.close_all()
            
            # Wait before next iteration
            time.sleep(UPDATE_INTERVAL)
    
    except KeyboardInterrupt:
        print("\n\n" + "=" * 70)
        print("AI Trading System Stopped by User")
        print("=" * 70)
        
        # Display final status
        snapshot = trader.read_snapshot()
        if snapshot:
            trader.display_status(snapshot)
        
        # Optional: Close all positions on exit
        response = input("\nClose all open positions? (y/n): ")
        if response.lower() == 'y':
            trader.close_all()
            print("Closing all positions...")
            time.sleep(3)
            snapshot = trader.read_snapshot()
            if snapshot:
                trader.display_status(snapshot)
        
        print("\nThank you for using AI Trading System!")
    
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        print("AI Trading System terminated with error")

# =============================================================================
# ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    print("""
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                                                                   ║
    ║        AI Trading Integration Example for MT5                    ║
    ║        ──────────────────────────────────────                    ║
    ║                                                                   ║
    ║        This is a demonstration of AI-driven trading              ║
    ║        using the AI_Executor Expert Advisor.                     ║
    ║                                                                   ║
    ║        ⚠️  USE ONLY ON DEMO ACCOUNTS ⚠️                          ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝
    """)
    
    # Check if user has updated the file path
    if "YourName" in FILE_PATH_BASE:
        print("\n⚠️  WARNING: You need to update FILE_PATH_BASE variable!")
        print("\nPlease edit this file and set FILE_PATH_BASE to your MT5 Common Files folder.")
        print("\nExample:")
        print('FILE_PATH_BASE = r"C:\\Users\\John\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files"')
        print("\nTo find your path:")
        print("1. Open MT5")
        print("2. Open MetaEditor (F4)")
        print("3. File → Open Data Folder")
        print("4. Go up to Terminal folder, then Common\\Files\\")
        print()
    else:
        main()
