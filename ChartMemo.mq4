//+------------------------------------------------------------------+
//|                                                    ChartMemo.mq4 |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Takafumi (via Gemini CLI)"
#property link      ""
#property version   "1.50" // トレードエリア機能追加バージョン
#property strict

#define STATE_FILE_NAME "ChartMemo_State.tmp" // 状態保存ファイル名

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
#define PANEL_HEIGHT 400
#define BUTTON_WIDTH 140
#define BUTTON_HEIGHT 25
#define PADDING 10

// --- 構造体定義 ---
struct Evidence
{
    string rectName;
    string labelName;
};

//--- グローバル変数 ---
bool   isSessionActive = false; // セッションがアクティブか
string drawingMode = "";        // 描画モード ("", "evidence", "trade")
int    evidenceCount = 0;       // 根拠エリアのカウンター
Evidence evidences[];             // 根拠エリアのオブジェクト情報を格納
string tradeAreaRectName = ""; // トレードエリアは1つだけ

//--- プロトタイプ宣言 ---
void UpdateUIState();
void FinalizeEvidenceObject(string objectName);
void FinalizeTradeAreaObject(string objectName);
void ResetSession();
void DeleteDrawnObjects();
void DeleteLastEvidence();
void SaveState();
void LoadState();

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

    // --- コメントエリア ---
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
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_BORDER_COLOR, clrGray);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_BACK, false);
    ObjectSetString(0, globalCommentEditName, OBJPROP_FONT, font);
    ObjectSetInteger(0, globalCommentEditName, OBJPROP_FONTSIZE, fontSize);

    // --- 根拠コメントエリアのプレースホルダー / ステータス表示 ---
    y_offset += 100 + PADDING;
    string evidenceAreaLabelName = OBJ_PREFIX + "EvidenceAreaLabel";
    ObjectCreate(0, evidenceAreaLabelName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, evidenceAreaLabelName, OBJPROP_XDISTANCE, PANEL_X + PADDING);
    ObjectSetInteger(0, evidenceAreaLabelName, OBJPROP_YDISTANCE, y_offset);
    ObjectSetString(0, evidenceAreaLabelName, OBJPROP_TEXT, "（根拠コメントはここに表示されます）");
    ObjectSetInteger(0, evidenceAreaLabelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, evidenceAreaLabelName, OBJPROP_COLOR, clrGray);
    ObjectSetInteger(0, evidenceAreaLabelName, OBJPROP_BACK, false);
    ObjectSetString(0, evidenceAreaLabelName, OBJPROP_FONT, font);
    ObjectSetInteger(0, evidenceAreaLabelName, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, evidenceAreaLabelName, OBJPROP_SELECTABLE, false);

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
            isSessionActive = true;
            ResetSession(); // この中でSaveStateが呼ばれる
            UpdateUIState();
            Print("ChartMemo: 記録セッションを開始しました。");
        }
        else if(sparam == OBJ_PREFIX + "CompleteButton")
        {
            isSessionActive = false;
            SaveState(); // セッションが非アクティブになったことを保存
            DeleteDrawnObjects();
            UpdateUIState();
            Print("ChartMemo: 記録セッションを完了しました。");
        }
        else if(sparam == OBJ_PREFIX + "AddEvidenceButton")
        {
            drawingMode = "evidence";
            ObjectSetString(0, OBJ_PREFIX + "EvidenceAreaLabel", OBJPROP_TEXT, "描画モード: 根拠エリア(青)を描画");
            ObjectSetInteger(0, OBJ_PREFIX + "EvidenceAreaLabel", OBJPROP_COLOR, clrBlue);
        }
        else if(sparam == OBJ_PREFIX + "AddTradeButton")
        {
            drawingMode = "trade";
            ObjectSetString(0, OBJ_PREFIX + "EvidenceAreaLabel", OBJPROP_TEXT, "描画モード: トレードエリア(赤)を描画");
            ObjectSetInteger(0, OBJ_PREFIX + "EvidenceAreaLabel", OBJPROP_COLOR, clrRed);
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
        // パネルのラベルを元に戻す共通処理
        string original_text = "（根拠コメントはここに表示されます）";
        
        if(drawingMode == "evidence" && ObjectGetInteger(0, sparam, OBJPROP_TYPE) == OBJ_RECTANGLE)
        {
            FinalizeEvidenceObject(sparam);
            drawingMode = ""; // 描画モードをリセット
            ObjectSetString(0, OBJ_PREFIX + "EvidenceAreaLabel", OBJPROP_TEXT, original_text);
            ObjectSetInteger(0, OBJ_PREFIX + "EvidenceAreaLabel", OBJPROP_COLOR, clrGray);
        }
        else if(drawingMode == "trade" && ObjectGetInteger(0, sparam, OBJPROP_TYPE) == OBJ_RECTANGLE)
        {
            FinalizeTradeAreaObject(sparam);
            drawingMode = ""; // 描画モードをリセット
            ObjectSetString(0, OBJ_PREFIX + "EvidenceAreaLabel", OBJPROP_TEXT, original_text);
            ObjectSetInteger(0, OBJ_PREFIX + "EvidenceAreaLabel", OBJPROP_COLOR, clrGray);
        }
    }
}

