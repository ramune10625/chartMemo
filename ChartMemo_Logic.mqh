//+------------------------------------------------------------------+
//|                                          ChartMemo_Logic.mqh |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+

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
