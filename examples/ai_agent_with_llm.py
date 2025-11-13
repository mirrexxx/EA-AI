#!/usr/bin/env python3
"""
Advanced AI Trading Agent with LLM Integration
This is an example of how to integrate LLM (OpenAI, Claude, etc.) with the trading system
"""

import json
import time
import os
from datetime import datetime
from pathlib import Path

# Uncomment and configure based on your LLM provider
# from openai import OpenAI
# import anthropic

# Configuration
SNAPSHOT_FILE = "AI_snapshot.json"
COMMANDS_FILE = "AI_commands.txt"
CHECK_INTERVAL = 5  # seconds
MT5_COMMON_PATH = None  # Will be auto-detected

# LLM Configuration
# OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
# ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")


class LLMTradingAgent:
    def __init__(self):
        self.command_counter = 0
        self.last_snapshot_time = None
        self.trading_history = []
        self.setup_paths()
        # self.setup_llm()
        
    def setup_paths(self):
        """Setup file paths for MT5 terminal common files folder"""
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
        self.snapshot_path = Path(SNAPSHOT_FILE)
        self.commands_path = Path(COMMANDS_FILE)
    
    def setup_llm(self):
        """Initialize LLM client"""
        # Example for OpenAI
        # self.llm_client = OpenAI(api_key=OPENAI_API_KEY)
        
        # Example for Anthropic Claude
        # self.llm_client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)
        
        pass
    
    def read_snapshot(self):
        """Read the current market state from snapshot file"""
        try:
            if not self.snapshot_path.exists():
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
            
            print(f"✓ Command written: {command_line.strip()}")
            self.trading_history.append({
                'id': self.command_counter,
                'command': command,
                'timestamp': datetime.now().isoformat()
            })
            return True
        except Exception as e:
            print(f"✗ Error writing command: {e}")
            return False
    
    def build_llm_prompt(self, snapshot):
        """Build a comprehensive prompt for the LLM"""
        account = snapshot.get('account', {})
        current_symbol = snapshot.get('current_symbol', {})
        positions = snapshot.get('positions', [])
        pending_orders = snapshot.get('pending_orders', [])
        
        prompt = f"""You are an expert trading AI analyzing the forex market. Your goal is to make profitable trading decisions.

CURRENT MARKET STATE:
====================

Account Information:
- Balance: ${account.get('balance', 0):.2f}
- Equity: ${account.get('equity', 0):.2f}
- Margin Used: ${account.get('margin', 0):.2f}
- Free Margin: ${account.get('free_margin', 0):.2f}
- Current Profit/Loss: ${account.get('profit', 0):.2f}
- Margin Level: {account.get('margin_level', 0):.2f}%

Active Symbol: {current_symbol.get('name', 'UNKNOWN')}
- Bid: {current_symbol.get('bid', 0):.5f}
- Ask: {current_symbol.get('ask', 0):.5f}
- Spread: {current_symbol.get('spread', 0)} points

Open Positions ({len(positions)}):
"""
        
        if positions:
            for pos in positions:
                prompt += f"""
- Ticket #{pos['ticket']}: {pos['type']} {pos['volume']} {pos['symbol']}
  Entry: {pos['open_price']:.5f} | SL: {pos['sl']:.5f} | TP: {pos['tp']:.5f} | P/L: ${pos['profit']:.2f}
"""
        else:
            prompt += "\n- No open positions\n"
        
        prompt += f"\nPending Orders ({len(pending_orders)}):\n"
        
        if pending_orders:
            for order in pending_orders:
                prompt += f"""
- Ticket #{order['ticket']}: {order['type']} {order['volume']} {order['symbol']} @ {order['price']:.5f}
  SL: {order['sl']:.5f} | TP: {order['tp']:.5f}
"""
        else:
            prompt += "- No pending orders\n"
        
        prompt += """

AVAILABLE COMMANDS:
==================
- BUY <volume> - Open buy position on current symbol
- SELL <volume> - Open sell position on current symbol
- BUY_LIMIT <volume> <price> - Place buy limit order
- SELL_LIMIT <volume> <price> - Place sell limit order
- BUY_STOP <volume> <price> - Place buy stop order
- SELL_STOP <volume> <price> - Place sell stop order
- MODIFY_SLTP <ticket> <sl> <tp> - Modify stop loss and take profit
- CLOSE_TICKET <ticket> - Close specific position
- CLOSE_SYMBOL <symbol> - Close all positions for a symbol
- CLOSE_ALL - Close all positions
- SET_SYMBOL <symbol> - Change active symbol (e.g., EURUSD, GBPUSD, XAUUSD)
- NO_ACTION - Take no action this cycle

TRADING RULES:
==============
1. Risk management: Never risk more than 2% per trade
2. Use stop losses on all positions
3. Consider market conditions and trends
4. Don't overtrade - quality over quantity
5. Protect profits by adjusting stop losses

TASK:
=====
Analyze the current market state and decide on the SINGLE BEST action to take right now.
Consider:
- Current market trend
- Open positions and their performance
- Available margin
- Risk/reward ratio
- Market volatility

Respond with ONLY the command to execute (e.g., "BUY 0.10" or "CLOSE_TICKET 123456" or "NO_ACTION").
Do not include explanations or commentary - just the command.
"""
        
        return prompt
    
    def call_llm(self, prompt):
        """Call the LLM API to get trading decision"""
        
        # Example for OpenAI GPT
        """
        try:
            response = self.llm_client.chat.completions.create(
                model="gpt-4",  # or "gpt-3.5-turbo" for faster/cheaper
                messages=[
                    {"role": "system", "content": "You are an expert forex trading AI. Respond only with trading commands, no explanations."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=50,
                temperature=0.7
            )
            
            decision = response.choices[0].message.content.strip()
            return decision
            
        except Exception as e:
            print(f"LLM API error: {e}")
            return "NO_ACTION"
        """
        
        # Example for Anthropic Claude
        """
        try:
            response = self.llm_client.messages.create(
                model="claude-3-sonnet-20240229",
                max_tokens=50,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            
            decision = response.content[0].text.strip()
            return decision
            
        except Exception as e:
            print(f"LLM API error: {e}")
            return "NO_ACTION"
        """
        
        # Placeholder - replace with actual LLM call
        print("\n" + "="*60)
        print("LLM PROMPT:")
        print("="*60)
        print(prompt)
        print("="*60)
        print("\nWaiting for LLM response... (placeholder)")
        print("To enable LLM: Uncomment setup_llm() and call_llm() code")
        print("="*60 + "\n")
        
        return "NO_ACTION"
    
    def validate_command(self, command, snapshot):
        """Validate command before execution"""
        if not command or command == "NO_ACTION":
            return False
        
        parts = command.split()
        if not parts:
            return False
        
        cmd = parts[0]
        
        # Basic validation
        valid_commands = [
            "BUY", "SELL", "BUY_LIMIT", "SELL_LIMIT", 
            "BUY_STOP", "SELL_STOP", "MODIFY_SLTP",
            "CLOSE_TICKET", "CLOSE_SYMBOL", "CLOSE_ALL", "SET_SYMBOL"
        ]
        
        if cmd not in valid_commands:
            print(f"✗ Invalid command: {cmd}")
            return False
        
        # Safety checks
        account = snapshot.get('account', {})
        
        # Check if we have enough margin
        if cmd in ["BUY", "SELL", "BUY_LIMIT", "SELL_LIMIT", "BUY_STOP", "SELL_STOP"]:
            if account.get('free_margin', 0) < 100:
                print("✗ Insufficient free margin")
                return False
        
        # Check margin level
        if account.get('margin_level', 0) < 200 and account.get('margin_level', 0) > 0:
            if cmd in ["BUY", "SELL", "BUY_LIMIT", "SELL_LIMIT", "BUY_STOP", "SELL_STOP"]:
                print("✗ Margin level too low, not opening new positions")
                return False
        
        return True
    
    def check_safety_circuit_breaker(self, snapshot):
        """Emergency stop - circuit breaker"""
        account = snapshot.get('account', {})
        
        balance = account.get('balance', 0)
        equity = account.get('equity', 0)
        
        # Stop trading if drawdown exceeds 10%
        if equity < balance * 0.9:
            print("\n⚠️  CIRCUIT BREAKER ACTIVATED ⚠️")
            print(f"Drawdown exceeds 10% ({((balance - equity) / balance * 100):.2f}%)")
            print("Closing all positions...")
            self.write_command("CLOSE_ALL")
            return False
        
        # Stop if margin level is critical
        margin_level = account.get('margin_level', 0)
        if 0 < margin_level < 150:
            print("\n⚠️  CIRCUIT BREAKER ACTIVATED ⚠️")
            print(f"Margin level critical: {margin_level:.2f}%")
            print("Closing all positions...")
            self.write_command("CLOSE_ALL")
            return False
        
        return True
    
    def run(self):
        """Main execution loop"""
        print("="*60)
        print("AI Trading Agent with LLM Integration")
        print("="*60)
        print(f"Snapshot file: {self.snapshot_path}")
        print(f"Commands file: {self.commands_path}")
        print(f"Check interval: {CHECK_INTERVAL} seconds")
        print("\n⚠️  WARNING: This system can trade automatically!")
        print("Make sure you are using a DEMO account!")
        print("\nPress Ctrl+C to stop\n")
        print("="*60 + "\n")
        
        try:
            while True:
                # Read market snapshot
                snapshot = self.read_snapshot()
                
                if snapshot:
                    # Check circuit breaker first
                    if not self.check_safety_circuit_breaker(snapshot):
                        print("Circuit breaker active, waiting...")
                        time.sleep(CHECK_INTERVAL * 6)  # Wait longer before next check
                        continue
                    
                    # Build prompt for LLM
                    prompt = self.build_llm_prompt(snapshot)
                    
                    # Get decision from LLM
                    decision = self.call_llm(prompt)
                    
                    print(f"\nLLM Decision: {decision}")
                    
                    # Validate and execute
                    if self.validate_command(decision, snapshot):
                        self.write_command(decision)
                    else:
                        if decision != "NO_ACTION":
                            print("Command validation failed, skipping")
                
                # Wait before next check
                time.sleep(CHECK_INTERVAL)
                
        except KeyboardInterrupt:
            print("\n\nAgent stopped by user")
            print(f"Total commands issued: {self.command_counter}")
        except Exception as e:
            print(f"\n\nAgent error: {e}")
            import traceback
            traceback.print_exc()


if __name__ == "__main__":
    import sys
    
    print("\n" + "="*60)
    print("IMPORTANT: Configure your LLM API keys before running!")
    print("="*60)
    print("1. Uncomment LLM provider imports at top of file")
    print("2. Set API keys in environment variables or .env file")
    print("3. Uncomment setup_llm() and call_llm() code")
    print("4. Test on DEMO account first!")
    print("="*60 + "\n")
    
    if "--demo" in sys.argv:
        print("Demo mode - showing structure only, not trading")
        # Could show example prompts/responses here
    else:
        agent = LLMTradingAgent()
        agent.run()
