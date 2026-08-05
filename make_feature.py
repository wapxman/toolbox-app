# -*- coding: utf-8 -*-
"""Feature graphic 1024x500 для Google Play из фирменного лок-апа Taketool."""
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1024, 500
RED = (200, 0, 19)      # #C80013
DARK = (26, 26, 26)
GRAY = (90, 90, 90)

img = Image.new("RGB", (W, H), (255, 255, 255))
d = ImageDraw.Draw(img)

# тонкая красная полоса снизу как акцент
d.rectangle([0, H-10, W, H], fill=RED)

# логотип-локап
logo = Image.open("assets/images/logo.png").convert("RGBA")
# масштаб по ширине ~640
scale = 640 / logo.width
lw, lh = int(logo.width*scale), int(logo.height*scale)
logo = logo.resize((lw, lh), Image.LANCZOS)
lx = (W - lw)//2
ly = 120
# если фон логотипа прозрачный — кладём на белый через альфу
img.paste(logo, (lx, ly), logo)

# tagline
def font(path, size):
    for p in [path, "C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arialbd.ttf"]:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()

f = font("C:/Windows/Fonts/segoeuib.ttf", 36)
tag = "Аренда электроинструмента 24/7 из умных боксов"
tb = d.textbbox((0,0), tag, font=f)
tw = tb[2]-tb[0]
d.text(((W-tw)//2, ly+lh+40), tag, font=f, fill=DARK)

os.makedirs("assets/branding", exist_ok=True)
img.save("assets/branding/feature_1024x500.png")

ob = r"C:\Users\User\tg-claude-bot\outbox"
if os.path.isdir(ob):
    img.save(os.path.join(ob, "taketool_feature_1024x500.png"))
print("feature graphic saved")
