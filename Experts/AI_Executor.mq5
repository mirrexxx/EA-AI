//+------------------------------------------------------------------+
//|                                                  AI_Executor.mq5 |
//|                                    Full Autonomous AI Trading EA |
//|                                      https://github.com/mirrexxx |
//+------------------------------------------------------------------+
#property copyright "mirrexxx"
#property link      "https://github.com/mirrexxx/EA-AI"
#property version   "1.00"
#property description "Autonomous AI Trading Executor - Provides complete trading freedom to external AI"
#property strict

//--- Input parameters
input int SnapshotInterval = 3;  // Snapshot update interval (seconds)

//--- Global variables
string activeSymbol;              // Current active trading symbol
int lastCommandID = -1;           // Last processed command ID
string commandFilePath;           // Full path to AI_commands.txt
string snapshotFilePath;          // Full path to AI_snapshot.json

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Set active symbol to current chart symbol
   activeSymbol = _Symbol;
   
   //--- Setup file paths in terminal's common data folder
   string terminalDataPath = TerminalInfoString(TERMINAL_COMMONDATA_PATH);
   commandFilePath = terminalDataPath + "\\MQL5\\Files\\AI_commands.txt";
   snapshotFilePath = terminalDataPath + "\\MQL5\\Files\\AI_snapshot.json";
   
   //--- Create AI_commands.txt if it doesn't exist
   int cmdFileHandle = FileOpen("AI_commands.txt", FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(cmdFileHandle != INVALID_HANDLE)
   {
      FileWriteString(cmdFileHandle, "0 INIT\n");
      FileClose(cmdFileHandle);
      Print("AI_commands.txt created at: ", commandFilePath);
   }
   else
   {
      Print("Warning: Could not create AI_commands.txt. Error: ", GetLastError());
   }
   
   //--- Set timer for snapshot updates
   if(!EventSetTimer(SnapshotInterval))
   {
      Print("Error: Failed to set timer. Error: ", GetLastError());
      return(INIT_FAILED);
   }
   
   Print("AI_Executor initialized successfully");
   Print("Active symbol: ", activeSymbol);
   Print("Snapshot interval: ", SnapshotInterval, " seconds");
   Print("Command file: ", commandFilePath);
   Print("Snapshot file: ", snapshotFilePath);
   
   //--- Create initial snapshot
   CreateSnapshot();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Kill the timer
   EventKillTimer();
   Print("AI_Executor stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Timer function                                                     |
//+------------------------------------------------------------------+
void OnTimer()
{
   //--- Read and process commands from AI
   ProcessCommands();
   
   //--- Update snapshot for AI
   CreateSnapshot();
}

//+------------------------------------------------------------------+
//| Process commands from AI_commands.txt                             |
//+------------------------------------------------------------------+
void ProcessCommands()
{
   //--- Open command file for reading
   int fileHandle = FileOpen("AI_commands.txt", FILE_READ|FILE_TXT|FILE_COMMON);
   if(fileHandle == INVALID_HANDLE)
   {
      Print("Warning: Cannot open AI_commands.txt for reading. Error: ", GetLastError());
      return;
   }
   
   //--- Read all lines and get the last one
   string lastLine = "";
   while(!FileIsEnding(fileHandle))
   {
      string line = FileReadString(fileHandle);
      if(StringLen(line) > 0)
         lastLine = line;
   }
   FileClose(fileHandle);
   
   //--- Parse and execute command if it's new
   if(StringLen(lastLine) > 0)
   {
      string parts[];
      int count = StringSplit(lastLine, ' ', parts);
      
      if(count >= 2)
      {
         int commandID = (int)StringToInteger(parts[0]);
         
         //--- Check if this is a new command
         if(commandID > lastCommandID)
         {
            lastCommandID = commandID;
            string command = parts[1];
            
            Print("Processing command ID ", commandID, ": ", lastLine);
            ExecuteCommand(command, parts, count);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Execute trading command                                            |
//+------------------------------------------------------------------+
void ExecuteCommand(string command, string &parts[], int count)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   //--- SET_SYMBOL command
   if(command == "SET_SYMBOL" && count >= 3)
   {
      string newSymbol = parts[2];
      if(SymbolSelect(newSymbol, true))
      {
         activeSymbol = newSymbol;
         Print("Active symbol changed to: ", activeSymbol);
      }
      else
      {
         Print("Error: Symbol ", newSymbol, " not found or cannot be selected");
      }
      return;
   }
   
   //--- BUY command
   if(command == "BUY" && count >= 3)
   {
      double volume = StringToDouble(parts[2]);
      ExecuteMarketOrder(ORDER_TYPE_BUY, volume);
      return;
   }
   
   //--- SELL command
   if(command == "SELL" && count >= 3)
   {
      double volume = StringToDouble(parts[2]);
      ExecuteMarketOrder(ORDER_TYPE_SELL, volume);
      return;
   }
   
   //--- BUY_LIMIT command
   if(command == "BUY_LIMIT" && count >= 4)
   {
      double volume = StringToDouble(parts[2]);
      double price = StringToDouble(parts[3]);
      ExecutePendingOrder(ORDER_TYPE_BUY_LIMIT, volume, price);
      return;
   }
   
   //--- SELL_LIMIT command
   if(command == "SELL_LIMIT" && count >= 4)
   {
      double volume = StringToDouble(parts[2]);
      double price = StringToDouble(parts[3]);
      ExecutePendingOrder(ORDER_TYPE_SELL_LIMIT, volume, price);
      return;
   }
   
   //--- BUY_STOP command
   if(command == "BUY_STOP" && count >= 4)
   {
      double volume = StringToDouble(parts[2]);
      double price = StringToDouble(parts[3]);
      ExecutePendingOrder(ORDER_TYPE_BUY_STOP, volume, price);
      return;
   }
   
   //--- SELL_STOP command
   if(command == "SELL_STOP" && count >= 4)
   {
      double volume = StringToDouble(parts[2]);
      double price = StringToDouble(parts[3]);
      ExecutePendingOrder(ORDER_TYPE_SELL_STOP, volume, price);
      return;
   }
   
   //--- CLOSE_TICKET command
   if(command == "CLOSE_TICKET" && count >= 3)
   {
      ulong ticket = StringToInteger(parts[2]);
      ClosePosition(ticket);
      return;
   }
   
   //--- CLOSE_SYMBOL command
   if(command == "CLOSE_SYMBOL" && count >= 3)
   {
      string symbol = parts[2];
      CloseAllPositionsBySymbol(symbol);
      return;
   }
   
   //--- CLOSE_ALL command
   if(command == "CLOSE_ALL")
   {
      CloseAllPositions();
      return;
   }
   
   //--- SET_SL command
   if(command == "SET_SL" && count >= 4)
   {
      ulong ticket = StringToInteger(parts[2]);
      double sl = StringToDouble(parts[3]);
      ModifyPosition(ticket, sl, 0, true, false);
      return;
   }
   
   //--- SET_TP command
   if(command == "SET_TP" && count >= 4)
   {
      ulong ticket = StringToInteger(parts[2]);
      double tp = StringToDouble(parts[3]);
      ModifyPosition(ticket, 0, tp, false, true);
      return;
   }
   
   //--- MODIFY command
   if(command == "MODIFY" && count >= 5)
   {
      ulong ticket = StringToInteger(parts[2]);
      double sl = StringToDouble(parts[3]);
      double tp = StringToDouble(parts[4]);
      ModifyPosition(ticket, sl, tp, true, true);
      return;
   }
   
   //--- CANCEL_PENDING command
   if(command == "CANCEL_PENDING" && count >= 3)
   {
      ulong ticket = StringToInteger(parts[2]);
      CancelPendingOrder(ticket);
      return;
   }
   
   //--- CANCEL_ALL_PENDING command
   if(command == "CANCEL_ALL_PENDING")
   {
      CancelAllPendingOrders();
      return;
   }
   
   Print("Warning: Unknown or malformed command: ", command);
}

//+------------------------------------------------------------------+
//| Execute market order (BUY/SELL)                                   |
//+------------------------------------------------------------------+
void ExecuteMarketOrder(ENUM_ORDER_TYPE orderType, double volume)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = activeSymbol;
   request.volume = volume;
   request.type = orderType;
   request.deviation = 10;
   request.magic = 0;
   
   if(orderType == ORDER_TYPE_BUY)
      request.price = SymbolInfoDouble(activeSymbol, SYMBOL_ASK);
   else
      request.price = SymbolInfoDouble(activeSymbol, SYMBOL_BID);
   
   request.type_filling = ORDER_FILLING_FOK;
   
   if(!OrderSend(request, result))
   {
      //--- Try IOC filling if FOK failed
      request.type_filling = ORDER_FILLING_IOC;
      if(!OrderSend(request, result))
      {
         //--- Try RETURN filling
         request.type_filling = ORDER_FILLING_RETURN;
         OrderSend(request, result);
      }
   }
   
   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
   {
      Print("Market order executed: ", EnumToString(orderType), " ", volume, " lots of ", activeSymbol, 
            ". Ticket: ", result.order);
   }
   else
   {
      Print("Market order failed: ", result.retcode, " - ", result.comment);
   }
}

//+------------------------------------------------------------------+
//| Execute pending order                                              |
//+------------------------------------------------------------------+
void ExecutePendingOrder(ENUM_ORDER_TYPE orderType, double volume, double price)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_PENDING;
   request.symbol = activeSymbol;
   request.volume = volume;
   request.type = orderType;
   request.price = price;
   request.deviation = 0;
   request.magic = 0;
   request.type_filling = ORDER_FILLING_RETURN;
   
   if(!OrderSend(request, result))
   {
      Print("Pending order failed: ", result.retcode, " - ", result.comment);
   }
   else if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
   {
      Print("Pending order placed: ", EnumToString(orderType), " ", volume, " lots of ", activeSymbol,
            " at ", price, ". Ticket: ", result.order);
   }
   else
   {
      Print("Pending order failed: ", result.retcode, " - ", result.comment);
   }
}

//+------------------------------------------------------------------+
//| Close specific position by ticket                                  |
//+------------------------------------------------------------------+
void ClosePosition(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
   {
      Print("Position ", ticket, " not found");
      return;
   }
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = PositionGetString(POSITION_SYMBOL);
   request.volume = PositionGetDouble(POSITION_VOLUME);
   request.deviation = 10;
   request.magic = 0;
   
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(posType == POSITION_TYPE_BUY)
   {
      request.type = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(request.symbol, SYMBOL_BID);
   }
   else
   {
      request.type = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
   }
   
   request.type_filling = ORDER_FILLING_FOK;
   if(!OrderSend(request, result))
   {
      request.type_filling = ORDER_FILLING_IOC;
      if(!OrderSend(request, result))
      {
         request.type_filling = ORDER_FILLING_RETURN;
         OrderSend(request, result);
      }
   }
   
   if(result.retcode == TRADE_RETCODE_DONE)
   {
      Print("Position ", ticket, " closed successfully");
   }
   else
   {
      Print("Failed to close position ", ticket, ": ", result.retcode, " - ", result.comment);
   }
}

//+------------------------------------------------------------------+
//| Close all positions for specific symbol                           |
//+------------------------------------------------------------------+
void CloseAllPositionsBySymbol(string symbol)
{
   int total = PositionsTotal();
   int closed = 0;
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == symbol)
         {
            ClosePosition(ticket);
            closed++;
         }
      }
   }
   
   Print("Closed ", closed, " positions for symbol ", symbol);
}

