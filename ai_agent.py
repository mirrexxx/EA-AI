#!/usr/bin/env python3
"""
AI Trading Agent
This script reads market state from AI_snapshot.json,
makes trading decisions using AI/LLM, and writes commands to AI_commands.txt
"""

import json
import time
import os
from datetime import datetime
from pathlib import Path

# Configuration
SNAPSHOT_FILE = "AI_snapshot.json"
COMMANDS_FILE = "AI_commands.txt"
CHECK_INTERVAL = 5  # seconds
MT5_COMMON_PATH = None  # Will be auto-detected or set manually

class AITradingAgent:
    def __init__(self):
        self.command_counter = 0
        self.last_snapshot_time = None
        self.setup_paths()
        
    def setup_paths(self):
        """Setup file paths for MT5 terminal common files folder"""
        # Try to detect MT5 common folder
        # Windows: C:\Users\<username>\AppData\Roaming\MetaQuotes\Terminal\Common\Files
        # Wine: ~/.wine/drive_c/users/<username>/AppData/Roaming/MetaQuotes/Terminal/Common/Files
        
        global MT5_COMMON_PATH
        
        if MT5_COMMON_PATH:
            self.snapshot_path = Path(MT5_COMMON_PATH) / SNAPSHOT_FILE
            self.commands_path = Path(MT5_COMMON_PATH) / COMMANDS_FILE
            return
            
        # Try common locations
        possible_paths = []
        
        # Windows
        appdata = os.environ.get('APPDATA')
        if appdata:
            possible_paths.append(Path(appdata) / "MetaQuotes" / "Terminal" / "Common" / "Files")
        
        # Wine
        home = Path.home()
        wine_path = home / ".wine" / "drive_c" / "users" / os.environ.get('USER', 'user') / "AppData" / "Roaming" / "MetaQuotes" / "Terminal" / "Common" / "Files"
        if wine_path.exists():
            possible_paths.append(wine_path)
        
        # Check which path exists
        for path in possible_paths:
            if path.exists():
                MT5_COMMON_PATH = str(path)
                self.snapshot_path = path / SNAPSHOT_FILE
                self.commands_path = path / COMMANDS_FILE
                print(f"Using MT5 common files path: {MT5_COMMON_PATH}")
                return
        
        # Fallback to current directory
        print("Warning: Could not auto-detect MT5 common files path. Using current directory.")
        print("Set MT5_COMMON_PATH variable if files are in a different location.")
        self.snapshot_path = Path(SNAPSHOT_FILE)
        self.commands_path = Path(COMMANDS_FILE)
    
    def read_snapshot(self):
        """Read the current market state from snapshot file"""
        try:
            if not self.snapshot_path.exists():
                print(f"Snapshot file not found: {self.snapshot_path}")
                return None
                
            with open(self.snapshot_path, 'r') as f:
                data = json.load(f)
                self.last_snapshot_time = data.get('timestamp')
                return data
        except Exception as e:
            print(f"Error reading snapshot: {e}")
            return None
    
    def write_command(self, command):
        """Write a command to the commands file"""
        try:
            self.command_counter += 1
            command_line = f"{self.command_counter} {command}\n"
            
            with open(self.commands_path, 'a') as f:
                f.write(command_line)
            
            print(f"Command written: {command_line.strip()}")
            return True
        except Exception as e:
            print(f"Error writing command: {e}")
            return False
    
    def analyze_market(self, snapshot):
        """
        Analyze market data and make trading decision
        
        This is where AI/LLM integration would happen.
        For now, this is a placeholder that demonstrates the structure.
        
        In a real implementation, you would:
        1. Send snapshot data to LLM (OpenAI, Claude, etc.)
        2. Let LLM analyze market conditions
        3. LLM returns trading decision
        4. Parse and validate the decision
        """
        
        if not snapshot:
            return None
        
        account = snapshot.get('account', {})
        current_symbol = snapshot.get('current_symbol', {})
        positions = snapshot.get('positions', [])
        pending_orders = snapshot.get('pending_orders', [])
        
        # Example logic (placeholder for AI)
        # In real implementation, this would be replaced with LLM API call
        
        print("\n" + "="*60)
        print(f"Market Analysis - {snapshot.get('timestamp')}")
        print("="*60)
        print(f"Account Balance: {account.get('balance')}")
        print(f"Account Equity: {account.get('equity')}")
        print(f"Account Profit: {account.get('profit')}")
        print(f"Current Symbol: {current_symbol.get('name')}")
        print(f"Bid/Ask: {current_symbol.get('bid')}/{current_symbol.get('ask')}")
        print(f"Open Positions: {len(positions)}")
        print(f"Pending Orders: {len(pending_orders)}")
        
        # Display positions
        if positions:
            print("\nOpen Positions:")
            for pos in positions:
                print(f"  - Ticket {pos['ticket']}: {pos['type']} {pos['volume']} {pos['symbol']} @ {pos['open_price']}, Profit: {pos['profit']}")
        
        # Display pending orders
        if pending_orders:
            print("\nPending Orders:")
            for order in pending_orders:
                print(f"  - Ticket {order['ticket']}: {order['type']} {order['volume']} {order['symbol']} @ {order['price']}")
        
        print("="*60)
        
        # TODO: Replace this with actual AI/LLM decision making
        # For now, return None (no action)
        return None
    
    def make_ai_decision(self, snapshot):
        """
        Interface for AI/LLM to make trading decisions
        
        This function should:
        1. Prepare context for LLM
        2. Call LLM API with market data
        3. Parse LLM response
        4. Return trading command
        
        Example LLM prompt structure:
        '''
        You are a trading AI. Analyze the following market data and decide on an action.
        
        Account State:
        - Balance: {balance}
        - Equity: {equity}
        - Open Positions: {positions}
        
        Current Market:
        - Symbol: {symbol}
        - Bid: {bid}
        - Ask: {ask}
        
        Available commands:
        - BUY <volume>
        - SELL <volume>
        - CLOSE_TICKET <ticket>
        - CLOSE_ALL
        - SET_SYMBOL <symbol>
        - etc.
        
        Respond with ONLY the command to execute, or "NO_ACTION" if no action is needed.
        '''
        """
        
        # Placeholder for AI decision
        # In production, this would call OpenAI/Claude/etc API
        
        decision = self.analyze_market(snapshot)
        
        # Example: Simple decision logic (replace with AI)
        # This is just to demonstrate the concept
        
        return decision
    
    def run(self):
        """Main execution loop"""
        print("AI Trading Agent started")
        print(f"Snapshot file: {self.snapshot_path}")
        print(f"Commands file: {self.commands_path}")
        print(f"Check interval: {CHECK_INTERVAL} seconds")
        print("\nWaiting for snapshot file from EA...")
        print("Press Ctrl+C to stop\n")
        
        try:
            while True:
                # Read market snapshot
                snapshot = self.read_snapshot()
                
                if snapshot:
                    # Make AI decision
                    command = self.make_ai_decision(snapshot)
                    
                    # Execute command if AI decided to act
                    if command:
                        self.write_command(command)
                
                # Wait before next check
                time.sleep(CHECK_INTERVAL)
                
        except KeyboardInterrupt:
            print("\n\nAgent stopped by user")
        except Exception as e:
            print(f"\n\nAgent error: {e}")


def demo_mode():
    """
    Demo mode - shows example commands without actually trading
    Useful for testing the system
    """
    print("Running in DEMO mode")
    print("This will show example commands but not execute them\n")
    
    agent = AITradingAgent()
    
    # Example commands
    examples = [
        "BUY 0.10",
        "SELL 0.10",
        "BUY_LIMIT 0.10 1.2000",
        "SELL_LIMIT 0.10 1.2100",
        "SET_SYMBOL EURUSD",
        "CLOSE_ALL",
    ]
    
    print("Example commands that can be sent:")
    for i, cmd in enumerate(examples, 1):
        print(f"{i}. {cmd}")
    
    print("\nThese commands would be written to:", agent.commands_path)


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        demo_mode()
    else:
        agent = AITradingAgent()
        agent.run()
