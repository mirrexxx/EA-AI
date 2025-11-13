//+------------------------------------------------------------------+
//|                                                 AI_Executor.mq5 |
//|                                     Universal EA for AI Trading |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "AI Executor"
#property link      ""
#property version   "1.00"
#property strict

// Input parameters
input int TimerIntervalSeconds = 5;        // Timer interval in seconds
input string CommandFile = "AI_commands.txt";  // Command file name
input string SnapshotFile = "AI_snapshot.json"; // Snapshot file name

// Global variables
int lastCommandId = 0;
string currentSymbol;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set timer
    EventSetTimer(TimerIntervalSeconds);
    
    currentSymbol = Symbol();
    
    Print("AI_Executor initialized on ", currentSymbol);
    Print("Command file: ", CommandFile);
    Print("Snapshot file: ", SnapshotFile);
    Print("Timer interval: ", TimerIntervalSeconds, " seconds");
    
    // Create initial snapshot
    WriteSnapshot();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    Print("AI_Executor stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Timer function                                                    |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Read and execute commands
    ReadAndExecuteCommands();
    
    // Update snapshot
    WriteSnapshot();
}

//+------------------------------------------------------------------+
//| Read and execute commands from file                              |
//+------------------------------------------------------------------+
void ReadAndExecuteCommands()
{
    int fileHandle = FileOpen(CommandFile, FILE_READ|FILE_TXT|FILE_COMMON);
    
    if(fileHandle == INVALID_HANDLE)
    {
        // File doesn't exist or can't be opened - that's OK, just return
        return;
    }
    
    string lastLine = "";
    
    // Read all lines to get the last one
    while(!FileIsEnding(fileHandle))
    {
        string line = FileReadString(fileHandle);
        if(StringLen(line) > 0)
            lastLine = line;
    }
    
    FileClose(fileHandle);
    
    if(StringLen(lastLine) == 0)
        return;
    
    // Parse command
    string parts[];
    int count = StringSplit(lastLine, ' ', parts);
    
    if(count < 2)
        return;
    
    int commandId = (int)StringToInteger(parts[0]);
    
    // Check if this command was already executed
    if(commandId <= lastCommandId)
        return;
    
    lastCommandId = commandId;
    string command = parts[1];
    
    Print("Executing command ID ", commandId, ": ", command);
    
    // Execute command
    if(command == "BUY")
    {
        if(count >= 3)
        {
            double volume = StringToDouble(parts[2]);
            ExecuteBuy(volume);
        }
    }
    else if(command == "SELL")
    {
        if(count >= 3)
        {
            double volume = StringToDouble(parts[2]);
            ExecuteSell(volume);
        }
    }
    else if(command == "BUY_LIMIT")
    {
        if(count >= 4)
        {
            double volume = StringToDouble(parts[2]);
            double price = StringToDouble(parts[3]);
            ExecuteBuyLimit(volume, price);
        }
    }
    else if(command == "SELL_LIMIT")
    {
        if(count >= 4)
        {
            double volume = StringToDouble(parts[2]);
            double price = StringToDouble(parts[3]);
            ExecuteSellLimit(volume, price);
        }
    }
    else if(command == "BUY_STOP")
    {
        if(count >= 4)
        {
            double volume = StringToDouble(parts[2]);
            double price = StringToDouble(parts[3]);
            ExecuteBuyStop(volume, price);
        }
    }
    else if(command == "SELL_STOP")
    {
        if(count >= 4)
        {
            double volume = StringToDouble(parts[2]);
            double price = StringToDouble(parts[3]);
            ExecuteSellStop(volume, price);
        }
    }
    else if(command == "MODIFY_SLTP")
    {
        if(count >= 5)
        {
            ulong ticket = StringToInteger(parts[2]);
            double sl = StringToDouble(parts[3]);
            double tp = StringToDouble(parts[4]);
            ExecuteModifySLTP(ticket, sl, tp);
        }
    }
    else if(command == "CLOSE_TICKET")
    {
        if(count >= 3)
        {
            ulong ticket = StringToInteger(parts[2]);
            ExecuteCloseTicket(ticket);
        }
    }
    else if(command == "CLOSE_SYMBOL")
    {
        if(count >= 3)
        {
            string symbol = parts[2];
            ExecuteCloseSymbol(symbol);
        }
    }
    else if(command == "CLOSE_ALL")
    {
        ExecuteCloseAll();
    }
    else if(command == "SET_SYMBOL")
    {
        if(count >= 3)
        {
            string symbol = parts[2];
            ExecuteSetSymbol(symbol);
        }
    }
    else
    {
        Print("Unknown command: ", command);
    }
}

