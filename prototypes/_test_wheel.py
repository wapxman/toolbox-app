# -*- coding: utf-8 -*-
"""Проверка прототипа колеса: вёрстка, шансы и — главное — совпадение
сектора под указателем с объявленным призом."""
import json, math, pathlib, sys
from playwright.sync_api import sync_playwright

HTML = pathlib.Path(r"C:\Users\User\Desktop\GitHub\toolbox-app\prototypes\fortune_wheel.html")
OUT  = pathlib.Path(r"C:\Users\User\Desktop\GitHub\toolbox-app\prototypes")

with sync_playwright() as pw:
    b = pw.chromium.launch()
    pg = b.new_page(viewport={"width": 460, "height": 1000}, device_scale_factor=2)
    errors = []
    pg.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.goto(HTML.as_uri())
    pg.wait_for_timeout(900)

    print("JS-ошибки:", errors or "нет")

    # 1. колесо реально нарисовано (не пустой canvas)
    painted = pg.evaluate("""() => {
        const c = document.getElementById('wheel');
        const d = c.getContext('2d').getImageData(0,0,c.width,c.height).data;
        let on = 0;
        for (let i=3;i<d.length;i+=4) if (d[i]>0) on++;
        return on / (d.length/4);
    }""")
    print(f"закрашено полотна: {painted*100:.1f} %")

    # 2. шансы: 200+300 тысяч должны давать 99 %
    sim = pg.evaluate("""() => {
        const n=200000, hit={};
        for(let i=0;i<n;i++){const id=pickPrize(); hit[id]=(hit[id]||0)+1;}
        const r={}; for(const k in PRIZES) r[k]=(hit[k]||0)/n*100;
        return r;
    }""")
    core = sim["p200"] + sim["p300"]
    for k, v in sim.items():
        print(f"  {k:8} {v:7.3f} %")
    print(f"200-300 тысяч суммарно: {core:.2f} %")

    # 2b. подписи не должны заезжать под ступицу и за обод
    fit = pg.evaluate("""() => {
        const c = document.getElementById('wheel'), x = c.getContext('2d');
        const R = c.width/2, k = c.width/636;
        // радиус ступицы берём из реального DOM, а не из константы
        const hubEl = document.querySelector('.hub').getBoundingClientRect();
        const cssW  = c.getBoundingClientRect().width;
        const hubR  = (hubEl.width/2) * (c.width / cssW);
        const out = [];
        for (const id of new Set(SECTORS)) {
            const p = PRIZES[id];
            if (p.unit === 'сум') continue;
            x.font = '900 ' + Math.round(22*k) + 'px Arial,Helvetica,sans-serif';
            const w = x.measureText(p.label).width;
            const inner = (R - 66*k) - w;        // ближний к центру край текста
            x.font = Math.round(22*k) + 'px Arial,Helvetica,sans-serif';
            const iw = x.measureText(p.icon).width;
            const iconLeft = (R - 32*k) - iw;    // левый край иконки
            const gap = iconLeft - (R - 66*k);   // зазор между текстом и иконкой
            out.push({label: p.label, inner: +inner.toFixed(1), hubR: +hubR.toFixed(1),
                      margin: +(inner - hubR).toFixed(1), gap: +gap.toFixed(1),
                      ok: inner > hubR + 8*k && gap > 0});
        }
        return out;
    }""")
    for f in fit:
        print(f"  подпись «{f['label']}»: запас до ступицы {f['margin']} px, "
              f"зазор до иконки {f['gap']} px -> {'ок' if f['ok'] else 'ТЕСНО'}")
    bad_fit = [f for f in fit if not f["ok"]]

    # 2c. эмодзи должны реально отрисовываться, а не пустым квадратом
    glyphs = pg.evaluate("""() => {
        const x = document.createElement('canvas').getContext('2d');
        x.font = '27px Arial,Helvetica,sans-serif';
        const ref = x.measureText('\\uFFFF').width;   // заведомо отсутствующий глиф (tofu)
        const r = {};
        for (const id in PRIZES) {
            const g = PRIZES[id].icon;
            r[g] = +(x.measureText(g).width).toFixed(2);
        }
        return {tofu: +ref.toFixed(2), icons: r};
    }""")
    tofu = glyphs["tofu"]
    bad_glyph = [g for g, w in glyphs["icons"].items() if abs(w - tofu) < 0.01]
    print(f"  ширина «квадрата» {tofu} px; иконки: {glyphs['icons']}")
    print("  не отрисовались:", bad_glyph or "нет")

    # 3. ГЛАВНОЕ: сектор под указателем == объявленный приз. 12 прогонов.
    mism = []
    for i in range(12):
        pg.evaluate("() => { attempts = 1; spinning = false; }")
        pg.evaluate("() => spin()")
        pg.wait_for_selector("#modal.on", timeout=15000)
        res = pg.evaluate("""() => {
            const N = SECTORS.length, SEG = 2*Math.PI/N;
            // какой сектор стоит под указателем при текущем rot
            let k = Math.round(-rot/SEG - 0.5) % N; if (k < 0) k += N;
            const err = Math.abs(((-rot/SEG - 0.5) - Math.round(-rot/SEG - 0.5))) * SEG * 180/Math.PI;
            return {underPointer: SECTORS[k], shown: document.getElementById('mVal').textContent,
                    offsetDeg: err};
        }""")
        under = pg.evaluate("(id) => PRIZES[id].label + (PRIZES[id].unit ? ' '+PRIZES[id].unit : '')",
                            res["underPointer"])
        ok = under == res["shown"].strip()
        if not ok:
            mism.append((under, res["shown"]))
        print(f"  спин {i+1:2}: под указателем «{under}» / в окне «{res['shown']}» "
              f"откл. {res['offsetDeg']:.2f}° -> {'OK' if ok else 'РАСХОЖДЕНИЕ'}")
        pg.evaluate("() => document.getElementById('mBtn').click()")
        pg.wait_for_timeout(120)

    print("расхождений:", mism or "нет")

    # 4. скриншоты
    pg.evaluate("() => { document.getElementById('modal').classList.remove('on'); }")
    pg.wait_for_timeout(200)
    pg.locator(".phone").screenshot(path=str(OUT / "wheel_screen.png"))
    pg.evaluate("() => showWin('pDrill')")
    pg.wait_for_timeout(700)
    pg.locator(".phone").screenshot(path=str(OUT / "wheel_win.png"))
    print("скриншоты сохранены")
    b.close()

    if errors or mism or painted < 0.4 or bad_fit or bad_glyph:
        print("ИТОГ: есть дефекты")
        sys.exit(1)
    print("ИТОГ: всё чисто")
