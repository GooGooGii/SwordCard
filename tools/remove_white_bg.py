import sys
import os
from PIL import Image

def remove_white_background(img_path, threshold=245):
    if not os.path.exists(img_path):
        print(f"Error: File {img_path} not found.")
        return False
    
    try:
        img = Image.open(img_path)
        img = img.convert("RGBA")
        
        datas = img.getdata()
        newData = []
        for item in datas:
            # item is (r, g, b, a)
            # If red, green, and blue are all above threshold, make it transparent
            if item[0] >= threshold and item[1] >= threshold and item[2] >= threshold:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)
                
        img.putdata(newData)
        img.save(img_path, "PNG")
        print(f"Successfully removed background from {img_path}")
        return True
    except Exception as e:
        print(f"Error processing image {img_path}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python remove_white_bg.py <image_path> [threshold]")
        sys.exit(1)
        
    path = sys.argv[1]
    thresh = int(sys.argv[2]) if len(sys.argv) > 2 else 245
    remove_white_background(path, thresh)
