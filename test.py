import os, config, sqlite3, ffmpeg
from re import search

def insertVaribleIntoTable(Current_Bits, Pixel_Height, Target_Bits, Target_Height, Encode, Root_Path, File_Path):
    try:
        sqliteConnection = sqlite3.connect('contents.db')
        cursor = sqliteConnection.cursor()
        print([1,"Connected to SQLite"])

        sqlite_insert_with_param = """INSERT INTO Disk_Content
                          (Current_Bits, Pixel_Height, Target_Bits, Target_Height, Encode, Root_Path, File_Path) 
                          VALUES (?, ?, ?, ?, ?, ?, ?);"""

        data_tuple = (Current_Bits, Pixel_Height, Target_Bits, Target_Height, Encode, Root_Path, File_Path)
        cursor.execute(sqlite_insert_with_param, data_tuple)
        sqliteConnection.commit()
        print([1,"Python Variables inserted successfully into Disk_Content table"])

        cursor.close()

    except sqlite3.Error as error:
        string = "UNIQUE constraint failed" 
        if search(string, str(error)):
            print([1,f"File already in DB, skipping - {File_Path}"])
        else:
            print([3,f"Failed to insert Python variable into sqlite table, {error}"])
    finally:
        if sqliteConnection:
            sqliteConnection.close()
            print([1,"The SQLite connection is closed"])


# path = "smb://10.0.0.229/media/anime"

# traverse root directory, and list directories as dirs and files as files
for root, dirs, files in os.walk(config.sRootPath):
     path = root.split(os.sep)
     print((len(path) - 1) * '---', os.path.basename(root))
     for file in files:
        filepath = []
        filepath = os.path.join(root, file)
        insertVaribleIntoTable(100, 720, 50, 720, 1, 'filepath2', filepath)  