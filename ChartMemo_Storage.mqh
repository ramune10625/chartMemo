//+------------------------------------------------------------------+
//|                                       ChartMemo_Storage.mqh |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+

#include "ChartMemo_Defines.mqh"

//+------------------------------------------------------------------+
//| データをCSVファイルに保存する関数                                |
//+------------------------------------------------------------------+
void SaveCsvFiles()
{
    // 変数宣言を関数の先頭に移動
    string startTime, startPrice, endTime, endPrice;

    // GetMicrosecondCount()を使用してユニークなIDを生成
    string tradeId = (string)GetMicrosecondCount();

    string tradeTimeframeStr = TimeframeToString(g_chartData.session.tradeAreaTimeframe);
    // TradeAreaが描画されていない場合も考慮
    if (g_chartData.session.tradeAreaTimeframe == 0) {
        tradeTimeframeStr = TimeframeToString((int)Period()); // 現在のチャートの時間足を使用
    }
    // ファイル名とパスを生成
    string cleanSymbol = Symbol();
    StringReplace(cleanSymbol, "/", "-"); // ファイル名として無効な'/'を'-'に置換

    // tradeIdをファイル名に使用して一意性を保証
    string screenshotFile = cleanSymbol + "_" + tradeTimeframeStr + "_" + tradeId + ".png";
    string dirName = "ChartMemo";

    // Ensure the directory exists by opening and closing a dummy file
    string dummyPath = dirName + "\\dummy.txt";
    int handle = FileOpen(dummyPath, FILE_WRITE);
    if(handle != INVALID_HANDLE)
    {
        FileClose(handle);
        FileDelete(dummyPath);
    }

    string screenshotPath = dirName + "\\" + screenshotFile;

    Print("ChartMemo Path: ", screenshotPath);

    // --- チャート画像を保存 (代替方法) ---
    CaptureActiveWindowToClipboard();
    Sleep(500); // クリップボードに画像が格納されるのを待つ

    string psScriptPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files\\save_clipboard.ps1";
    // PowerShellに渡すファイルパスを、MQL4\Filesからのフルパスに修正
    string absoluteScreenshotPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files\\" + screenshotPath;

    string command = "powershell.exe";
    // -ExecutionPolicy Bypass: 実行ポリシーを一時的に回避
    // -File: 実行するスクリプトファイル
    // -filePath: スクリプトに渡す引数（保存先のフルパス）
    string parameters = "-ExecutionPolicy Bypass -File \"" + psScriptPath + "\" -filePath \"" + absoluteScreenshotPath + "\"";

    // ShellExecuteWでPowerShellを非表示で実行 (SW_HIDE = 0)
    int result = ShellExecuteW(0, "open", command, parameters, "", 0);
    if(result <= 32) // ShellExecuteWは成功すると32より大きい値を返す
    {
        Print("ChartMemo: Failed to execute PowerShell script to save screenshot. Result code: ", result, ", Last Error: ", GetLastError());
    }
    else
    {
        Print("ChartMemo: Screenshot command executed via PowerShell.");
    }

    // --- trades.csvへの書き込み ---
    string tradesPath = dirName + "\\trades.csv";
    int tradesHandle = FileOpen(tradesPath, FILE_READ|FILE_WRITE|FILE_SHARE_WRITE|FILE_UNICODE);

    if(tradesHandle != INVALID_HANDLE)
    {
        if(FileSize(tradesHandle) <= 0)
        {
            FileWrite(tradesHandle, 255); // Write UTF-16LE BOM
            FileWrite(tradesHandle, 254); // Write UTF-16LE BOM
            FileWriteString(tradesHandle, "TradeID,Timestamp,Symbol,Timeframe,GlobalComment,ScreenshotFile,TradeArea_StartTime,TradeArea_StartPrice,TradeArea_EndTime,TradeArea_EndPrice\n");
        }

        FileSeek(tradesHandle, 0, SEEK_END);

        string tradeAreaName = CharArrayToString(g_chartData.session.tradeAreaRectName);
        // 使用前に初期化
        startTime = "N/A"; startPrice = "N/A"; endTime = "N/A"; endPrice = "N/A";
        if(ObjectFind(0, tradeAreaName) >= 0)
        {
            startTime  = TimeToString((datetime)ObjectGetInteger(0, tradeAreaName, OBJPROP_TIME, 0), "yyyy.MM.dd HH:mm:ss");
            startPrice = DoubleToString(ObjectGetDouble(0, tradeAreaName, OBJPROP_PRICE, 0), _Digits);
            endTime    = TimeToString((datetime)ObjectGetInteger(0, tradeAreaName, OBJPROP_TIME, 1), "yyyy.MM.dd HH:mm:ss");
            endPrice   = DoubleToString(ObjectGetDouble(0, tradeAreaName, OBJPROP_PRICE, 1), _Digits);
        }

        string globalComment = StringSubstr(CharArrayToString(g_chartData.session.globalComment), 0, GLOBAL_COMMENT_LENGTH -1);
        StringReplace(globalComment, "\"", "\"\""); // Correct CSV quote escaping

        string tradeLine = StringFormat("%s,%s,%s,%s,\"%s\",%s,%s,%s,%s,%s\n",
                           tradeId,
                           TimeToString(TimeCurrent(), "yyyy.MM.dd HH:mm:ss"),
                           Symbol(),
                           tradeTimeframeStr,
                           globalComment,
                           screenshotFile,
                           startTime,
                           startPrice,
                           endTime,
                           endPrice);

        FileWriteString(tradesHandle, tradeLine);
        FileClose(tradesHandle);
    }
    else
    {
        Print("ChartMemo: Error opening trades.csv. Error code: ", GetLastError());
    }

    // --- evidence.csvへの書き込み ---
    string evidencePath = dirName + "\\evidence.csv";
    int evidenceHandle = FileOpen(evidencePath, FILE_READ|FILE_WRITE|FILE_SHARE_WRITE|FILE_UNICODE);

    if(evidenceHandle != INVALID_HANDLE)
    {
        if(FileSize(evidenceHandle) <= 0)
        {
            FileWrite(evidenceHandle, 255); // Write UTF-16LE BOM
            FileWrite(evidenceHandle, 254); // Write UTF-16LE BOM
            FileWriteString(evidenceHandle, "EvidenceID,TradeID,EvidenceNumber,EvidenceTimeframe,EvidenceComment,EvidenceArea_StartTime,EvidenceArea_StartPrice,EvidenceArea_EndTime,EvidenceArea_EndPrice\n");
        }

        FileSeek(evidenceHandle, 0, SEEK_END);

        for(int i = 0; i < g_chartData.session.evidenceCount; i++)
        {
            string evidenceId = tradeId + "_" + (string)(i+1);
            string evidenceTimeframeStr = TimeframeToString(g_chartData.evidences[i].timeframe);

            string rectName = CharArrayToString(g_chartData.evidences[i].rectName);
            // 使用前に初期化
            startTime = "N/A"; startPrice = "N/A"; endTime = "N/A"; endPrice = "N/A";
            if(ObjectFind(0, rectName) >= 0)
            {
                startTime  = TimeToString((datetime)ObjectGetInteger(0, rectName, OBJPROP_TIME, 0), "yyyy.MM.dd HH:mm:ss");
                startPrice = DoubleToString(ObjectGetDouble(0, rectName, OBJPROP_PRICE, 0), _Digits);
                endTime    = TimeToString((datetime)ObjectGetInteger(0, rectName, OBJPROP_TIME, 1), "yyyy.MM.dd HH:mm:ss");
                endPrice   = DoubleToString(ObjectGetDouble(0, rectName, OBJPROP_PRICE, 1), _Digits);
            }
            
            string evidenceComment = StringSubstr(CharArrayToString(g_chartData.evidences[i].comment), 0, COMMENT_LENGTH - 1);
            StringReplace(evidenceComment, "\"", "\"\""); // Correct CSV quote escaping

            

            string evidenceLine = StringFormat("%s,%s,%d,%s,%s,%s,%s,%s,%s\n",
                                  evidenceId,
                                  tradeId,
                                  i + 1,
                                  evidenceTimeframeStr,
                                  evidenceComment,
                                  startTime,
                                  startPrice,
                                  endTime,
                                  endPrice);

            FileWriteString(evidenceHandle, evidenceLine);
        }
        FileClose(evidenceHandle);
    }
    else
    {
        Print("ChartMemo: Error opening evidence.csv. Error code: ", GetLastError());
    }
    Print("ChartMemo: データをCSVに保存しました。");
}



//+------------------------------------------------------------------+
//| セッションの状態を保存する関数                                     |
//+------------------------------------------------------------------+
void SaveState()
{
    int handle = FileOpen(STATE_FILE_NAME, FILE_WRITE|FILE_BIN);
    if(handle != INVALID_HANDLE)
    {
        FileWriteStruct(handle, g_chartData);
        FileClose(handle);
    }
}


//+------------------------------------------------------------------+
//| セッションの状態を復元する関数                                     |
//+------------------------------------------------------------------+
void LoadState()
{
    // ファイルが存在しない場合は初期化
    if(!FileIsExist(STATE_FILE_NAME))
    {
        ZeroMemory(g_chartData); // 構造体をゼロクリア
        return;
    }

    int handle = FileOpen(STATE_FILE_NAME, FILE_READ|FILE_BIN);
    if(handle != INVALID_HANDLE)
    {
        FileReadStruct(handle, g_chartData);
        FileClose(handle);
    }
}