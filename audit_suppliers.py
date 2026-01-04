import pyodbc
import os
from dotenv import load_dotenv

load_dotenv()

def get_connection():
    return pyodbc.connect(
        f"DRIVER={os.getenv('DB_DRIVER', 'ODBC Driver 17 for SQL Server')};"
        f"SERVER={os.getenv('DB_SERVER')};"
        f"DATABASE={os.getenv('DB_DATABASE')};"
        "Trusted_Connection=yes;"
    )

def ensure_audit_columns(cursor):
    """
    Ensure audit-related columns exist on Suppliers table.
    Safe to run multiple times.
    """
    cursor.execute("""
        IF COL_LENGTH('dbo.Suppliers', 'status') IS NULL
        BEGIN
            ALTER TABLE dbo.Suppliers
            ADD status VARCHAR(20) NOT NULL DEFAULT 'Active';
        END
    """)

    cursor.execute("""
        IF COL_LENGTH('dbo.Suppliers', 'last_audit') IS NULL
        BEGIN
            ALTER TABLE dbo.Suppliers
            ADD last_audit DATETIME NULL;
        END
    """)


def run_audit():
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor()

        # 🔧 ENSURE AUDIT COLUMNS EXIST (THIS WAS MISSING)
        ensure_audit_columns(cursor)
        conn.commit()

        cursor.execute("""
            SELECT supplier_id
            FROM dbo.v_supplier_health
            WHERE
                cert_status IN ('Expired', 'Expiring Soon')
                OR orders_90d = 0
                OR (
                    latest_yield IS NOT NULL
                    AND rolling_avg_yield IS NOT NULL
                    AND latest_yield < rolling_avg_yield * 0.8
                )
        """)

        at_risk_ids = [row.supplier_id for row in cursor.fetchall()]

        if not at_risk_ids:
            print("✓ No suppliers require review")
            return

        cursor.executemany("""
            UPDATE dbo.Suppliers
            SET status = ?, last_audit = GETDATE()
            WHERE supplier_id = ?
        """, [('Review', sid) for sid in at_risk_ids])

        conn.commit()
        print(f"⚠ {len(at_risk_ids)} suppliers require review")

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"✗ Audit failed: {e}")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    run_audit()
