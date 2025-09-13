//+------------------------------------------------------------------+
//|                                                    ChartMemo.mq4 |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Takafumi (via Gemini CLI)"
#property link      ""
#property version   "1.80" // Refactored into multiple files
#property strict

//--- インジケーターの基本設定
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//--- インクルード ---
#include "ChartMemo_Defines.mqh"
#include "ChartMemo_Globals.mqh"
#include "ChartMemo_Utils.mqh"
#include "ChartMemo_Storage.mqh"
#include "ChartMemo_UI.mqh"
#include "ChartMemo_Logic.mqh"


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- チャートイベントの有効化 ---
    ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, true);

    //--- 状態を復元 ---
    LoadState();

    //--- UIを作成 ---
    CreateUI();

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
