import sqlite3
import os

def delete_nonexistent_strm_files(db_path, batch_size=1000):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM MediaItems WHERE Path LIKE '%.strm'")
    total_records = cursor.fetchone()[0]
    
    print(f"Total .strm records: {total_records}")
    
    offset = 0
    while offset < total_records:
        cursor.execute(f"SELECT Id, Path FROM MediaItems WHERE Path LIKE '%.strm' LIMIT {batch_size} OFFSET {offset}")
        rows = cursor.fetchall()
        
        if not rows:
            break
        
        delete_ids = []
        for row in rows:
            record_id, path = row
            if not os.path.exists(path):
                print(path)
                delete_ids.append(record_id)
        
        if delete_ids:
            cursor.execute("BEGIN TRANSACTION")
            cursor.executemany("DELETE FROM MediaItems WHERE Id = ?", [(id,) for id in delete_ids])
            conn.commit()
            print(f"Deleted {len(delete_ids)} records")
        
        offset += batch_size
    
    cursor.close()
    conn.close()

db_path = '/emby-data/library.db'

delete_nonexistent_strm_files(db_path)
