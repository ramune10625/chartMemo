//+------------------------------------------------------------------+
//|                                          ChartMemo_Utils.mqh |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 時間足を文字列に変換する関数                                     |
//+------------------------------------------------------------------+
string TimeframeToString(int tf)
{
    switch(tf)
    {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default:         return (string)tf;
    }
}
