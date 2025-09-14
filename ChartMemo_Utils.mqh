//+------------------------------------------------------------------+
//|                                        ChartMemo_Utils.mqh |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Takafumi (via Gemini CLI)"
#property link      ""

// Windows APIのインポート
#import "user32.dll"
void keybd_event(int bVk, int bScan, int dwFlags, int dwExtraInfo);
#import "kernel32.dll"
int Sleep(int dwMilliseconds);
#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

// キーイベントの定数
#define KEYEVENTF_KEYUP 0x0002
#define VK_MENU 18 // Altキー
#define VK_SNAPSHOT 44 // PrintScreenキー

//+------------------------------------------------------------------+
//| アクティブウィンドウのスクリーンショットをクリップボードにコピーする     |
//+------------------------------------------------------------------+
void CaptureActiveWindowToClipboard()
{
    // Alt + PrintScreen を押す
    keybd_event(VK_MENU, 0, 0, 0);
    keybd_event(VK_SNAPSHOT, 0, 0, 0);
    Sleep(250); // OSがクリップボードにコピーするのを少し待つ
    keybd_event(VK_SNAPSHOT, 0, KEYEVENTF_KEYUP, 0);
    keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
}


//+------------------------------------------------------------------+
//| MQL4の時間枠定数を文字列に変換する                               |
//+------------------------------------------------------------------+
string TimeframeToString(int timeframe)
{
    switch(timeframe)
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
        default:         return "Unknown";
    }
}