//+------------------------------------------------------------------+
//| Execute BUY order                                                |
//+------------------------------------------------------------------+
void ExecuteBuy(double volume)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = currentSymbol;
    request.volume = volume;
    request.type = ORDER_TYPE_BUY;
    request.price = SymbolInfoDouble(currentSymbol, SYMBOL_ASK);
    request.deviation = 10;
    request.magic = 0;
    
    if(!OrderSend(request, result))
    {
        Print("BUY order failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
    }
    else
    {
        Print("BUY order executed. Ticket: ", result.order, ", Volume: ", volume);
    }
}

//+------------------------------------------------------------------+
//| Execute SELL order                                               |
//+------------------------------------------------------------------+
void ExecuteSell(double volume)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = currentSymbol;
    request.volume = volume;
    request.type = ORDER_TYPE_SELL;
    request.price = SymbolInfoDouble(currentSymbol, SYMBOL_BID);
    request.deviation = 10;
    request.magic = 0;
    
    if(!OrderSend(request, result))
    {
        Print("SELL order failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
    }
    else
    {
        Print("SELL order executed. Ticket: ", result.order, ", Volume: ", volume);
    }
}

//+------------------------------------------------------------------+
//| Execute BUY_LIMIT order                                          |
//+------------------------------------------------------------------+
void ExecuteBuyLimit(double volume, double price)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_PENDING;
    request.symbol = currentSymbol;
    request.volume = volume;
    request.type = ORDER_TYPE_BUY_LIMIT;
    request.price = price;
    request.magic = 0;
    
    if(!OrderSend(request, result))
    {
        Print("BUY_LIMIT order failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
    }
    else
    {
        Print("BUY_LIMIT order placed. Ticket: ", result.order, ", Volume: ", volume, ", Price: ", price);
    }
}

//+------------------------------------------------------------------+
//| Execute SELL_LIMIT order                                         |
//+------------------------------------------------------------------+
void ExecuteSellLimit(double volume, double price)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_PENDING;
    request.symbol = currentSymbol;
    request.volume = volume;
    request.type = ORDER_TYPE_SELL_LIMIT;
    request.price = price;
    request.magic = 0;
    
    if(!OrderSend(request, result))
    {
        Print("SELL_LIMIT order failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
    }
    else
    {
        Print("SELL_LIMIT order placed. Ticket: ", result.order, ", Volume: ", volume, ", Price: ", price);
    }
}

//+------------------------------------------------------------------+
//| Execute BUY_STOP order                                           |
//+------------------------------------------------------------------+
void ExecuteBuyStop(double volume, double price)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_PENDING;
    request.symbol = currentSymbol;
    request.volume = volume;
    request.type = ORDER_TYPE_BUY_STOP;
    request.price = price;
    request.magic = 0;
    
    if(!OrderSend(request, result))
    {
        Print("BUY_STOP order failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
    }
    else
    {
        Print("BUY_STOP order placed. Ticket: ", result.order, ", Volume: ", volume, ", Price: ", price);
    }
}

//+------------------------------------------------------------------+
//| Execute SELL_STOP order                                          |
//+------------------------------------------------------------------+
void ExecuteSellStop(double volume, double price)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_PENDING;
    request.symbol = currentSymbol;
    request.volume = volume;
    request.type = ORDER_TYPE_SELL_STOP;
    request.price = price;
    request.magic = 0;
    
    if(!OrderSend(request, result))
    {
        Print("SELL_STOP order failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
    }
    else
    {
        Print("SELL_STOP order placed. Ticket: ", result.order, ", Volume: ", volume, ", Price: ", price);
    }
}

