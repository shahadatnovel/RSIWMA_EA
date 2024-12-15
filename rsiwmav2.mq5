//+------------------------------------------------------------------+
//|                                                     rsiwmav2.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, ShahadatNovel."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

input string Indicator_Settings="++++++++++++++++++++++++++";
input string RSI_WMA_TF1="RSI WMA LOWER TF";
input ENUM_TIMEFRAMES RSI_Timeframe = PERIOD_CURRENT;
input int RSI_Period = 14;
input ENUM_APPLIED_PRICE RSI_Applied_Price = PRICE_CLOSE;
input ENUM_MA_METHOD WMA_METHOD = MODE_LWMA;
input int WMA_Period = 50;
input int EMA_Period = 20;

input double RSI_Threshold_Buy = 30.0;
input double RSI_Threshold_Sell = 70.0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input bool UseHigherTimeFrame=true;//Use RSI WMA HTF
input string RSI_WMA_TF2="RSI WMA HIGHER TF";

input ENUM_TIMEFRAMES RSI_Timeframe2 = PERIOD_CURRENT;
input int RSI_Period2 = 14;
input ENUM_APPLIED_PRICE RSI_Applied_Price2 = PRICE_CLOSE;
input ENUM_MA_METHOD WMA_METHOD2 = MODE_LWMA;
input int WMA_Period2 = 50;
input int EMA_Period2 = 20;

input double RSI_Threshold_Buy2 = 30.0;
input double RSI_Threshold_Sell2 = 70.0;

//input bool DisplayBars =false;//Display Color Bars

//input color BullishCandles = clrBlue;
//input color BearishCandles = clrRed;
input string EA_Settings="++++++++++++++++++++++++++";

input bool UseUSDAmountPerTrader=false;//Use USD Amount Per Trade
input double Trade_Value_USD = 500.0; // USD amount per trade
input double LotSize=0.2;//Lot Size
input double LotClosePartially =50;//Partial Close Lot %
input double Profit_Target_1_Ratio = 1.0; // First profit target ratio
input double Profit_Target_2_Ratio = 3.0; // Second profit target ratio

input bool UseTrailingStop=false;//Use Trailing Stop
input bool Use_Last_High_Low_Price =false;//Use Last High/Low Price
input double Trail_Trigger_Ratio = 1.0; // Trailing Stop Loss ratio

input int MagicNumber = 1234;//Magic Number
double myPoint; //initialized in OnInit

input int NumberOfActiveTradesPerChart=5;//Number Of Active  Trades Per Chart

//input double _Spread = 1000;//Spread (Points)



int rsi_handle;
int WMA_Handle;
double RSI[];
double WMA[];         // Array to store MA on RSI

int rsi_handle2;
int WMA_Handle2;
double RSI2[];
double WMA2[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---


   if(TimeCurrent()>=D'2024.12.20')
     {
      ExpertRemove();
      MessageBox("Your Time has Expired! Please contact the Developer.","License Expiry");
     }


   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

   myPoint=SymbolInfoDouble(Symbol(),SYMBOL_POINT);
   if(digits == 5 || digits == 3)
     {
      myPoint *= 10;
     }


   ArraySetAsSeries(RSI, true);
   ArraySetAsSeries(WMA, true);

   rsi_handle = iRSI(_Symbol, PERIOD_M15, RSI_Period, RSI_Applied_Price);
   if(rsi_handle == INVALID_HANDLE)
     {
      Print("Failed to create RSI handle. Error: ", GetLastError());
      return INIT_FAILED;
     }

   ArraySetAsSeries(RSI2, true);
   ArraySetAsSeries(WMA2, true);

   rsi_handle2 = iRSI(_Symbol, PERIOD_M15, RSI_Period2, RSI_Applied_Price2);
   if(rsi_handle2 == INVALID_HANDLE)
     {
      Print("Failed to create RSI handle. Error: ", GetLastError());
      return INIT_FAILED;
     }



//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   double decimalPoint = SymbolInfoDouble(Symbol(), SYMBOL_POINT);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double spread = MathAbs(SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID));

   double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low = iLow(_Symbol, PERIOD_CURRENT, 1);


   double buysl = MathAbs(ask - low)+spread ;
   double sellsl = MathAbs(high - bid)+spread;

   double buyslpoints = SafeDivide(buysl, decimalPoint);
   double sellslpoints = SafeDivide(sellsl, decimalPoint);



   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);



   double buydivider = buyslpoints * tickValue;
   double lotsizebuy = NormalizeDouble(SafeDivide(Trade_Value_USD, buydivider), 2);

   double selldivider = sellslpoints * tickValue;
   double lotsizesell = NormalizeDouble(SafeDivide(Trade_Value_USD, selldivider), 2);


