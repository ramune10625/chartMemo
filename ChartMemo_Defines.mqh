#ifndef CHARTMEMO_DEFINES_MQH
#define CHARTMEMO_DEFINES_MQH

//+------------------------------------------------------------------+
//|                                        ChartMemo_Defines.mqh |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+

#define STATE_FILE_NAME "ChartMemo_State.bin" // 状態保存ファイル名 (バイナリ)

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



#endif // CHARTMEMO_DEFINES_MQH