//+------------------------------------------------------------------+
//| Close all positions                                                |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   int total = PositionsTotal();
   int closed = 0;
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         ClosePosition(ticket);
         closed++;
      }
   }
   
   Print("Closed ", closed, " positions");
}

//+------------------------------------------------------------------+
//| Modify position SL/TP                                              |
//+------------------------------------------------------------------+
void ModifyPosition(ulong ticket, double sl, double tp, bool modifySL, bool modifyTP)
{
   if(!PositionSelectByTicket(ticket))
   {
      Print("Position ", ticket, " not found for modification");
      return;
   }
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = PositionGetString(POSITION_SYMBOL);
   
   if(modifySL)
      request.sl = sl;
   else
      request.sl = PositionGetDouble(POSITION_SL);
   
   if(modifyTP)
      request.tp = tp;
   else
      request.tp = PositionGetDouble(POSITION_TP);
   
   if(!OrderSend(request, result))
   {
      Print("Position modification failed: ", result.retcode, " - ", result.comment);
   }
   else if(result.retcode == TRADE_RETCODE_DONE)
   {
      Print("Position ", ticket, " modified: SL=", request.sl, ", TP=", request.tp);
   }
   else
   {
      Print("Position modification failed: ", result.retcode, " - ", result.comment);
   }
}

