# Replay corpus (permanent regression suite, D-073)

Real GoldIntelDiag lab files recorded in the WoW Forever client (build 70450). They are copies of the files in `GoldIntel_Docs/evidence/`. They are NEVER edited. Phase 3b and every later phase replays them so that a Reconciler or collector change cannot silently break verified timing or data behavior.

| File | Evidence | What it pins |
|---|---|---|
| E-22_quest_turnin.lua | E-22 | QUEST_TURNED_IN arrives 0.041 s before the money move; the money argument equals the delta |
| E-28_mail_update.lua | E-28 | MAIL_INBOX_UPDATE arrives 0.365 s before the money move |
| E-31_trade.lua | E-31 | TRADE_CLOSED precedes the money move by 0.394 s; a cancelled trade gives a zero money move |
| E-34_ah_sale_mail.lua | E-34 | Sold-auction mail: header money 149 = sale price 51 + deposit refund 100 - cut 2; invoice readable before the take |
| E-33_merchant_close.lua | E-33 | MERCHANT_CLOSED fires for both close routes and arrives twice in one frame when the window closes by walking away |
| E-39_cod_paid.lua | E-39 | COD amount (100) is in the mail header before paying; paying moves money -100 exactly, 0.106 s after MAIL_INBOX_UPDATE; taking a money mail +30 after 0.233 s |
| E-40_cod_payment_mail.lua | E-40 | The COD payment mail carries the full 100 (no fee); taking it moves money +100, 0.267 s after MAIL_INBOX_UPDATE |

Rules: a missing corpus file FAILS the suite (it never skips). New verified sequences are added here with a row in this table and a test. The window under test is the 1.0 s reconciliation window (D-065).
