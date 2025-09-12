//+------------------------------------------------------------------+
//|                                                    ChartMemo.mq4 |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Takafumi (via Gemini CLI)"
#property link      ""
#property version   "1.72" // Bug fixes for compilation
#property strict

#define STATE_FILE_NAME "ChartMemo_State.bin" // 状態保存ファイル名 (バイナリ)

//--- インジケーターを別のウィンドウではなく、メインチャートに表示
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//--- オブジェクト名のプレフィックス
#define OBJ_PREFIX "ChartMemo_"

//--- UIの座標とサイズ
#define PANEL_X 10
#define PANEL_Y 25
#define PANEL_WIDTH 300
#define PANEL_HEIGHT 550 // パネルサイズを拡大
#define BUTTON_WIDTH 140
#define BUTTON_HEIGHT 25
#define PADDING 10
#define COMMENT_EDIT_HEIGHT 40

// --- 構造体定義 ---
#define MAX_EVIDENCE_COUNT 5
#define OBJECT_NAME_LENGTH 64
#define COMMENT_LENGTH 256
#define GLOBAL_COMMENT_LENGTH 1024

// 根拠エリアの情報
struct Evidence
{
    char rectName[OBJECT_NAME_LENGTH];
    char labelName[OBJECT_NAME_LENGTH];
    char comment[COMMENT_LENGTH]; // 根拠コメント
    int  timeframe;               // 描画された時間足
};

// セッション全体の状態を管理する構造体
struct SessionState
{
    bool   isSessionActive;
    int    evidenceCount;
    char   tradeAreaRectName[OBJECT_NAME_LENGTH];
    int    tradeAreaTimeframe;                   // トレードエリアが描画された時間足
    char   globalComment[GLOBAL_COMMENT_LENGTH]; // 全体コメント
};

// ファイルに保存する全データ
struct ChartMemoData
{
    SessionState session;
    Evidence     evidences[MAX_EVIDENCE_COUNT];
};


//--- グローバル変数 ---
ChartMemoData g_chartData;            // 全セッションデータ
string        g_drawingMode = "";     // 描画モード (UIの一時的な状態)


