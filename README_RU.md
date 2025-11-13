# EA-AI: Универсальный исполнитель для AI торговли

Система для автоматической торговли на MetaTrader 5, где **все решения принимает искусственный интеллект**.

## Концепция

EA (Expert Advisor) — это **тупой исполнитель** без собственной логики. Весь мозг находится снаружи, в AI агенте.

```
AI Agent (Python + LLM) ←→ EA (MQL5) ←→ MT5 Terminal
```

### Схема работы:

1. **EA** каждые N секунд:
   - Читает команды из `AI_commands.txt`
   - Выполняет торговые операции
   - Записывает состояние счёта в `AI_snapshot.json`

2. **AI Agent** (Python скрипт):
   - Читает `AI_snapshot.json`
   - Анализирует рынок через LLM (ChatGPT, Claude и т.д.)
   - Генерирует команды
   - Записывает команды в `AI_commands.txt`

3. **EA читает команды → выполняет → цикл повторяется**

## Возможности EA

EA — это чистый API к MetaTrader 5. Никакого встроенного риск-менеджмента, фильтров или логики.

### Команды (примитивы):

#### 1. Торговля
- `BUY <volume>` - Открыть позицию на покупку
- `SELL <volume>` - Открыть позицию на продажу
- `BUY_LIMIT <volume> <price>` - Установить отложенный ордер Buy Limit
- `SELL_LIMIT <volume> <price>` - Установить отложенный ордер Sell Limit
- `BUY_STOP <volume> <price>` - Установить отложенный ордер Buy Stop
- `SELL_STOP <volume> <price>` - Установить отложенный ордер Sell Stop

#### 2. Управление позициями
- `MODIFY_SLTP <ticket> <sl> <tp>` - Изменить Stop Loss и Take Profit
- `CLOSE_TICKET <ticket>` - Закрыть позицию по тикету
- `CLOSE_SYMBOL <symbol>` - Закрыть все позиции по символу
- `CLOSE_ALL` - Закрыть все позиции

#### 3. Настройки
- `SET_SYMBOL <symbol>` - Переключить активный символ

### Что НЕТ в EA:

- ❌ Встроенного риск-менеджмента
- ❌ Лимита по числу позиций
- ❌ Лимита по объёму лота (кроме ограничений брокера)
- ❌ Фильтров по спреду/времени/сессиям
- ❌ Никакой торговой логики

**Единственные ограничения** — те, что накладывает брокер (минимальный лот, margin call, stop out).

## Установка

### 1. Установить EA в MetaTrader 5

1. Скопировать `AI_Executor.mq5` в папку:
   ```
   C:\Users\<ИМЯ>\AppData\Roaming\MetaQuotes\Terminal\<ID>\MQL5\Experts\
   ```

2. Открыть MetaEditor (F4 в MT5)

3. Скомпилировать `AI_Executor.mq5`

4. Перетащить EA на график в MT5

5. В настройках EA:
   - `TimerIntervalSeconds` - интервал проверки команд (по умолчанию 5 сек)
   - `CommandFile` - имя файла с командами (по умолчанию AI_commands.txt)
   - `SnapshotFile` - имя файла со снимком рынка (по умолчанию AI_snapshot.json)

6. Включить автоматическую торговлю (кнопка AutoTrading в MT5)

### 2. Настроить AI Agent

1. Установить Python 3.7+

2. Запустить агента:
   ```bash
   python ai_agent.py
   ```

3. Агент автоматически найдёт файлы MT5 или использует текущую директорию

### 3. Интеграция с LLM

В файле `ai_agent.py` найти функцию `make_ai_decision()` и добавить свою интеграцию с AI:

```python
def make_ai_decision(self, snapshot):
    # Подготовить данные для LLM
    prompt = f"""
    Ты трейдинг AI. Проанализируй рынок:
    
    Баланс: {snapshot['account']['balance']}
    Equity: {snapshot['account']['equity']}
    Позиции: {len(snapshot['positions'])}
    
    Текущий символ: {snapshot['current_symbol']['name']}
    Bid: {snapshot['current_symbol']['bid']}
    Ask: {snapshot['current_symbol']['ask']}
    
    Доступные команды:
    - BUY <объём>
    - SELL <объём>
    - CLOSE_ALL
    
    Верни ТОЛЬКО команду или NO_ACTION
    """
    
    # Вызвать LLM API (OpenAI, Claude, etc.)
    response = your_llm_api_call(prompt)
    
    if response != "NO_ACTION":
        return response
    
    return None
```

