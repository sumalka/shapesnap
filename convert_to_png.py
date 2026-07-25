import os
from PIL import Image

def convert_jpg_to_png(folder_path):
    """
    Convert all JPG images in a folder and subfolders to PNG format
    """
    converted_count = 0
    error_count = 0
    skipped_count = 0
    
    print(f"📁 Scanning folder: {folder_path}\n")
    
    # Walk through all directories
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            # Check if file is a JPG or JPEG
            if file.lower().endswith(('.jpg', '.jpeg')):
                # Get full file path
                jpg_path = os.path.join(root, file)
                
                # Create PNG filename (replace extension)
                png_filename = os.path.splitext(file)[0] + '.png'
                png_path = os.path.join(root, png_filename)
                
                # Skip if PNG already exists
                if os.path.exists(png_path):
                    print(f"⏭️  SKIP: {file} → PNG already exists")
                    skipped_count += 1
                    continue
                
                try:
                    # Open and convert image
                    with Image.open(jpg_path) as img:
                        # Convert to RGB if necessary (for PNG compatibility)
                        if img.mode in ('RGBA', 'LA', 'P'):
                            # If already has alpha, keep it
                            img.save(png_path, 'PNG')
                        else:
                            # Convert to RGB
                            rgb_img = img.convert('RGB')
                            rgb_img.save(png_path, 'PNG')
                    
                    print(f"✅ CONVERTED: {file} → {png_filename}")
                    converted_count += 1
                    
                    # Optional: Delete the original JPG file
                    # Uncomment the line below to delete JPG after conversion
                    # os.remove(jpg_path)
                    # print(f"🗑️  REMOVED: {file}")
                    
                except Exception as e:
                    print(f"❌ ERROR: {file} - {e}")
                    error_count += 1
    
    # Print summary
    print("\n" + "="*50)
    print("📊 CONVERSION SUMMARY:")
    print(f"   ✅ Converted: {converted_count} files")
    print(f"   ⏭️  Skipped: {skipped_count} files (PNG already exists)")
    print(f"   ❌ Errors: {error_count} files")
    print("="*50)

def main():
    # Path to your assets folder - CHANGE THIS IF NEEDED
    assets_path = 'assets/recommendations'
    
    # Check if folder exists
    if os.path.exists(assets_path):
        print("🚀 Starting conversion...\n")
        convert_jpg_to_png(assets_path)
        print("\n✅ All images converted to PNG!")
    else:
        print(f"❌ Folder not found: {assets_path}")
        print("💡 Make sure you're running this script from your project root folder")

if __name__ == "__main__":
    main()