// Calculate stop loss distance for buy trades
   double sldisbuy = MathAbs(NormalizeDouble(
                                SymbolInfoDouble(Symbol(), SYMBOL_ASK) - iLow(Symbol(), PERIOD_CURRENT, 1), 2));

// Calculate stop loss distance for sell trades
   double sldissell = MathAbs(NormalizeDouble(
                                 iHigh(Symbol(), PERIOD_CURRENT, 1) - SymbolInfoDouble(Symbol(), SYMBOL_BID), 2));




   int bars = Bars(_Symbol, RSI_Timeframe) - 50;

   int copied = CopyBuffer(rsi_handle, 0, 0, bars, RSI);

   if(copied <= 0)
     {
      Print("Failed to get RSI values. Error: ", GetLastError());
      return;
     }

// Resize the arrays to match the number of bars
// int bars = Bars(_Symbol, RSI_Timeframe);
   ArrayResize(RSI, bars);
   ArrayResize(WMA, bars);

   for(int i = 0; i <RSI_Period+WMA_Period; i++)
     {

      WMA[i] = iMAOnArray(RSI, WMA_Period, 0, MODE_LWMA, i);
     }


   bool  buysignal = WMA[1]<RSI[1]  &&   WMA[2]>RSI[2]  &&RSI[1]<RSI_Threshold_Buy  ;
   bool sellsignal =  WMA[1]>RSI[1] && WMA[2]<RSI[2] && RSI[1]>RSI_Threshold_Sell ;




//Print(CountTradesByMagicAndSymbol(MagicNumber,Symbol()));



//   Print(low-spread);
//   Print(ask+sldisbuy*Profit_Target_2_Ratio);
//


   bool newbar = NewBar();

   if(CountTradesByMagicAndSymbol(MagicNumber,Symbol())<NumberOfActiveTradesPerChart  &&newbar && buysignal)
     {
      double lotbuy = UseUSDAmountPerTrader?lotsizebuy:LotSize;
      trade.SetExpertMagicNumber(MagicNumber);
      trade.Buy(lotbuy,Symbol(),ask,low-spread,ask+sldisbuy*Profit_Target_2_Ratio,"RSIWMA EA");
     }



   if(CountTradesByMagicAndSymbol(MagicNumber,Symbol())<NumberOfActiveTradesPerChart  &&newbar && sellsignal)
     {
      double lotsell = UseUSDAmountPerTrader?lotsizesell:LotSize;
      trade.SetExpertMagicNumber(MagicNumber);
      trade.Sell(lotsell,Symbol(),bid,high+spread,bid-sldissell*Profit_Target_2_Ratio,"RSIWMA EA");
     }




   int copied2 = CopyBuffer(rsi_handle2, 0, 0, bars, RSI2);

   if(copied2 <= 0)
     {
      Print("Failed to get RSI values. Error: ", GetLastError());
      return;
     }