## Примеры команд

Формат команд в файле `AI_commands.txt`:

```
<ID> <КОМАНДА> [параметры]
```

Примеры:

```
1 BUY 0.10
2 SELL 0.05
3 SET_SYMBOL EURUSD
4 BUY_LIMIT 0.10 1.2000
5 MODIFY_SLTP 123456 1.1950 1.2050
6 CLOSE_TICKET 123456
7 CLOSE_ALL
```

**Важно**: ID должен быть уникальным и возрастающим. EA выполняет только команды с новым ID.

## Формат AI_snapshot.json

EA создаёт JSON файл с полным состоянием счёта:

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
  "pending_orders": [],
  "timestamp": "2025.11.13 14:30:00"
}
```

## Безопасность

⚠️ **ВАЖНО**: Эта система даёт AI полный контроль над счётом!

### Рекомендации:

1. **ИСПОЛЬЗУЙТЕ ТОЛЬКО ДЕМО-СЧЁТ** для экспериментов
2. Начните с минимальных объёмов
3. Следите за логами EA и агента
4. Установите ограничения в самом AI (промпт-инжиниринг)
5. Добавьте систему остановки (circuit breaker) в AI агента

### Пример Circuit Breaker:

```python
def check_safety_limits(self, snapshot):
    """Проверка безопасности перед выполнением команды"""
    account = snapshot['account']
    
    # Максимальная просадка
    if account['equity'] < account['balance'] * 0.9:
        print("STOP: Просадка больше 10%")
        return False
    
    # Максимальное количество позиций
    if len(snapshot['positions']) > 5:
        print("STOP: Слишком много открытых позиций")
        return False
    
    return True
```

## Архитектура

```
┌─────────────────┐
│   AI Agent      │ ← Мозг системы (LLM, логика)
│   (Python)      │
└────────┬────────┘
         │
         │ AI_snapshot.json (читает)
         │ AI_commands.txt (пишет)
         │
┌────────▼────────┐
│   EA Executor   │ ← Тупой исполнитель (API к MT5)
│   (MQL5)        │
└────────┬────────┘
         │
         │ OrderSend(), PositionClose()
         │
┌────────▼────────┐
│   MT5 Terminal  │ ← Брокер, демо-счёт
└─────────────────┘
```

## Разработка

### Тестирование EA без AI

Можно вручную создать файл `AI_commands.txt` в папке MT5:
```
C:\Users\<ИМЯ>\AppData\Roaming\MetaQuotes\Terminal\Common\Files\AI_commands.txt
```

И записать туда команду:
```
1 BUY 0.01
```

EA выполнит команду на следующем тике таймера.

### Логи

EA выводит все действия в журнал MT5 (вкладка Experts в Toolbox).

AI Agent выводит анализ в консоль Python.

## FAQ

**Q: Почему команды через файлы, а не через API?**  
A: Это самый простой и надёжный способ для MVP. Файлы работают локально, не требуют сетевого взаимодействия, легко отлаживать.

**Q: Можно ли использовать на реальном счёте?**  
A: Технически да, но **крайне не рекомендуется**. Это экспериментальная система. Сначала протестируйте на демо несколько месяцев.

**Q: Как добавить индикаторы?**  
A: Можно расширить `WriteSnapshot()` в EA, добавив расчёт индикаторов (MA, RSI, ATR и т.д.) и записав их в JSON.

**Q: Поддерживается ли MT4?**  
A: Нет, только MT5. В MT4 другой API для работы с позициями.

## Лицензия

MIT License - используйте на свой риск.

## Вклад

Pull requests приветствуются! Особенно:
- Примеры интеграций с разными LLM
- Улучшения безопасности
- Дополнительные команды
- Тесты

---

**Помните**: ИИ принимает ВСЕ решения. Вы только создаёте инструмент.