//+------------------------------------------------------------------+
//| Modify SL/TP for a position                                      |
//+------------------------------------------------------------------+
void ExecuteModifySLTP(ulong ticket, double sl, double tp)
{
    if(!PositionSelectByTicket(ticket))
    {
        Print("Position not found: ", ticket);
        return;
    }
    
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_SLTP;
    request.position = ticket;
    request.symbol = PositionGetString(POSITION_SYMBOL);
    request.sl = sl;
    request.tp = tp;
    
    if(!OrderSend(request, result))
    {
        Print("Modify SL/TP failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
    }
    else
    {
        Print("SL/TP modified. Ticket: ", ticket, ", SL: ", sl, ", TP: ", tp);
    }
}

//+------------------------------------------------------------------+
//| Close position by ticket                                         |
//+------------------------------------------------------------------+
void ExecuteCloseTicket(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
    {
        Print("Position not found: ", ticket);
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
    
    // Determine order type based on position type
    if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        request.type = ORDER_TYPE_SELL;
    else
        request.type = ORDER_TYPE_BUY;
    
    request.price = (request.type == ORDER_TYPE_SELL) ? 
                    SymbolInfoDouble(request.symbol, SYMBOL_BID) : 
                    SymbolInfoDouble(request.symbol, SYMBOL_ASK);
    
    if(!OrderSend(request, result))
    {
        Print("Close ticket failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
    }
    else
    {
        Print("Position closed. Ticket: ", ticket);
    }
}

//+------------------------------------------------------------------+
//| Close all positions for a symbol                                 |
//+------------------------------------------------------------------+
void ExecuteCloseSymbol(string symbol)
{
    int total = PositionsTotal();
    
    for(int i = total - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            if(PositionGetString(POSITION_SYMBOL) == symbol)
            {
                ExecuteCloseTicket(ticket);
            }
        }
    }
    
    Print("All positions closed for symbol: ", symbol);
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void ExecuteCloseAll()
{
    int total = PositionsTotal();
    
    for(int i = total - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            ExecuteCloseTicket(ticket);
        }
    }
    
    Print("All positions closed");
}

//+------------------------------------------------------------------+
//| Set active symbol                                                |
//+------------------------------------------------------------------+
void ExecuteSetSymbol(string symbol)
{
    // Verify symbol exists
    if(!SymbolSelect(symbol, true))
    {
        Print("Failed to select symbol: ", symbol);
        return;
    }
    
    currentSymbol = symbol;
    Print("Active symbol changed to: ", currentSymbol);
}

//+------------------------------------------------------------------+
//| Write market snapshot to JSON file                               |
//+------------------------------------------------------------------+
void WriteSnapshot()
{
    int fileHandle = FileOpen(SnapshotFile, FILE_WRITE|FILE_TXT|FILE_COMMON);
    
    if(fileHandle == INVALID_HANDLE)
    {
        Print("Failed to open snapshot file for writing. Error: ", GetLastError());
        return;
    }
    
    // Start JSON
    FileWriteString(fileHandle, "{\n");
    
    // Account info
    FileWriteString(fileHandle, "  \"account\": {\n");
    FileWriteString(fileHandle, "    \"balance\": " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",\n");
    FileWriteString(fileHandle, "    \"equity\": " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",\n");
    FileWriteString(fileHandle, "    \"margin\": " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2) + ",\n");
    FileWriteString(fileHandle, "    \"free_margin\": " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + ",\n");
    FileWriteString(fileHandle, "    \"margin_level\": " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2) + ",\n");
    FileWriteString(fileHandle, "    \"profit\": " + DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT), 2) + "\n");
    FileWriteString(fileHandle, "  },\n");
    
    // Current symbol info
    FileWriteString(fileHandle, "  \"current_symbol\": {\n");
    FileWriteString(fileHandle, "    \"name\": \"" + currentSymbol + "\",\n");
    FileWriteString(fileHandle, "    \"bid\": " + DoubleToString(SymbolInfoDouble(currentSymbol, SYMBOL_BID), 5) + ",\n");
    FileWriteString(fileHandle, "    \"ask\": " + DoubleToString(SymbolInfoDouble(currentSymbol, SYMBOL_ASK), 5) + ",\n");
    FileWriteString(fileHandle, "    \"spread\": " + IntegerToString(SymbolInfoInteger(currentSymbol, SYMBOL_SPREAD)) + "\n");
    FileWriteString(fileHandle, "  },\n");
    
    // Open positions
    FileWriteString(fileHandle, "  \"positions\": [\n");
    int posTotal = PositionsTotal();
    for(int i = 0; i < posTotal; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            string posSymbol = PositionGetString(POSITION_SYMBOL);
            long posType = PositionGetInteger(POSITION_TYPE);
            double posVolume = PositionGetDouble(POSITION_VOLUME);
            double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double posSL = PositionGetDouble(POSITION_SL);
            double posTP = PositionGetDouble(POSITION_TP);
            double posProfit = PositionGetDouble(POSITION_PROFIT);
            
            FileWriteString(fileHandle, "    {\n");
            FileWriteString(fileHandle, "      \"ticket\": " + IntegerToString(ticket) + ",\n");
            FileWriteString(fileHandle, "      \"symbol\": \"" + posSymbol + "\",\n");
            FileWriteString(fileHandle, "      \"type\": \"" + (posType == POSITION_TYPE_BUY ? "BUY" : "SELL") + "\",\n");
            FileWriteString(fileHandle, "      \"volume\": " + DoubleToString(posVolume, 2) + ",\n");
            FileWriteString(fileHandle, "      \"open_price\": " + DoubleToString(posOpenPrice, 5) + ",\n");
            FileWriteString(fileHandle, "      \"sl\": " + DoubleToString(posSL, 5) + ",\n");
            FileWriteString(fileHandle, "      \"tp\": " + DoubleToString(posTP, 5) + ",\n");
            FileWriteString(fileHandle, "      \"profit\": " + DoubleToString(posProfit, 2) + "\n");
            FileWriteString(fileHandle, "    }" + (i < posTotal - 1 ? "," : "") + "\n");
        }
    }
    FileWriteString(fileHandle, "  ],\n");
    
    // Pending orders
    FileWriteString(fileHandle, "  \"pending_orders\": [\n");
    int ordTotal = OrdersTotal();
    for(int i = 0; i < ordTotal; i++)
    {
        ulong ticket = OrderGetTicket(i);
        if(ticket > 0)
        {
            string ordSymbol = OrderGetString(ORDER_SYMBOL);
            long ordType = OrderGetInteger(ORDER_TYPE);
            double ordVolume = OrderGetDouble(ORDER_VOLUME_CURRENT);
            double ordPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            double ordSL = OrderGetDouble(ORDER_SL);
            double ordTP = OrderGetDouble(ORDER_TP);
            
            string typeStr = "";
            if(ordType == ORDER_TYPE_BUY_LIMIT) typeStr = "BUY_LIMIT";
            else if(ordType == ORDER_TYPE_SELL_LIMIT) typeStr = "SELL_LIMIT";
            else if(ordType == ORDER_TYPE_BUY_STOP) typeStr = "BUY_STOP";
            else if(ordType == ORDER_TYPE_SELL_STOP) typeStr = "SELL_STOP";
            
            FileWriteString(fileHandle, "    {\n");
            FileWriteString(fileHandle, "      \"ticket\": " + IntegerToString(ticket) + ",\n");
            FileWriteString(fileHandle, "      \"symbol\": \"" + ordSymbol + "\",\n");
            FileWriteString(fileHandle, "      \"type\": \"" + typeStr + "\",\n");
            FileWriteString(fileHandle, "      \"volume\": " + DoubleToString(ordVolume, 2) + ",\n");
            FileWriteString(fileHandle, "      \"price\": " + DoubleToString(ordPrice, 5) + ",\n");
            FileWriteString(fileHandle, "      \"sl\": " + DoubleToString(ordSL, 5) + ",\n");
            FileWriteString(fileHandle, "      \"tp\": " + DoubleToString(ordTP, 5) + "\n");
            FileWriteString(fileHandle, "    }" + (i < ordTotal - 1 ? "," : "") + "\n");
        }
    }
    FileWriteString(fileHandle, "  ],\n");
    
    // Timestamp
    FileWriteString(fileHandle, "  \"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS) + "\"\n");
    
    // End JSON
    FileWriteString(fileHandle, "}\n");
    
    FileClose(fileHandle);
}
//+------------------------------------------------------------------+