//+------------------------------------------------------------------+
//| UIの状態を更新する関数                                           |
//+------------------------------------------------------------------+
void UpdateUIState()
{
    // セッションの状態に応じてボタンの有効/無効を切り替える
    ObjectSetInteger(0, OBJ_PREFIX + "StartButton", OBJPROP_STATE, isSessionActive);
    ObjectSetInteger(0, OBJ_PREFIX + "AddEvidenceButton", OBJPROP_STATE, !isSessionActive);
    ObjectSetInteger(0, OBJ_PREFIX + "AddTradeButton", OBJPROP_STATE, !isSessionActive);
    ObjectSetInteger(0, OBJ_PREFIX + "CompleteButton", OBJPROP_STATE, !isSessionActive);

    // 「最後の根拠を削除」ボタンは、セッション中で根拠が1つ以上ある場合のみ有効
    bool canDelete = isSessionActive && (evidenceCount > 0);
    ObjectSetInteger(0, OBJ_PREFIX + "DeleteLastButton", OBJPROP_STATE, !canDelete);

    ChartRedraw();
}

//+------------------------------------------------------------------+
//| 根拠エリアオブジェクトを整形する関数                             |
//+------------------------------------------------------------------+
void FinalizeEvidenceObject(string objectName)
{
    evidenceCount++;
    
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
    string labelName = OBJ_PREFIX + "EvidenceLabel_" + (string)evidenceCount;
    ObjectCreate(0, labelName, OBJ_TEXT, 0, time1, price1);
    ObjectSetString(0, labelName, OBJPROP_TEXT, (string)evidenceCount);
    ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 12);
    ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Black");
    ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
    ObjectSetInteger(0, labelName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS); // 全時間足に表示

    // 後で削除するために名前をリストに保存
    ArrayResize(evidences, evidenceCount);
    evidences[evidenceCount - 1].rectName = objectName;
    evidences[evidenceCount - 1].labelName = labelName;

    SaveState(); // 状態を保存
    UpdateUIState(); // 削除ボタンの状態を更新
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| トレードエリアオブジェクトを整形する関数                         |
//+------------------------------------------------------------------+
void FinalizeTradeAreaObject(string objectName)
{
    // 既に存在する場合は古いものを削除
    if(tradeAreaRectName != "" && ObjectFind(0, tradeAreaRectName) >= 0)
    {
        ObjectDelete(0, tradeAreaRectName);
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
    tradeAreaRectName = objectName;
    SaveState(); // 状態を保存
    ChartRedraw();
}


//+------------------------------------------------------------------+
//| セッションをリセットする関数                                     |
//+------------------------------------------------------------------+
void ResetSession()
{
    FileDelete(STATE_FILE_NAME); // 古い状態ファイルを削除
    DeleteDrawnObjects();
    drawingMode = "";
    evidenceCount = 0;
    SaveState(); // リセットされた状態を保存
}

//+------------------------------------------------------------------+
//| 描画されたオブジェクトを削除する関数                             |
//+------------------------------------------------------------------+
void DeleteDrawnObjects()
{
    // 根拠エリアを削除
    int total = ArraySize(evidences);
    for(int i = 0; i < total; i++)
    {
        string rectName = evidences[i].rectName;
        if(rectName != "" && ObjectFind(0, rectName) >= 0) ObjectDelete(0, rectName);

        string labelName = evidences[i].labelName;
        if(labelName != "" && ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);
    }
    ArrayResize(evidences, 0);

    // トレードエリアを削除
    if(tradeAreaRectName != "" && ObjectFind(0, tradeAreaRectName) >= 0)
    {
        ObjectDelete(0, tradeAreaRectName);
    }
    tradeAreaRectName = "";

    ChartRedraw();
}

//+------------------------------------------------------------------+
//| 最後の根拠を削除する関数                                         |
//+------------------------------------------------------------------+
void DeleteLastEvidence()
{
    if(evidenceCount > 0)
    {
        evidenceCount--;
        string rectName = evidences[evidenceCount].rectName;
        string labelName = evidences[evidenceCount].labelName;

        if(rectName != "" && ObjectFind(0, rectName) >= 0) ObjectDelete(0, rectName);
        if(labelName != "" && ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);

        ArrayResize(evidences, evidenceCount);

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
    string state_string = "";
    // isSessionActive, evidenceCount, tradeAreaRectName
    state_string += (isSessionActive ? "1" : "0") + "|";
    state_string += IntegerToString(evidenceCount) + "|";
    state_string += tradeAreaRectName + "|";

    // evidences
    for (int i = 0; i < evidenceCount; i++) {
        state_string += evidences[i].rectName + "|";
        state_string += evidences[i].labelName + "|";
    }

    // ファイルに書き込む
    int handle = FileOpen(STATE_FILE_NAME, FILE_WRITE|FILE_TXT);
    if(handle != INVALID_HANDLE)
    {
        FileWriteString(handle, state_string);
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
        isSessionActive = false;
        evidenceCount = 0;
        tradeAreaRectName = "";
        ArrayResize(evidences, 0);
        return;
    }

    string state_string = "";
    int handle = FileOpen(STATE_FILE_NAME, FILE_READ|FILE_TXT);
    if(handle != INVALID_HANDLE)
    {
        // ファイルの終わりまで読み込む
        while(!FileIsEnding(handle))
        {
            state_string += FileReadString(handle);
        }
        FileClose(handle);
    }

    string parts[];
    int count = StringSplit(state_string, '|', parts);

    if (count < 3) return; // データが不完全

    int current_index = 0;
    isSessionActive = (StringToInteger(parts[current_index++]) == 1);
    evidenceCount = (int)StringToInteger(parts[current_index++]);
    tradeAreaRectName = parts[current_index++];

    // evidencesの復元
    if (evidenceCount > 0) {
        ArrayResize(evidences, evidenceCount);
        for (int i = 0; i < evidenceCount; i++) {
            if (current_index + 1 < count) { // ペアで存在するかチェック
                evidences[i].rectName = parts[current_index++];
                evidences[i].labelName = parts[current_index++];
            }
        }
    } else {
        ArrayResize(evidences, 0);
    }
}