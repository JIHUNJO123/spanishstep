from PIL import Image
import os

# 원본 아이콘 열기
img = Image.open('assets/icon/app_icon.png')

# 알파 채널 제거 (RGBA -> RGB, 흰색 배경)
if img.mode == 'RGBA':
    background = Image.new('RGB', img.size, (255, 255, 255))
    background.paste(img, mask=img.split()[3])  # 알파 채널을 마스크로 사용
    img = background

# 알파 제거된 원본 저장
img.save('assets/icon/app_icon_no_alpha.png', 'PNG')
print("Created: assets/icon/app_icon_no_alpha.png")

# iOS 아이콘 크기 목록
ios_sizes = [
    (20, 1), (20, 2), (20, 3),
    (29, 1), (29, 2), (29, 3),
    (40, 1), (40, 2), (40, 3),
    (50, 1), (50, 2),
    (57, 1), (57, 2),
    (60, 2), (60, 3),
    (72, 1), (72, 2),
    (76, 1), (76, 2),
    (83.5, 2),
    (1024, 1)
]

output_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'

for size, scale in ios_sizes:
    pixel_size = int(size * scale)
    resized = img.resize((pixel_size, pixel_size), Image.LANCZOS)
    
    if size == 1024:
        filename = f'Icon-App-{int(size)}x{int(size)}@{scale}x.png'
    elif size == 83.5:
        filename = f'Icon-App-{size}x{size}@{scale}x.png'
    else:
        filename = f'Icon-App-{int(size)}x{int(size)}@{scale}x.png'
    
    filepath = os.path.join(output_dir, filename)
    resized.save(filepath, 'PNG')
    print(f"Created: {filename} ({pixel_size}x{pixel_size})")

print("\nDone! All iOS icons regenerated without alpha channel.")
