$settings = @{
    "genkou" = @{ # 現行システム向けのパラメータ群です
        "odbc_name"  = "ESL_BT06" # ODBCの接続名を設定します
        "conn_user"  = "db2inst6" # DBの接続ユーザーを設定します
        "conn_pass"  = "db2inst6" # DBの接続パスワードを設定します
        "user_id"    = "SG00008"  # イーサポートリンクシステムのログインユーザーを設定します
        "session_id" = "ESL09AG"  # イーサポートリンクシステムのセッションIDを設定します
    }
    "cloud" = @{ # クラウドシステム向けのパラメータ群です
        "odbc_name"  = "ESL_BT06" # ODBCの接続名を設定します
        "conn_user"  = "db2inst6" # DBの接続ユーザーを設定します
        "conn_pass"  = "db2inst6" # DBの接続パスワードを設定します
        "user_id"    = "SG00008"  # イーサポートリンクシステムのログインユーザーを設定します
        "session_id" = "ESL09AC"  # イーサポートリンクシステムのセッションIDを設定します
    }
}