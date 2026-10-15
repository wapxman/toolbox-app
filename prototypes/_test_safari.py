# -*- coding: utf-8 -*-
"""Проверка колеса в движке Safari (WebKit) с эмуляцией iPhone."""
import pathlib, sys
from playwright.sync_api import sync_playwright

HTML = pathlib.Path(r"C:\Users\User\Desktop\GitHub\toolbox-app\prototypes\fortune_wheel.html")
OUT  = pathlib.Path(r"C:\Users\User\Desktop\GitHub\toolbox-app\prototypes")

with sync_playwright() as pw:
    dev = pw.devices["iPhone 13"]
    b = pw.webkit.launch()
    ctx = b.new_context(**dev)
    pg = ctx.new_page()
    errs = []
    pg.on("console", lambda m: errs.append(f"console.{m.type}: {m.text}") if m.type == "error" else None)
    pg.on("pageerror", lambda e: errs.append(f"pageerror: {e}"))
    pg.goto(HTML.as_uri())
    pg.wait_for_timeout(1200)

    print("viewport:", dev["viewport"], "dpr:", dev["device_scale_factor"])
    print("JS-ошибки:", errs or "нет")

    # отрисовалось ли колесо
    painted = pg.evaluate("""() => {
        const c = document.getElementById('wheel');
        const d = c.getContext('2d').getImageData(0,0,c.width,c.height).data;
        let on=0; for(let i=3;i<d.length;i+=4) if(d[i]>0) on++;
        return on/(d.length/4);
    }""")
    print(f"закрашено полотна: {painted*100:.1f} %")

    # помещается ли макет в экран телефона
    box = pg.evaluate("""() => {
        const p = document.querySelector('.phone').getBoundingClientRect();
        const btn = document.getElementById('spinBtn').getBoundingClientRect();
        return {phoneW: Math.round(p.width), phoneH: Math.round(p.height),
                winW: innerWidth, winH: innerHeight,
                docW: document.documentElement.scrollWidth,
                btnTop: Math.round(btn.top), btnVisible: btn.top < innerHeight && btn.bottom > 0};
    }""")
    print("геометрия:", box)
    overflow = box["docW"] > box["winW"] + 1
    print("горизонтальный вылет:", "ЕСТЬ" if overflow else "нет")

    # реальный тап по кнопке — как пальцем
    pg.locator("#spinBtn").tap()
    pg.wait_for_timeout(600)
    moving = pg.evaluate("() => spinning")
    print("после тапа колесо крутится:", moving)

    try:
        pg.wait_for_selector("#modal.on", timeout=15000)
        shown = pg.locator("#mVal").inner_text()
        print("окно выигрыша:", shown)
        win_ok = True
    except Exception as e:
        print("окно выигрыша НЕ появилось:", str(e)[:120])
        win_ok = False

    pg.screenshot(path=str(OUT / "safari_iphone.png"), full_page=False)
    print("скриншот safari_iphone.png сохранён")

    ctx.close(); b.close()
    bad = bool(errs) or painted < 0.4 or not moving or not win_ok or overflow
    print("ИТОГ:", "ЕСТЬ ПРОБЛЕМЫ" if bad else "в Safari работает")
    sys.exit(1 if bad else 0)