// Resize the arrays to match the number of bars
// int bars = Bars(_Symbol, RSI_Timeframe);
   ArrayResize(RSI2, bars);
   ArrayResize(WMA2, bars);

   for(int i = 0; i <RSI_Period2+WMA_Period2; i++)
     {

      WMA2[i] = iMAOnArray(RSI2, WMA_Period2, 0, MODE_LWMA, i);
     }


   bool  buysignal2 = (WMA[1]<RSI[1]  &&   WMA[2]>RSI[2]  &&RSI[1]<RSI_Threshold_Buy) && (WMA2[1]<RSI2[1]  &&   WMA2[2]>RSI2[2]  &&RSI2[1]<RSI_Threshold_Buy2)    ;



   bool sellsignal2 = (WMA[1]>RSI[1] && WMA[2]<RSI[2] && RSI[1]>RSI_Threshold_Sell) && (WMA2[1]>RSI2[1] && WMA2[2]<RSI2[2] && RSI2[1]>RSI_Threshold_Sell2);


   bool bs = true;
   bool ss = true;

   if(buysignal2 && newbar &&UseHigherTimeFrame==true
      && CountTradesByMagicAndSymbol(MagicNumber,Symbol())<NumberOfActiveTradesPerChart)
     {

      double lotbuy = UseUSDAmountPerTrader?lotsizebuy:LotSize;


      int bt = trade.Buy(lotbuy,Symbol(),ask,low-spread,ask+sldisbuy*Profit_Target_2_Ratio,(string)lotbuy+"OL");

     }




   if(sellsignal2 && newbar && UseHigherTimeFrame==true
      && CountTradesByMagicAndSymbol(MagicNumber,Symbol())<NumberOfActiveTradesPerChart)
     {
      double lotsell = UseUSDAmountPerTrader?lotsizesell:LotSize;


      int st =trade.Sell(lotsell,Symbol(),bid,high+spread,bid-sldissell*Profit_Target_2_Ratio,(string)lotsell+"OL");





     }


//+------------------------------------------------------------------+
//|     logic ends here                                                              |
//+------------------------------------------------------------------+


   PartialCloseBuy();
   PartialCloseSell();



   if(UseTrailingStop && Use_Last_High_Low_Price==false)
     {
      TrailPriceToBEBuy();
      TrailPriceToBESell();
     }

   if(UseTrailingStop && Use_Last_High_Low_Price)
     {
      ModifyStopLossForAllBuyPositions();
      ModifyStopLossForAllSellPositions();
     }



  }
//+------------------------------------------------------------------+









//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iMAOnArray(double& array[], int period, int ma_shift, ENUM_MA_METHOD ma_method, int shift)
  {

   double buf[], arr[];
   int total = ArraySize(array);

   if(total <= period)
      return 0;

   if(shift > total - period - ma_shift)
      return 0;

   switch(ma_method)
     {

      case MODE_SMA:
        {

         total = ArrayCopy(arr, array, 0, shift + ma_shift, period);
         if(ArrayResize(buf, total) < 0)
            return 0;

         double sum = 0;
         int i, pos = total-1;

         for(i = 1; i < period; i++, pos--)

            sum += arr[pos];

         while(pos >= 0)
           {

            sum += arr[pos];

            buf[pos] = sum / period;

            sum -= arr[pos + period - 1];

            pos--;

           }

         return buf[0];

        }



      case MODE_EMA:
        {

         if(ArrayResize(buf, total) < 0)

            return 0;

         double pr = 2.0 / (period + 1);

         int pos = total - 2;



         while(pos >= 0)
           {

            if(pos == total - 2)

               buf[pos+1] = array[pos+1];

            buf[pos] = array[pos] * pr + buf[pos+1] * (1-pr);

            pos--;

           }

         return buf[shift+ma_shift];

        }



      case MODE_SMMA:
        {

         if(ArrayResize(buf, total) < 0)

            return(0);

         double sum = 0;

         int i, k, pos;



         pos = total - period;

         while(pos >= 0)
           {

            if(pos == total - period)
              {

               for(i = 0, k = pos; i < period; i++, k++)
                 {

                  sum += array[k];

                  buf[k] = 0;

                 }

              }

            else

               sum = buf[pos+1] * (period-1) + array[pos];

            buf[pos]=sum/period;

            pos--;

           }

         return buf[shift+ma_shift];

        }



      case MODE_LWMA:
        {

         if(ArrayResize(buf, total) < 0)

            return 0;

         double sum = 0.0, lsum = 0.0;

         double price;

         int i, weight = 0, pos = total-1;



         for(i = 1; i <= period; i++, pos--)
           {

            price = array[pos];

            sum += price * i;

            lsum += price;

            weight += i;

           }

         pos++;

         i = pos + period;

         while(pos >= 0)
           {

            buf[pos] = sum / weight;

            if(pos == 0)

               break;

            pos--;

            i--;

            price = array[pos];

            sum = sum - lsum + price * period;

            lsum -= array[i];

            lsum += price;

           }

         return buf[shift+ma_shift];

        }

     }

   return 0;

  }

