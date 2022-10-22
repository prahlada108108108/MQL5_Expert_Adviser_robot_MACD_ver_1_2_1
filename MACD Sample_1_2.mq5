//+------------------------------------------------------------------+
//|                                                  MACD Sample.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2009-2017, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property version     "5.50"
#property description "It is important to make sure that the expert works with a normal"
#property description "chart and the user did not make any mistakes setting input"
#property description "variables (Lots, TakeProfit, TrailingStop) in our case,"
#property description "we check TakeProfit on a chart of more than 2*trend_period bars"

#define MACD_MAGIC 1234502
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
//---
input double InpLots          =0.1; // Lots
input int    InpTakeProfit    =50;  // Take Profit (in pips)
input int    InpTrailingStop  =30;  // Trailing Stop Level (in pips)
input int    InpMACDOpenLevel =3;   // MACD open level (in pips)
input int    InpMACDCloseLevel=2;   // MACD close level (in pips)
input int    InpMATrendPeriod =26;  // MA trend period
//---
int ExtTimeOut=10; // time out in seconds between trade operations
//+------------------------------------------------------------------+
//| MACD Sample expert class                                         |
//+------------------------------------------------------------------+
class CSampleExpert
  {
protected:
   double            m_adjusted_point;             // point value adjusted for 3 or 5 points
   CTrade            m_trade;                      // trading object
   CSymbolInfo       m_symbol;                     // symbol info object
   CPositionInfo     m_position;                   // trade position object
   CAccountInfo      m_account;                    // account info wrapper
   //--- indicators
   int               m_handle_macd_1;                // MACD indicator handle
   int               m_handle_ema_1;                 // moving average indicator handle
   int               m_handle_macd_2;                // prahlada: macd 2 parameters
   int               m_handle_ema_2;
   int               m_handle_macd_3;                // prahlada: macd 3 parameters
   int               m_handle_ema_3;
   
   
   //--- indicator buffers
   double            m_buff_MACD_main_1[];           // MACD indicator main buffer
   double            m_buff_MACD_signal_1[];         // MACD indicator signal buffer
   double            m_buff_EMA_1[];                 // EMA indicator buffer
      
   double            m_buff_MACD_main_2[];           // MACD indicator main buffer
   double            m_buff_MACD_signal_2[];         // MACD indicator signal buffer
   double            m_buff_EMA_2[];                 // EMA indicator buffer
   
   double            m_buff_MACD_main_3[];           // MACD indicator main buffer
   double            m_buff_MACD_signal_3[];         // MACD indicator signal buffer
   double            m_buff_EMA_3[];                 // EMA indicator buffer
   //--- indicator data for processing
   double            m_macd_current_1;
   double            m_macd_previous_1;
   double            m_signal_current_1;
   double            m_signal_previous_1;
   double            m_ema_current_1;
   double            m_ema_previous_1;
   
   double            m_macd_current_2;
   double            m_macd_previous_2;
   double            m_signal_current_2;
   double            m_signal_previous_2;
   double            m_ema_current_2;
   double            m_ema_previous_2;
   
   double            m_macd_current_3;
   double            m_macd_previous_3;
   double            m_signal_current_3;
   double            m_signal_previous_3;
   double            m_ema_current_3;
   double            m_ema_previous_3;
   //---
   double            m_macd_open_level;
   double            m_macd_close_level;
   double            m_traling_stop;
   double            m_take_profit;
   ENUM_TIMEFRAMES   m_timeframe_1,m_timeframe_2,m_timeframe_3;

public:
                     CSampleExpert(void);
                    ~CSampleExpert(void);
   bool              Init(void);
   void              Deinit(void);
   bool              Processing(void);

protected:
   bool              InitCheckParameters(const int digits_adjust);
   bool              InitIndicators(void);
   bool              LongClosed(void);
   bool              ShortClosed(void);
   bool              LongModified(void);
   bool              ShortModified(void);
   bool              LongOpened(void);
   bool              ShortOpened(void);
  };