//+------------------------------------------------------------------+
//| Cancel pending order by ticket                                     |
//+------------------------------------------------------------------+
void CancelPendingOrder(ulong ticket)
{
   if(!OrderSelect(ticket))
   {
      Print("Order ", ticket, " not found");
      return;
   }
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_REMOVE;
   request.order = ticket;
   
   if(!OrderSend(request, result))
   {
      Print("Failed to cancel order ", ticket, ": ", result.retcode, " - ", result.comment);
   }
   else if(result.retcode == TRADE_RETCODE_DONE)
   {
      Print("Order ", ticket, " cancelled successfully");
   }
   else
   {
      Print("Failed to cancel order ", ticket, ": ", result.retcode, " - ", result.comment);
   }
}

//+------------------------------------------------------------------+
//| Cancel all pending orders                                          |
//+------------------------------------------------------------------+
void CancelAllPendingOrders()
{
   int total = OrdersTotal();
   int cancelled = 0;
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         CancelPendingOrder(ticket);
         cancelled++;
      }
   }
   
   Print("Cancelled ", cancelled, " pending orders");
}

//+------------------------------------------------------------------+
//| Create snapshot JSON for AI                                        |
//+------------------------------------------------------------------+
void CreateSnapshot()
{
   //--- Get current server time
   datetime serverTime = TimeCurrent();
   string timeStr = TimeToString(serverTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   
   //--- Get account information
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);
   
   //--- Get symbol information
   double bid = SymbolInfoDouble(activeSymbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(activeSymbol, SYMBOL_ASK);
   long spread = SymbolInfoInteger(activeSymbol, SYMBOL_SPREAD);
   
   //--- Build JSON string
   string json = "{\n";
   json += "  \"server_time\": \"" + timeStr + "\",\n";
   json += "  \"active_symbol\": \"" + activeSymbol + "\",\n";
   json += "  \"account\": {\n";
   json += "    \"balance\": " + DoubleToString(balance, 2) + ",\n";
   json += "    \"equity\": " + DoubleToString(equity, 2) + ",\n";
   json += "    \"margin\": " + DoubleToString(margin, 2) + "\n";
   json += "  },\n";
   json += "  \"symbol_info\": {\n";
   json += "    \"bid\": " + DoubleToString(bid, (int)SymbolInfoInteger(activeSymbol, SYMBOL_DIGITS)) + ",\n";
   json += "    \"ask\": " + DoubleToString(ask, (int)SymbolInfoInteger(activeSymbol, SYMBOL_DIGITS)) + ",\n";
   json += "    \"spread_points\": " + IntegerToString(spread) + "\n";
   json += "  },\n";
   
   //--- Add positions
   json += "  \"positions\": [\n";
   int posTotal = PositionsTotal();
   for(int i = 0; i < posTotal; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         string posSymbol = PositionGetString(POSITION_SYMBOL);
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         double profit = PositionGetDouble(POSITION_PROFIT);
         
         json += "    {\n";
         json += "      \"ticket\": " + IntegerToString(ticket) + ",\n";
         json += "      \"symbol\": \"" + posSymbol + "\",\n";
         json += "      \"type\": \"" + (posType == POSITION_TYPE_BUY ? "BUY" : "SELL") + "\",\n";
         json += "      \"volume\": " + DoubleToString(volume, 2) + ",\n";
         json += "      \"price_open\": " + DoubleToString(priceOpen, (int)SymbolInfoInteger(posSymbol, SYMBOL_DIGITS)) + ",\n";
         json += "      \"sl\": " + DoubleToString(sl, (int)SymbolInfoInteger(posSymbol, SYMBOL_DIGITS)) + ",\n";
         json += "      \"tp\": " + DoubleToString(tp, (int)SymbolInfoInteger(posSymbol, SYMBOL_DIGITS)) + ",\n";
         json += "      \"profit\": " + DoubleToString(profit, 2) + "\n";
         json += "    }";
         if(i < posTotal - 1) json += ",";
         json += "\n";
      }
   }
   json += "  ],\n";
   
   //--- Add pending orders
   json += "  \"orders\": [\n";
   int ordTotal = OrdersTotal();
   for(int i = 0; i < ordTotal; i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         string ordSymbol = OrderGetString(ORDER_SYMBOL);
         ENUM_ORDER_TYPE ordType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         double volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
         double price = OrderGetDouble(ORDER_PRICE_OPEN);
         
         string typeStr = "";
         if(ordType == ORDER_TYPE_BUY_LIMIT) typeStr = "BUY_LIMIT";
         else if(ordType == ORDER_TYPE_SELL_LIMIT) typeStr = "SELL_LIMIT";
         else if(ordType == ORDER_TYPE_BUY_STOP) typeStr = "BUY_STOP";
         else if(ordType == ORDER_TYPE_SELL_STOP) typeStr = "SELL_STOP";
         else typeStr = EnumToString(ordType);
         
         json += "    {\n";
         json += "      \"ticket\": " + IntegerToString(ticket) + ",\n";
         json += "      \"symbol\": \"" + ordSymbol + "\",\n";
         json += "      \"type\": \"" + typeStr + "\",\n";
         json += "      \"volume\": " + DoubleToString(volume, 2) + ",\n";
         json += "      \"price\": " + DoubleToString(price, (int)SymbolInfoInteger(ordSymbol, SYMBOL_DIGITS)) + "\n";
         json += "    }";
         if(i < ordTotal - 1) json += ",";
         json += "\n";
      }
   }
   json += "  ]\n";
   json += "}\n";
   
   //--- Write to file
   int fileHandle = FileOpen("AI_snapshot.json", FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(fileHandle != INVALID_HANDLE)
   {
      FileWriteString(fileHandle, json);
      FileClose(fileHandle);
   }
   else
   {
      Print("Error: Cannot write snapshot. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| OnTick function - intentionally empty                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Do nothing - all logic is in OnTimer
}
//+------------------------------------------------------------------+