//+------------------------------------------------------------------+
// Function for safe division to handle division by zero
double SafeDivide(double numerator, double denominator)
  {
   if(denominator == 0.0)
     {
      Print("Error: Division by zero. Returning 0.");
      return 0.0; // Return 0 or any default value when denominator is zero
     }
   return numerator / denominator;
  }

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar()
  {
   datetime cTime[];
   ArraySetAsSeries(cTime, true);
   CopyTime(Symbol(), Period(), 0, 1, cTime);
   static datetime LastTime = 0;
   bool ret = cTime[0] > LastTime && LastTime > 0;
   LastTime = cTime[0];
   return(ret);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
int CountTradesByMagicAndSymbol(int magicNumber, string symbol)
  {
   int tradeCount = 0; // Initialize the trade count
   int totalPositions = PositionsTotal(); // Get the total number of positions

// Loop through all positions
   for(int i = 0; i < totalPositions; i++)
     {
      ulong ticket = PositionGetTicket(i); // Get position ticket by index
      if(PositionSelectByTicket(ticket))   // Select the position by ticket
        {
         // Check if the position's magic number and symbol match the given criteria
         if(PositionGetInteger(POSITION_MAGIC) == magicNumber && PositionGetString(POSITION_SYMBOL) == symbol)
           {
            tradeCount++; // Increment the trade count
           }
        }
     }

   return tradeCount; // Return the count of matching trades
  }
//+------------------------------------------------------------------+









//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PartialCloseBuy()
  {
// Get the total number of positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetInteger(POSITION_TICKET);

      // Select the position by ticket
      if(PositionSelectByTicket(ticket))
        {
         // Check if this is a position with the correct magic number and symbol
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            // Extract necessary position properties
            double lotSize = PositionGetDouble(POSITION_VOLUME);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double stopLoss = PositionGetDouble(POSITION_SL);

            double slSize = openPrice - stopLoss;
            double closeLots = NormalizeDouble(lotSize * LotClosePartially * 0.01, _Digits);

            // Calculate the profit target
            double profitTarget = openPrice + slSize * Profit_Target_1_Ratio;

            // Check if conditions for partial close are met
            if(closeLots > 0 && closeLots <= lotSize && SymbolInfoDouble(_Symbol, SYMBOL_BID) >= profitTarget)
              {
               if(!trade.PositionClosePartial(_Symbol, closeLots))
                 {
                  Print("Error closing part of the position: ", GetLastError());
                 }
              }
            else
              {
               Print("Invalid lot size or conditions not met for partial close: ", closeLots);
              }
           }
        }
      else
        {
         Print("PositionSelectByTicket failed for ticket: ", ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PartialCloseSell()
  {
// Get the total number of positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetInteger(POSITION_TICKET);

      // Select the position by ticket
      if(PositionSelectByTicket(ticket))
        {
         // Check if this is a position with the correct magic number and symbol
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            // Extract necessary position properties
            double lotSize = PositionGetDouble(POSITION_VOLUME);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double stopLoss = PositionGetDouble(POSITION_SL);

            double slSize = stopLoss - openPrice;
            double closeLots = NormalizeDouble(lotSize * LotClosePartially * 0.01, _Digits);

            // Calculate the profit target
            double profitTarget = openPrice - slSize * Profit_Target_1_Ratio;

            // Check if conditions for partial close are met
            if(closeLots > 0 && closeLots <= lotSize && SymbolInfoDouble(_Symbol, SYMBOL_ASK) <= profitTarget)
              {
               if(!trade.PositionClosePartial(_Symbol, closeLots))
                 {
                  Print("Error closing part of the sell position: ", GetLastError());
                 }
              }
            else
              {
               Print("Invalid lot size or conditions not met for partial close: ", closeLots);
              }
           }
        }
      else
        {
         Print("PositionSelectByTicket failed for ticket: ", ticket);
        }
     }
  }
//+------------------------------------------------------------------+






//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailPriceToBEBuy()
  {

   double Ask =SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double Bid =SymbolInfoDouble(Symbol(),SYMBOL_BID);


   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         // Check if the position matches the current symbol and magic number
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double stopLoss = PositionGetDouble(POSITION_SL);

            double slSize = openPrice - stopLoss;
            double bePrice = openPrice + slSize * Trail_Trigger_Ratio;
            double trailPrice = Ask - bePrice;


            if(Ask >= openPrice + slSize * Trail_Trigger_Ratio && Ask > stopLoss)
              {
               bool res = trade.PositionModify(ticket, openPrice, PositionGetDouble(POSITION_TP));
               if(!res)
                 {
                  Print("Failed to modify position: ", trade.ResultRetcode());
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailPriceToBESell()
  {

   double Ask =SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double Bid =SymbolInfoDouble(Symbol(),SYMBOL_BID);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         // Check if the position matches the current symbol and magic number
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double stopLoss = PositionGetDouble(POSITION_SL);

            double slSize = stopLoss - openPrice;

            if(Bid <= openPrice - slSize * Trail_Trigger_Ratio && Bid < stopLoss)
              {
               bool res = trade.PositionModify(ticket, openPrice, PositionGetDouble(POSITION_TP));
               if(!res)
                 {
                  Print("Failed to modify position: ", trade.ResultRetcode());
                 }
              }
           }
        }
     }
  }









// Function to modify stop loss to the low of the previous candle for buy positions
void ModifyStopLossForAllBuyPositions()
  {
// Loop through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      // Get the position ticket and details
      ulong positionTicket = PositionGetTicket(i);
      if(PositionSelectByTicket(positionTicket))
        {
         // Check if it's a buy position
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            // Get the low of the previous candle
            double previousCandleLow = iLow(Symbol(), PERIOD_CURRENT, 1);

            // Get the current stop loss and open price
            double currentStopLoss = PositionGetDouble(POSITION_SL);
            double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);

            // Ensure the new stop loss is valid (below the open price but above the current stop loss)
            if(previousCandleLow < positionOpenPrice && previousCandleLow > currentStopLoss)
              {
               // Modify the position to update the stop loss
               if(trade.PositionModify(positionTicket, previousCandleLow, PositionGetDouble(POSITION_TP)))
                 {
                  Print("Stop loss for Position #", positionTicket, " modified successfully to the low of the previous candle.");
                 }
               else
                 {
                  Print("Error modifying stop loss for Position #", positionTicket, ": ", GetLastError());
                 }
              }
            else
              {
               Print("New stop loss for Position #", positionTicket, " is not valid.");
              }
           }
        }
      else
        {
         Print("Failed to select position with ticket ", positionTicket, ": ", GetLastError());
        }
     }
  }

