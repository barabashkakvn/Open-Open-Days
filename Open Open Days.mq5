//+------------------------------------------------------------------+
//|                                               Open Open Days.mq5 |
//|                              Copyright © 2024, Vladimir Karputov |
//|                      https://www.mql5.com/en/users/barabashkakvn |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2024, Vladimir Karputov"
#property link      "https://www.mql5.com/en/users/barabashkakvn"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers   0
#property indicator_plots     0
//--- input parameters
input string   InpCurrentName    = "Current Day";  // Current Day Line name
input string   InpPreviousName   = "Previous Day"; // Previous Day Line name
//---
datetime m_prev_bars    = 0;                       // "0" -> D'1970.01.01 00:00';
bool     m_error        = false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(Period() >= PERIOD_D1)
     {
      string err_text = "The indicator works on a timeframe LESS than D1!";
      Print(__FILE__, " ", __FUNCTION__, ", ERROR: ", err_text);
      m_error = true;
      return(INIT_SUCCEEDED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   long chart_id = ChartID();
   TrendDelete(chart_id, InpCurrentName);
   TrendDelete(chart_id, InpPreviousName);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(m_error)
      return(0);
//--- we work only at the time of the birth of new bar
   datetime time_0 = time[rates_total - 1];
   if(time_0 == m_prev_bars)
      return(rates_total);
   m_prev_bars = time_0;
//---
   MqlRates rates_d1[];
   ArraySetAsSeries(rates_d1, true);
   int start_pos = 0, count = 6;
   if(CopyRates(Symbol(), PERIOD_D1, start_pos, count, rates_d1) != count)
     {
      m_prev_bars = 0;
      return(rates_total);
     }
//---
   long chart_id = ChartID();
   if(ObjectFind(chart_id, InpCurrentName) < 0)
      if(!TrendCreate(chart_id, InpCurrentName, 0, 0, 0, 0, 0, clrMediumOrchid))
        {
         m_prev_bars = 0;
         return(rates_total);
        }
   if(ObjectFind(chart_id, InpPreviousName) < 0)
      if(!TrendCreate(chart_id, InpPreviousName, 0, 0, 0, 0, 0, clrYellowGreen))
        {
         m_prev_bars = 0;
         return(rates_total);
        }
   TrendPointChange(chart_id, InpCurrentName, 0, rates_d1[1].time, rates_d1[1].open);
   TrendPointChange(chart_id, InpCurrentName, 1, rates_d1[0].time, rates_d1[0].open);
   TrendPointChange(chart_id, InpPreviousName, 0, rates_d1[2].time, rates_d1[2].open);
   TrendPointChange(chart_id, InpPreviousName, 1, rates_d1[1].time, rates_d1[1].open);
   ChartRedraw(chart_id);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Create a trend line by the given coordinates                     |
//+------------------------------------------------------------------+
bool TrendCreate(const long            chart_ID = 0,      // chart's ID
                 const string          name = "TrendLine", // line name
                 const int             sub_window = 0,    // subwindow index
                 datetime              time1 = 0,         // first point time
                 double                price1 = 0,        // first point price
                 datetime              time2 = 0,         // second point time
                 double                price2 = 0,        // second point price
                 const color           clr = clrRed,      // line color
                 const ENUM_LINE_STYLE style = STYLE_SOLID, // line style
                 const int             width = 1,         // line width
                 const bool            back = false,      // in the background
                 const bool            selection = true,  // highlight to move
                 const bool            ray_left = false,  // line's continuation to the left
                 const bool            ray_right = true, // line's continuation to the right
                 const bool            hidden = true,     // hidden in the object list
                 const long            z_order = 0)       // priority for mouse click
  {
//--- set anchor points' coordinates if they are not set
   ChangeTrendEmptyPoints(time1, price1, time2, price2);
//--- reset the error value
   ResetLastError();
//--- create a trend line by the given coordinates
   if(!ObjectCreate(chart_ID, name, OBJ_TREND, sub_window, time1, price1, time2, price2))
     {
      Print(__FUNCTION__,
            ": failed to create a trend line! Error code = ", GetLastError());
      return(false);
     }
//--- set line color
   ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clr);
//--- set line display style
   ObjectSetInteger(chart_ID, name, OBJPROP_STYLE, style);
//--- set line width
   ObjectSetInteger(chart_ID, name, OBJPROP_WIDTH, width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID, name, OBJPROP_BACK, back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, selection);
   ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, selection);
//--- enable (true) or disable (false) the mode of continuation of the line's display to the left
   ObjectSetInteger(chart_ID, name, OBJPROP_RAY_LEFT, ray_left);
//--- enable (true) or disable (false) the mode of continuation of the line's display to the right
   ObjectSetInteger(chart_ID, name, OBJPROP_RAY_RIGHT, ray_right);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID, name, OBJPROP_HIDDEN, hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move trend line anchor point                                     |
//+------------------------------------------------------------------+
bool TrendPointChange(const long   chart_ID = 0,     // chart's ID
                      const string name = "TrendLine", // line name
                      const int    point_index = 0,  // anchor point index
                      datetime     time = 0,         // anchor point time coordinate
                      double       price = 0)        // anchor point price coordinate
  {
//--- if point position is not set, move it to the current bar having Bid price
   if(!time)
      time = TimeCurrent();
   if(!price)
      price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move trend line's anchor point
   if(!ObjectMove(chart_ID, name, point_index, time, price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ", GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| The function deletes the trend line from the chart.              |
//+------------------------------------------------------------------+
bool TrendDelete(const long   chart_ID = 0,     // chart's ID
                 const string name = "TrendLine") // line name
  {
//--- reset the error value
   ResetLastError();
//--- delete a trend line
   if(!ObjectDelete(chart_ID, name))
     {
      Print(__FUNCTION__,
            ": failed to delete a trend line! Error code = ", GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the values of trend line's anchor points and set default   |
//| values for empty ones                                            |
//+------------------------------------------------------------------+
void ChangeTrendEmptyPoints(datetime &time1, double &price1,
                            datetime &time2, double &price2)
  {
//--- if the first point's time is not set, it will be on the current bar
   if(!time1)
      time1 = TimeCurrent();
//--- if the first point's price is not set, it will have Bid value
   if(!price1)
      price1 = SymbolInfoDouble(Symbol(), SYMBOL_BID);
//--- if the second point's time is not set, it is located 9 bars left from the second one
   if(!time2)
     {
      //--- array for receiving the open time of the last 10 bars
      datetime temp[10];
      CopyTime(Symbol(), Period(), time1, 10, temp);
      //--- set the second point 9 bars left from the first one
      time2 = temp[0];
     }
//--- if the second point's price is not set, it is equal to the first point's one
   if(!price2)
      price2 = price1;
  }
//+------------------------------------------------------------------+