//--- global expert
CSampleExpert ExtExpert;
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSampleExpert::CSampleExpert(void) : m_adjusted_point(0),
                                     m_handle_macd_1(INVALID_HANDLE),
                                     m_handle_ema_1(INVALID_HANDLE),
                                     m_macd_current_1(0),
                                     m_macd_previous_1(0),
                                     m_signal_current_1(0),
                                     m_signal_previous_1(0),
                                     m_ema_current_1(0),
                                     m_ema_previous_1(0),
                                     
                                     //prahlada:2nd MACD parameters
                                     m_handle_macd_2(INVALID_HANDLE),
                                     m_handle_ema_2(INVALID_HANDLE),
                                     m_macd_current_2(0),
                                     m_macd_previous_2(0),
                                     m_signal_current_2(0),
                                     m_signal_previous_2(0),
                                     m_ema_current_2(0),
                                     m_ema_previous_2(0),
                                     
                                     //prahlada:3rd MACD parameters
                                     m_handle_macd_3(INVALID_HANDLE),
                                     m_handle_ema_3(INVALID_HANDLE),
                                     m_macd_current_3(0),
                                     m_macd_previous_3(0),
                                     m_signal_current_3(0),
                                     m_signal_previous_3(0),
                                     m_ema_current_3(0),
                                     m_ema_previous_3(0),
                                     
                                     m_macd_open_level(0),
                                     m_macd_close_level(0),
                                     m_traling_stop(0),
                                     m_take_profit(0)
  {
   ArraySetAsSeries(m_buff_MACD_main_1,true);
   ArraySetAsSeries(m_buff_MACD_signal_1,true);
   ArraySetAsSeries(m_buff_EMA_1,true);
   ArraySetAsSeries(m_buff_MACD_main_2,true);
   ArraySetAsSeries(m_buff_MACD_signal_2,true);
   ArraySetAsSeries(m_buff_EMA_2,true);
   ArraySetAsSeries(m_buff_MACD_main_3,true);
   ArraySetAsSeries(m_buff_MACD_signal_3,true);
   ArraySetAsSeries(m_buff_EMA_3,true);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSampleExpert::~CSampleExpert(void)
  {
  }
//+------------------------------------------------------------------+
//| Initialization and checking for input parameters                 |
//+------------------------------------------------------------------+
bool CSampleExpert::Init(void)
  {
//--- initialize common information
   m_symbol.Name(Symbol());                  // symbol
   m_trade.SetExpertMagicNumber(MACD_MAGIC); // magic
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(Symbol());
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
//--- set default deviation for trading in adjusted points
   m_macd_open_level =InpMACDOpenLevel*m_adjusted_point;
   m_macd_close_level=InpMACDCloseLevel*m_adjusted_point;
   m_traling_stop    =InpTrailingStop*m_adjusted_point;
   m_take_profit     =InpTakeProfit*m_adjusted_point;
//--- set default deviation for trading in adjusted points
   m_trade.SetDeviationInPoints(3*digits_adjust);
//---
   if(!InitCheckParameters(digits_adjust))
      return(false);
   if(!InitIndicators())
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking for input parameters                                    |
//+------------------------------------------------------------------+
bool CSampleExpert::InitCheckParameters(const int digits_adjust)
  {
//--- initial data checks
   if(InpTakeProfit*digits_adjust<m_symbol.StopsLevel())
     {
      printf("Take Profit must be greater than %d",m_symbol.StopsLevel());
      return(false);
     }
   if(InpTrailingStop*digits_adjust<m_symbol.StopsLevel())
     {
      printf("Trailing Stop must be greater than %d",m_symbol.StopsLevel());
      return(false);
     }
//--- check for right lots amount
   if(InpLots<m_symbol.LotsMin() || InpLots>m_symbol.LotsMax())
     {
      printf("Lots amount must be in the range from %f to %f",m_symbol.LotsMin(),m_symbol.LotsMax());
      return(false);
     }
   if(MathAbs(InpLots/m_symbol.LotsStep()-MathRound(InpLots/m_symbol.LotsStep()))>1.0E-10)
     {
      printf("Lots amount is not corresponding with lot step %f",m_symbol.LotsStep());
      return(false);
     }
//--- warning
   if(InpTakeProfit<=InpTrailingStop)
      printf("Warning: Trailing Stop must be less than Take Profit");
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization of the indicators                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::InitIndicators(void)
  {
//--- create MACD indicator
   if(m_handle_macd_1==INVALID_HANDLE)
      if((m_handle_macd_1=iMACD(NULL,0,12,26,9,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating MACD indicator for %f",m_timeframe_1);
         return(false);
        }
//--- create EMA indicator and add it to collection
   if(m_handle_ema_1==INVALID_HANDLE)
      if((m_handle_ema_1=iMA(NULL,0,InpMATrendPeriod,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating EMA indicator for %f",m_timeframe_1));
         return(false);
        }
//prahlada: init 2nd indicators
   if(m_handle_macd_2==INVALID_HANDLE)
      if((m_handle_macd_2=iMACD(NULL,0,12,26,9,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating MACD indicator for %f",m_timeframe_2);
         return(false);
        }
   if(m_handle_ema_2==INVALID_HANDLE)
      if((m_handle_ema_2=iMA(NULL,0,InpMATrendPeriod,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating EMA indicator for %f",m_timeframe_2));
         return(false);
        }
//prahlada: init 3rd indicators        
   if(m_handle_macd_3==INVALID_HANDLE)
      if((m_handle_macd_3=iMACD(NULL,0,12,26,9,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating MACD indicator for %f",m_timeframe_3);
         return(false);
        }
   if(m_handle_ema_3==INVALID_HANDLE)
      if((m_handle_ema_3=iMA(NULL,0,InpMATrendPeriod,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating EMA indicator for %f",m_timeframe_3));
         return(false);
        }
//--- succeed        
   return(true);
  }
//+------------------------------------------------------------------+
//| Check for long position closing                                  |
//+------------------------------------------------------------------+
bool CSampleExpert::LongClosed(void)
  {
   bool res=false;
//--- should it be closed?
   if(m_macd_current>0)
      if(m_macd_current<m_signal_current && m_macd_previous>m_signal_previous)
         if(m_macd_current>m_macd_close_level)
           {
            //--- close position
            if(m_trade.PositionClose(Symbol()))
               printf("Long position by %s to be closed",Symbol());
            else
               printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
            //--- processed and cannot be modified
            res=true;
           }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position closing                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::ShortClosed(void)
  {
   bool res=false;
//--- should it be closed?
   if(m_macd_current<0)
      if(m_macd_current>m_signal_current && m_macd_previous<m_signal_previous)
         if(MathAbs(m_macd_current)>m_macd_close_level)
           {
            //--- close position
            if(m_trade.PositionClose(Symbol()))
               printf("Short position by %s to be closed",Symbol());
            else
               printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
            //--- processed and cannot be modified
            res=true;
           }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for long position modifying                                |
//+------------------------------------------------------------------+
bool CSampleExpert::LongModified(void)
  {
   bool res=false;
//--- check for trailing stop
   if(InpTrailingStop>0)
     {
      if(m_symbol.Bid()-m_position.PriceOpen()>m_adjusted_point*InpTrailingStop)
        {
         double sl=NormalizeDouble(m_symbol.Bid()-m_traling_stop,m_symbol.Digits());
         double tp=m_position.TakeProfit();
         if(m_position.StopLoss()<sl || m_position.StopLoss()==0.0)
           {
            //--- modify position
            if(m_trade.PositionModify(Symbol(),sl,tp))
               printf("Long position by %s to be modified",Symbol());
            else
              {
               printf("Error modifying position by %s : '%s'",Symbol(),m_trade.ResultComment());
               printf("Modify parameters : SL=%f,TP=%f",sl,tp);
              }
            //--- modified and must exit from expert
            res=true;
           }
        }
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position modifying                               |
//+------------------------------------------------------------------+
bool CSampleExpert::ShortModified(void)
  {
   bool   res=false;
//--- check for trailing stop
   if(InpTrailingStop>0)
     {
      if((m_position.PriceOpen()-m_symbol.Ask())>(m_adjusted_point*InpTrailingStop))
        {
         double sl=NormalizeDouble(m_symbol.Ask()+m_traling_stop,m_symbol.Digits());
         double tp=m_position.TakeProfit();
         if(m_position.StopLoss()>sl || m_position.StopLoss()==0.0)
           {
            //--- modify position
            if(m_trade.PositionModify(Symbol(),sl,tp))
               printf("Short position by %s to be modified",Symbol());
            else
              {
               printf("Error modifying position by %s : '%s'",Symbol(),m_trade.ResultComment());
               printf("Modify parameters : SL=%f,TP=%f",sl,tp);
              }
            //--- modified and must exit from expert
            res=true;
           }
        }
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for long position opening                                  |
//+------------------------------------------------------------------+
bool CSampleExpert::LongOpened(void)
  {
   bool res=false;
//--- check for long position (BUY) possibility
   if(m_macd_current<0)
      if(m_macd_current>m_signal_current && m_macd_previous<m_signal_previous) 
      //prahlada: conditions for opening here - better make a call for modules later
         if(MathAbs(m_macd_current)>(m_macd_open_level) && m_ema_current>m_ema_previous)
           {
            double price=m_symbol.Ask();
            double tp   =m_symbol.Bid()+m_take_profit;
            //--- check for free money
            if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_BUY,InpLots,price)<0.0)
               printf("We have no money. Free Margin = %f",m_account.FreeMargin());
            else
              {
               //--- open position
               if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,InpLots,price,0.0,tp))
                  printf("Position by %s to be opened",Symbol());
               else
                 {
                  printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
                  printf("Open parameters : price=%f,TP=%f",price,tp);
                 }
              }
            //--- in any case we must exit from expert
            res=true;
           }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position opening                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::ShortOpened(void)
  {
   bool res=false;
//--- check for short position (SELL) possibility
   if(m_macd_current>0)
      if(m_macd_current<m_signal_current && m_macd_previous>m_signal_previous)
         if(m_macd_current>(m_macd_open_level) && m_ema_current<m_ema_previous)
           {
            double price=m_symbol.Bid();
            double tp   =m_symbol.Ask()-m_take_profit;
            //--- check for free money
            if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_SELL,InpLots,price)<0.0)
               printf("We have no money. Free Margin = %f",m_account.FreeMargin());
            else
              {
               //--- open position
               if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,InpLots,price,0.0,tp))
                  printf("Position by %s to be opened",Symbol());
               else
                 {
                  printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
                  printf("Open parameters : price=%f,TP=%f",price,tp);
                 }
              }
            //--- in any case we must exit from expert
            res=true;
           }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| main function returns true if any position processed             |
//+------------------------------------------------------------------+
bool CSampleExpert::Processing(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- refresh indicators
   if(BarsCalculated(m_handle_macd)<2 || BarsCalculated(m_handle_ema)<2)
      return(false);
   if(CopyBuffer(m_handle_macd,0,0,2,m_buff_MACD_main)  !=2 ||
      CopyBuffer(m_handle_macd,1,0,2,m_buff_MACD_signal)!=2 ||
      CopyBuffer(m_handle_ema,0,0,2,m_buff_EMA)         !=2)
      return(false);
//   m_indicators.Refresh();
//--- to simplify the coding and speed up access
//--- data are put into internal variables
   m_macd_current   =m_buff_MACD_main[0];
   m_macd_previous  =m_buff_MACD_main[1];
   m_signal_current =m_buff_MACD_signal[0];
   m_signal_previous=m_buff_MACD_signal[1];
   m_ema_current    =m_buff_EMA[0];
   m_ema_previous   =m_buff_EMA[1];
//--- it is important to enter the market correctly, 
//--- but it is more important to exit it correctly...   
//--- first check if position exists - try to select it
   if(m_position.Select(Symbol()))
     {
      if(m_position.PositionType()==POSITION_TYPE_BUY)
        {
         //--- try to close or modify long position
         if(LongClosed())
            return(true);
         if(LongModified())
            return(true);
        }
      else
        {
         //--- try to close or modify short position
         if(ShortClosed())
            return(true);
         if(ShortModified())
            return(true);
        }
     }
//--- no opened position identified
   else
     {
      //--- check for long position (BUY) possibility
      if(LongOpened())
         return(true);
      //--- check for short position (SELL) possibility
      if(ShortOpened())
         return(true);
     }
//--- exit without position processing
   return(false);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- create all necessary objects
   if(!ExtExpert.Init())
      return(INIT_FAILED);
//--- secceed
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert new tick handling function                                |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   static datetime limit_time=0; // last trade processing time + timeout
//--- don't process if timeout
   if(TimeCurrent()>=limit_time)
     {
      //--- check for data
      if(Bars(Symbol(),m_timeframe_1)>2*InpMATrendPeriod
         && Bars(Symbol(),m_timeframe_2)>2*InpMATrendPeriod
         && Bars(Symbol(),m_timeframe_3)>2*InpMATrendPeriod)
        {
         //--- change limit time by timeout in seconds if processed
         if(ExtExpert.Processing())
            limit_time=TimeCurrent()+ExtTimeOut;
        }
     }
  }
//+------------------------------------------------------------------+
