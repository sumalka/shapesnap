import os

def delete_all_jpg(folder_path):
    """
    Delete all JPG files in a folder and subfolders
    """
    deleted_count = 0
    error_count = 0
    
    print(f"🗑️  Scanning for JPG files in: {folder_path}\n")
    
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.lower().endswith(('.jpg', '.jpeg')):
                file_path = os.path.join(root, file)
                try:
                    os.remove(file_path)
                    print(f"✅ DELETED: {file}")
                    deleted_count += 1
                except Exception as e:
                    print(f"❌ ERROR deleting {file}: {e}")
                    error_count += 1
    
    print("\n" + "="*50)
    print("📊 DELETION SUMMARY:")
    print(f"   ✅ Deleted: {deleted_count} JPG files")
    print(f"   ❌ Errors: {error_count} files")
    print("="*50)

if __name__ == "__main__":
    delete_all_jpg('assets/recommendations')