
# 2018 IC Design Contest - LCD Controller (LCD_CTRL)

此專案為 2018 年台灣大學校院積體電路設計競賽 (IC Design Contest) 大學部 B 組初賽題目的 RTL 實作與時序優化紀錄。本設計成功通過 Pre-sim 與 Post-sim 驗證，並針對極端時鐘週期`(<10ns)`進行了深度時序優化。

## 系統架構設計

本設計採用標準的 Mealy/Moore FSM 狀態機架構，將控制邏輯與資料路徑 (Datapath) 分離，確保電路在嚴苛的時序約束下維持高穩定性。

*   **FSM 狀態劃分：** `IDLE` (待機) ➔ `READ` (讀取影像) ➔ `OPER` (執行運算) ➔ `OUTPUT` (輸出結果)
*   **記憶體配置：** 捨棄 1D 陣列，採用 `reg [7:0] mem [7:0][7:0]` 2D 暫存器陣列。將影像空間二維化，使 `Shift` 與 `Mirror` 等空間操作能透過座標 (X, Y) 指標直接映射，大幅簡化邏輯閘複雜度。
*   **資料返回優化：** 捨棄`64to1多工器`，改成全體左移使`IRAM_D`直接讀取`mem[0][0]`，可減少Delay。

## 效能報告 (Synthesis Results)

| 評估項目 | 數值 / 狀態 | 說明 |
| :--- | :--- | :--- |
| **Technology** | TSMC 0.13 µm | 大會標準元件庫 |
| **Clock Period** | 7.1 ns | 無時序違規 (Slack = MET) |
| **Post-sim Status** | **PASS** | Gate-level 驗證通過，無 Unknown |

## 目錄結構

```text
├── LCD_CTRL.v       # 核心 Verilog 程式碼
├── testfixture.v    # 大會提供之 Testbench (未修改路徑)
├── syn.tcl          # 合成腳本 (Clock 約束設定)
│── LCD_CTRL_syn.v   # 合成後之閘級網表 (Gate-level Netlist)
│── LCD_CTRL.sdf     # 延遲時序檔
└── README.md
