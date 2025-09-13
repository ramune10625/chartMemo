//+------------------------------------------------------------------+
//|                                             ChartMemo_UI.mqh |
//|                        Copyright 2025, Takafumi (via Gemini CLI) |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| UIを作成する関数                                                 |
//+------------------------------------------------------------------+
void CreateUI()
{
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