// Function to modify stop loss to the high of the previous candle for sell positions
void ModifyStopLossForAllSellPositions()
  {
// Loop through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      // Get the position ticket and details
      ulong positionTicket = PositionGetTicket(i);
      if(PositionSelectByTicket(positionTicket))
        {
         // Check if it's a sell position
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            // Get the high of the previous candle
            double previousCandleHigh = iHigh(Symbol(), PERIOD_CURRENT, 1);

            // Get the current stop loss and open price
            double currentStopLoss = PositionGetDouble(POSITION_SL);
            double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);

            // Ensure the new stop loss is valid (above the open price but below the current stop loss)
            if(previousCandleHigh > positionOpenPrice && previousCandleHigh < currentStopLoss)
              {
               // Modify the position to update the stop loss
               if(trade.PositionModify(positionTicket, previousCandleHigh, PositionGetDouble(POSITION_TP)))
                 {
                  Print("Stop loss for Position #", positionTicket, " modified successfully to the high of the previous candle.");
                 }
               else
                 {
                  Print("Error modifying stop loss for Position #", positionTicket, ": ", GetLastError());
                 }
              }
            else
              {
               Print("New stop loss for Position #", positionTicket, " is not valid.");
              }
           }
        }
      else
        {
         Print("Failed to select position with ticket ", positionTicket, ": ", GetLastError());
        }
     }
  }
//+------------------------------------------------------------------+