//--- プロトタイプ宣言 ---
void UpdateUIState();
void UpdateCommentUI();
void FinalizeEvidenceObject(string objectName);
void FinalizeTradeAreaObject(string objectName);
void ResetSession();
void DeleteDrawnObjects();
void DeleteLastEvidence();
void SaveState();
void LoadState();
void SaveCsvFiles();
void CleanupSession();
string TimeframeToString(int tf);

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- チャートイベントの有効化 ---
    ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, true);

    //--- 状態を復元 ---
    LoadState();

    //--- フォント設定 ---
    string font = "Yu Gothic UI";
    int fontSize = 9;

    //--- メインパネル ---
    string panelName = OBJ_PREFIX + "Panel";
    ObjectCreate(0, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, panelName, OBJPROP_XDISTANCE, PANEL_X);
    ObjectSetInteger(0, panelName, OBJPROP_YDISTANCE, PANEL_Y);
    ObjectSetInteger(0, panelName, OBJPROP_XSIZE, PANEL_WIDTH);
    ObjectSetInteger(0, panelName, OBJPROP_YSIZE, PANEL_HEIGHT);
    ObjectSetInteger(0, panelName, OBJPROP_BGCOLOR, clrWhiteSmoke);
    ObjectSetInteger(0, panelName, OBJPROP_BORDER_COLOR, clrSilver);
    ObjectSetInteger(0, panelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, panelName, OBJPROP_BACK, false);
    ObjectSetInteger(0, panelName, OBJPROP_SELECTABLE, false);

    //--- ボタン ---
    int y_offset = PANEL_Y + PADDING;

    // 記録セッション開始ボタン
    string startButtonName = OBJ_PREFIX + "StartButton";
    ObjectCreate(0, startButtonName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, startButtonName, OBJPROP_XDISTANCE, PANEL_X + PADDING);
    ObjectSetInteger(0, startButtonName, OBJPROP_YDISTANCE, y_offset);
    ObjectSetInteger(0, startButtonName, OBJPROP_XSIZE, BUTTON_WIDTH);
    ObjectSetInteger(0, startButtonName, OBJPROP_YSIZE, BUTTON_HEIGHT);
    ObjectSetString(0, startButtonName, OBJPROP_TEXT, "記録セッション開始");
    ObjectSetInteger(0, startButtonName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, startButtonName, OBJPROP_BACK, false);
    ObjectSetString(0, startButtonName, OBJPROP_FONT, font);
    ObjectSetInteger(0, startButtonName, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, startButtonName, OBJPROP_SELECTABLE, false);

    y_offset += BUTTON_HEIGHT + PADDING;

    // 根拠エリア追加ボタン
    string addEvidenceButtonName = OBJ_PREFIX + "AddEvidenceButton";
    ObjectCreate(0, addEvidenceButtonName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, addEvidenceButtonName, OBJPROP_XDISTANCE, PANEL_X + PADDING);
    ObjectSetInteger(0, addEvidenceButtonName, OBJPROP_YDISTANCE, y_offset);
    ObjectSetInteger(0, addEvidenceButtonName, OBJPROP_XSIZE, BUTTON_WIDTH);
    ObjectSetInteger(0, addEvidenceButtonName, OBJPROP_YSIZE, BUTTON_HEIGHT);
    ObjectSetString(0, addEvidenceButtonName, OBJPROP_TEXT, "根拠エリア追加");
    ObjectSetInteger(0, addEvidenceButtonName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, addEvidenceButtonName, OBJPROP_BACK, false);
    ObjectSetString(0, addEvidenceButtonName, OBJPROP_FONT, font);
    ObjectSetInteger(0, addEvidenceButtonName, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, addEvidenceButtonName, OBJPROP_SELECTABLE, false);

    // 最後の根拠を削除ボタン
    string deleteLastButtonName = OBJ_PREFIX + "DeleteLastButton";
    ObjectCreate(0, deleteLastButtonName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, deleteLastButtonName, OBJPROP_XDISTANCE, PANEL_X + PADDING + BUTTON_WIDTH + PADDING);
    ObjectSetInteger(0, deleteLastButtonName, OBJPROP_YDISTANCE, y_offset);
    ObjectSetInteger(0, deleteLastButtonName, OBJPROP_XSIZE, BUTTON_WIDTH);
    ObjectSetInteger(0, deleteLastButtonName, OBJPROP_YSIZE, BUTTON_HEIGHT);
    ObjectSetString(0, deleteLastButtonName, OBJPROP_TEXT, "最後の根拠を削除");
    ObjectSetInteger(0, deleteLastButtonName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, deleteLastButtonName, OBJPROP_BACK, false);
    ObjectSetString(0, deleteLastButtonName, OBJPROP_FONT, font);
    ObjectSetInteger(0, deleteLastButtonName, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, deleteLastButtonName, OBJPROP_SELECTABLE, false);

    y_offset += BUTTON_HEIGHT + PADDING;

    // トレードエリア追加ボタン
    string addTradeButtonName = OBJ_PREFIX + "AddTradeButton";
    ObjectCreate(0, addTradeButtonName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, addTradeButtonName, OBJPROP_XDISTANCE, PANEL_X + PADDING);
    ObjectSetInteger(0, addTradeButtonName, OBJPROP_YDISTANCE, y_offset);
    ObjectSetInteger(0, addTradeButtonName, OBJPROP_XSIZE, BUTTON_WIDTH);
    ObjectSetInteger(0, addTradeButtonName, OBJPROP_YSIZE, BUTTON_HEIGHT);
    ObjectSetString(0, addTradeButtonName, OBJPROP_TEXT, "トレードエリア追加");
    ObjectSetInteger(0, addTradeButtonName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, addTradeButtonName, OBJPROP_BACK, false);
    ObjectSetString(0, addTradeButtonName, OBJPROP_FONT, font);
    ObjectSetInteger(0, addTradeButtonName, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, addTradeButtonName, OBJPROP_SELECTABLE, false);

    // --- 全体コメントエリア ---
    y_offset += BUTTON_HEIGHT + PADDING * 2;
    string globalCommentLabelName = OBJ_PREFIX + "GlobalCommentLabel";
    ObjectCreate(0, globalCommentLabelName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, globalCommentLabelName, OBJPROP_XDISTANCE, PANEL_X + PADDING);
    ObjectSetInteger(0, globalCommentLabelName, OBJPROP_YDISTANCE, y_offset);
    ObjectSetString(0, globalCommentLabelName, OBJPROP_TEXT, "全体コメント:");
    ObjectSetInteger(0, globalCommentLabelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, globalCommentLabelName, OBJPROP_BACK, false);
    ObjectSetString(0, globalCommentLabelName, OBJPROP_FONT, font);
    ObjectSetInteger(0, globalCommentLabelName, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, globalCommentLabelName, OBJPROP_SELECTABLE, false);

    y_offset += 15;
    string globalCommentEditName = OBJ_PREFIX + "GlobalCommentEdit";
    ObjectCreate(0, globalCommentEditName, OBJ_EDIT, 0, 0, 0);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_XDISTANCE, PANEL_X + PADDING);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_YDISTANCE, y_offset);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_XSIZE, PANEL_WIDTH - PADDING * 2);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_YSIZE, 100);
    ObjectSetString(0, globalCommentEditName, OBJPROP_TEXT, CharArrayToString(g_chartData.session.globalComment));
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_BORDER_COLOR, clrGray);
    ObjectSetString(0, globalCommentEditName, OBJPROP_FONT, font);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_FONTSIZE, fontSize);

    // --- 完了ボタン ---
    string completeButtonName = OBJ_PREFIX + "CompleteButton";
    ObjectCreate(0, completeButtonName, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, completeButtonName, OBJPROP_XDISTANCE, PANEL_X + PADDING);
    ObjectSetInteger(0, completeButtonName, OBJPROP_YDISTANCE, PANEL_Y + PANEL_HEIGHT - BUTTON_HEIGHT - PADDING);
    ObjectSetInteger(0, completeButtonName, OBJPROP_XSIZE, PANEL_WIDTH - PADDING * 2);
    ObjectSetInteger(0, completeButtonName, OBJPROP_YSIZE, BUTTON_HEIGHT);
    ObjectSetString(0, completeButtonName, OBJPROP_TEXT, "セッションを完了して記録");
    ObjectSetInteger(0, completeButtonName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, completeButtonName, OBJPROP_BACK, false);
    ObjectSetString(0, completeButtonName, OBJPROP_FONT, font);
    ObjectSetInteger(0, completeButtonName, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, completeButtonName, OBJPROP_SELECTABLE, false);

    //--- UIの初期状態を設定 ---
    UpdateCommentUI();
    UpdateUIState();
    ChartRedraw();
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- イベントを無効化 ---
    ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, false);

    // 時間足の変更や再コンパイルが理由の場合は、オブジェクトを削除せずに終了
    if (reason == REASON_CHARTCHANGE || reason == REASON_RECOMPILE) {
        return;
    }
    
    //--- インジケーター削除時のクリーンアップ ---
    DeleteDrawnObjects();
    ObjectsDeleteAll(0, OBJ_PREFIX);
    FileDelete(STATE_FILE_NAME); // 一時ファイルを削除
    ChartRedraw();
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
    return(rates_total);
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    //--- ボタンクリックイベント ---
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == OBJ_PREFIX + "StartButton")
        {
            g_chartData.session.isSessionActive = true;
            ResetSession();
            UpdateUIState();
            Print("ChartMemo: 記録セッションを開始しました。");
        }
        else if(sparam == OBJ_PREFIX + "CompleteButton")
        {
            g_chartData.session.isSessionActive = false;

            // --- コメントを一括取得 ---
            string globalComment = ObjectGetString(0, OBJ_PREFIX + "GlobalCommentEdit", OBJPROP_TEXT);
            StringToCharArray(globalComment, g_chartData.session.globalComment);

            for (int i = 0; i < g_chartData.session.evidenceCount; i++) {
                string edit_name = OBJ_PREFIX + "EvidenceCommentEdit_" + (string)(i + 1);
                string comment = ObjectGetString(0, edit_name, OBJPROP_TEXT);
                StringToCharArray(comment, g_chartData.evidences[i].comment);
            }

            SaveCsvFiles();      // CSVに保存
            CleanupSession();    // オブジェクトと内部データをクリーンアップ
            UpdateUIState();     // ボタンの状態を更新
            SaveState();         // クリーンな状態を保存
            
            Print("ChartMemo: 記録セッションを完了し、データを保存しました。");
        }
        else if(sparam == OBJ_PREFIX + "AddEvidenceButton")
        {
            g_drawingMode = "evidence";
            Print("描画モード: 根拠エリア(青)を描画");
        }
        else if(sparam == OBJ_PREFIX + "AddTradeButton")
        {
            g_drawingMode = "trade";
            Print("描画モード: トレードエリア(赤)を描画");
        }
        else if(sparam == OBJ_PREFIX + "DeleteLastButton")
        {
            DeleteLastEvidence();
        }
        return;
    }

    //--- オブジェクト作成イベント ---
    if(id == CHARTEVENT_OBJECT_CREATE)
    {
        if(g_drawingMode == "evidence" && ObjectGetInteger(0, sparam, OBJPROP_TYPE) == OBJ_RECTANGLE)
        {
            FinalizeEvidenceObject(sparam);
            g_drawingMode = ""; // 描画モードをリセット
        }
        else if(g_drawingMode == "trade" && ObjectGetInteger(0, sparam, OBJPROP_TYPE) == OBJ_RECTANGLE)
        {
            FinalizeTradeAreaObject(sparam);
            g_drawingMode = ""; // 描画モードをリセット
        }
    }
}

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

