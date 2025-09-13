//+------------------------------------------------------------------+
//|                                        ChartMemo_Globals.mqh |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+

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

// UI作成関数 (UI.mqh)
void CreateUI();