//+------------------------------------------------------------------+
//| データをCSVファイルに保存する関数                                |
//+------------------------------------------------------------------+
void SaveCsvFiles()
{
    // 変数宣言を関数の先頭に移動
    string startTime, startPrice, endTime, endPrice;

    string tradeId = (string)TimeCurrent();
    string tradeTimeframeStr = TimeframeToString(g_chartData.session.tradeAreaTimeframe);
    // TradeAreaが描画されていない場合も考慮
    if (g_chartData.session.tradeAreaTimeframe == 0) {
        tradeTimeframeStr = TimeframeToString((int)Period()); // 現在のチャートの時間足を使用
    }
    string screenshotFile = Symbol() + "_" + tradeTimeframeStr + "_" + tradeId + ".png";
    string dirName = "ChartMemo";
    string screenshotPath = dirName + "\\" + screenshotFile;

    // --- チャート画像を保存 ---
    if(!ChartScreenShot(0, screenshotPath, 0, 0, ALIGN_RIGHT))
    {
        Print("ChartMemo: Error saving screenshot. Error code: ", GetLastError());
    }

    // --- trades.csvへの書き込み ---
    string tradesPath = dirName + "\\trades.csv";
    int tradesHandle = FileOpen(tradesPath, FILE_READ|FILE_WRITE|FILE_SHARE_WRITE);

    if(tradesHandle != INVALID_HANDLE)
    {
        if(FileSize(tradesHandle) <= 0)
        {
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
        StringReplace(globalComment, "\"", "\\\""); // Correct CSV quote escaping

        string tradeLine = tradeId + "," +
                           TimeToString(TimeCurrent(), "yyyy.MM.dd HH:mm:ss") + "," +
                           Symbol() + "," +
                           tradeTimeframeStr + "," +
                           "\"" + globalComment + "\"," +
                           screenshotFile + "," +
                           startTime + "," + startPrice + "," + endTime + "," + endPrice + "\n";

        FileWriteString(tradesHandle, tradeLine);
        FileClose(tradesHandle);
    }
    else
    {
        Print("ChartMemo: Error opening trades.csv. Error code: ", GetLastError());
    }

    // --- evidence.csvへの書き込み ---
    string evidencePath = dirName + "\\evidence.csv";
    int evidenceHandle = FileOpen(evidencePath, FILE_READ|FILE_WRITE|FILE_SHARE_WRITE);

    if(evidenceHandle != INVALID_HANDLE)
    {
        if(FileSize(evidenceHandle) <= 0)
        {
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
            StringReplace(evidenceComment, "\"", "\\\""); // Correct CSV quote escaping

            string evidenceLine = evidenceId + "," +
                                  tradeId + "," +
                                  (string)(i+1) + "," +
                                  evidenceTimeframeStr + "," +
                                  "\"" + evidenceComment + "\"," +
                                  startTime + "," + startPrice + "," + endTime + "," + endPrice + "\n";

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
//| セッション完了後にクリーンアップする関数                         |
//+------------------------------------------------------------------+
void CleanupSession()
{
    DeleteDrawnObjects();
    g_drawingMode = "";
    ZeroMemory(g_chartData);
    ObjectSetString(0, OBJ_PREFIX + "GlobalCommentEdit", OBJPROP_TEXT, "");
    UpdateCommentUI();
}


//+------------------------------------------------------------------+
//| UIの状態を更新する関数                                           |
//+------------------------------------------------------------------+
void UpdateUIState()
{
    // セッションの状態に応じてボタンの有効/無効を切り替える
    ObjectSetInteger(0, OBJ_PREFIX + "StartButton", OBJPROP_STATE, g_chartData.session.isSessionActive);
    ObjectSetInteger(0, OBJ_PREFIX + "AddEvidenceButton", OBJPROP_STATE, !g_chartData.session.isSessionActive);
    ObjectSetInteger(0, OBJ_PREFIX + "AddTradeButton", OBJPROP_STATE, !g_chartData.session.isSessionActive);
    ObjectSetInteger(0, OBJ_PREFIX + "CompleteButton", OBJPROP_STATE, !g_chartData.session.isSessionActive);

    // 「最後の根拠を削除」ボタンは、セッション中で根拠が1つ以上ある場合のみ有効
    bool canDelete = g_chartData.session.isSessionActive && (g_chartData.session.evidenceCount > 0);
    ObjectSetInteger(0, OBJ_PREFIX + "DeleteLastButton", OBJPROP_STATE, !canDelete);

    ChartRedraw();
}

//+------------------------------------------------------------------+
//| コメントUIを更新する関数                                         |
//+------------------------------------------------------------------+
void UpdateCommentUI()
{
    // 既存の根拠コメントUIをすべて削除
    ObjectsDeleteAll(0, OBJ_PREFIX + "EvidenceCommentLabel_");
    ObjectsDeleteAll(0, OBJ_PREFIX + "EvidenceCommentEdit_");

    string font = "Yu Gothic UI";
    int fontSize = 9;
    int y_offset = PANEL_Y + PADDING + (BUTTON_HEIGHT + PADDING) * 3 + PADDING + 100 + PADDING; // GlobalCommentEditの下から開始

    // 根拠の数だけUIを再生成
    for (int i = 0; i < g_chartData.session.evidenceCount; i++) {
        string label_name = OBJ_PREFIX + "EvidenceCommentLabel_" + (string)(i + 1);
        string edit_name = OBJ_PREFIX + "EvidenceCommentEdit_" + (string)(i + 1);

        // ラベル
        ObjectCreate(0, label_name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, label_name, OBJPROP_XDISTANCE, PANEL_X + PADDING);
        ObjectSetInteger(0, label_name, OBJPROP_YDISTANCE, y_offset);
        ObjectSetString(0, label_name, OBJPROP_TEXT, "根拠 " + (string)(i + 1) + ":");
        ObjectSetInteger(0, label_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetString(0, label_name, OBJPROP_FONT, font);
        ObjectSetInteger(0, label_name, OBJPROP_FONTSIZE, fontSize);

        y_offset += 15;

        // テキストボックス
        ObjectCreate(0, edit_name, OBJ_EDIT, 0, 0, 0);
        ObjectSetInteger(0, edit_name, OBJPROP_XDISTANCE, PANEL_X + PADDING);
        ObjectSetInteger(0, edit_name, OBJPROP_YDISTANCE, y_offset);
        ObjectSetInteger(0, edit_name, OBJPROP_XSIZE, PANEL_WIDTH - PADDING * 2);
        ObjectSetInteger(0, edit_name, OBJPROP_YSIZE, COMMENT_EDIT_HEIGHT);
        ObjectSetString(0, edit_name, OBJPROP_TEXT, CharArrayToString(g_chartData.evidences[i].comment));
        ObjectSetInteger(0, edit_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, edit_name, OBJPROP_BORDER_COLOR, clrGray);
        ObjectSetString(0, edit_name, OBJPROP_FONT, font);
        ObjectSetInteger(0, edit_name, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, edit_name, OBJPROP_ALIGN, ALIGN_LEFT);

        y_offset += COMMENT_EDIT_HEIGHT + PADDING;
    }
    ChartRedraw();
}


//+------------------------------------------------------------------+
//| 根拠エリアオブジェクトを整形する関数                             |
//+------------------------------------------------------------------+
void FinalizeEvidenceObject(string objectName)
{
    if (g_chartData.session.evidenceCount >= MAX_EVIDENCE_COUNT) {
        Print("ChartMemo: 根拠エリアの最大数(" + (string)MAX_EVIDENCE_COUNT + ")に達しました。");
        ObjectDelete(0, objectName); // 作成されたオブジェクトを削除
        return;
    }

    g_chartData.session.evidenceCount++;
    int currentCount = g_chartData.session.evidenceCount;
    
    ObjectSetString(0, objectName, OBJPROP_TEXT, "");

    // プロパティ設定
    ObjectSetInteger(0, objectName, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(0, objectName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, objectName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
    ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, objectName, OBJPROP_FILL, false);
    ObjectSetInteger(0, objectName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS); // 全時間足に表示

    // 番号ラベルを作成
    datetime time1 = (datetime)ObjectGetInteger(0, objectName, OBJPROP_TIME, 0);
    double price1 = ObjectGetDouble(0, objectName, OBJPROP_PRICE, 0);
    string labelName = OBJ_PREFIX + "EvidenceLabel_" + (string)currentCount;
    ObjectCreate(0, labelName, OBJ_TEXT, 0, time1, price1);
    ObjectSetString(0, labelName, OBJPROP_TEXT, (string)currentCount);
    ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 12);
    ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Black");
    ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
    ObjectSetInteger(0, labelName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS); // 全時間足に表示

    // 後で削除するために名前をリストに保存
    StringToCharArray(objectName, g_chartData.evidences[currentCount - 1].rectName);
    StringToCharArray(labelName, g_chartData.evidences[currentCount - 1].labelName);
    g_chartData.evidences[currentCount - 1].timeframe = (int)Period();

    UpdateCommentUI();
    SaveState(); // 状態を保存
    UpdateUIState(); // 削除ボタンの状態を更新
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| トレードエリアオブジェクトを整形する関数                         |
//+------------------------------------------------------------------+
void FinalizeTradeAreaObject(string objectName)
{
    string oldRectName = CharArrayToString(g_chartData.session.tradeAreaRectName);
    // 既に存在する場合は古いものを削除
    if(oldRectName != "" && ObjectFind(0, oldRectName) >= 0)
    {
        ObjectDelete(0, oldRectName);
    }

    // 新しいオブジェクトのプロパティを設定
    ObjectSetString(0, objectName, OBJPROP_TEXT, "");
    ObjectSetInteger(0, objectName, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(0, objectName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, objectName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
    ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, objectName, OBJPROP_FILL, false);
    ObjectSetInteger(0, objectName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS); // 全時間足に表示

    // 新しい名前を保存
    StringToCharArray(objectName, g_chartData.session.tradeAreaRectName);
    g_chartData.session.tradeAreaTimeframe = (int)Period();
    SaveState(); // 状態を保存
    ChartRedraw();
}


//+------------------------------------------------------------------+
//| セッションをリセットする関数                                     |
//+------------------------------------------------------------------+
void ResetSession()
{
    DeleteDrawnObjects();
    g_drawingMode = "";
    ZeroMemory(g_chartData); // 構造体をゼロクリア
    // isSessionActiveはtrueのままにしたいので、リセット後に設定
    g_chartData.session.isSessionActive = true; 
    UpdateCommentUI();
    SaveState(); // リセットされた状態を保存
}

//+------------------------------------------------------------------+
//| 描画されたオブジェクトを削除する関数                             |
//+------------------------------------------------------------------+
void DeleteDrawnObjects()
{
    // 根拠エリアを削除
    for(int i = 0; i < g_chartData.session.evidenceCount; i++)
    {
        string rectName = CharArrayToString(g_chartData.evidences[i].rectName);
        if(rectName != "" && ObjectFind(0, rectName) >= 0) ObjectDelete(0, rectName);

        string labelName = CharArrayToString(g_chartData.evidences[i].labelName);
        if(labelName != "" && ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);
    }

    // トレードエリアを削除
    string tradeRectName = CharArrayToString(g_chartData.session.tradeAreaRectName);
    if(tradeRectName != "" && ObjectFind(0, tradeRectName) >= 0)
    {
        ObjectDelete(0, tradeRectName);
    }
    
    // コメントUIも削除
    ObjectsDeleteAll(0, OBJ_PREFIX + "EvidenceCommentLabel_");
    ObjectsDeleteAll(0, OBJ_PREFIX + "EvidenceCommentEdit_");

    // 状態変数はここではクリアせず、ResetSessionで行う
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| 最後の根拠を削除する関数                                         |
//+------------------------------------------------------------------+
void DeleteLastEvidence()
{
    if(g_chartData.session.evidenceCount > 0)
    {
        int lastIndex = g_chartData.session.evidenceCount - 1;
        
        string rectName = CharArrayToString(g_chartData.evidences[lastIndex].rectName);
        string labelName = CharArrayToString(g_chartData.evidences[lastIndex].labelName);

        if(rectName != "" && ObjectFind(0, rectName) >= 0) ObjectDelete(0, rectName);
        if(labelName != "" && ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);

        // カウンタを減らす
        g_chartData.session.evidenceCount--;

        UpdateCommentUI();
        SaveState(); // 状態を保存
        UpdateUIState();
        ChartRedraw();
    }
}
//+------------------------------------------------------------------+

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