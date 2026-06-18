// 用 Chrome 无头模式逐张截图 HTML 幻灯片课件
// 用法: node scripts/lark/shoot-slides.mjs <html路径> <输出目录>
// 例:   node scripts/lark/shoot-slides.mjs data/day3/courseware.html data/day3/slides
//
// Chrome 路径优先级: 环境变量 CHROME_PATH > 各系统常见安装位置自动探测
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync, existsSync, unlinkSync } from 'node:fs';
import { resolve, dirname } from 'node:path';

// ---- 定位 Chrome/Chromium ----
function findChrome() {
  if (process.env.CHROME_PATH && existsSync(process.env.CHROME_PATH)) {
    return process.env.CHROME_PATH;
  }
  const candidates = {
    win32: [
      'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
      'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    ],
    darwin: [
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/Applications/Chromium.app/Contents/MacOS/Chromium',
    ],
    linux: [
      '/usr/bin/google-chrome',
      '/usr/bin/chromium',
      '/usr/bin/chromium-browser',
    ],
  };
  for (const p of candidates[process.platform] || []) {
    if (existsSync(p)) return p;
  }
  return null;
}

const CHROME = findChrome();
if (!CHROME) {
  console.error('找不到 Chrome/Chromium。请在 00-env.sh 设置 CHROME_PATH，或安装 Chrome 后重试。');
  process.exit(1);
}

const htmlPath = resolve(process.argv[2] || '');
const outDir = resolve(process.argv[3] || '');
if (!process.argv[2] || !process.argv[3]) {
  console.error('用法: node scripts/lark/shoot-slides.mjs <html路径> <输出目录>');
  process.exit(1);
}
mkdirSync(outDir, { recursive: true });

// 读 HTML，统计幻灯片（section）数量
// 注意: 这里假设 HTML 课件用 <section class="canvas-card"> 标记每页幻灯片，
// 页脚是 <div class="slide-footer">N / M</div>。不同来源的 HTML 课件结构可能不同，
// 若你的课件不是这种结构，改下面的选择器即可。
const html = readFileSync(htmlPath, 'utf-8');
const slideCount = (html.match(/<section class="canvas-card/g) || []).length;
if (slideCount === 0) {
  console.error('未检测到 <section class="canvas-card"> 幻灯片。请检查 HTML 结构或修改本脚本选择器。');
  process.exit(1);
}
console.log(`检测到 ${slideCount} 张幻灯片`);

// 为每张幻灯片生成一个只显示该张的临时 HTML，再截图
// 注意: 临时 HTML 必须写在原 HTML 同目录，否则相对路径引用的图片(<img src="xx.jpg">)会找不到而裂图。
const htmlDir = dirname(htmlPath);
for (let i = 0; i < slideCount; i++) {
  const css = `<style>.deck>section{display:none!important}.deck>section:nth-of-type(${i + 1}){display:flex!important}.deck{padding:0!important;gap:0!important}body{background:#0d1b3e}</style>`;
  const injected = html.replace('</head>', css + '</head>');
  const tmpHtml = resolve(htmlDir, `_tmp-${i}.html`);
  writeFileSync(tmpHtml, injected, 'utf-8');
  const outPng = resolve(outDir, `slide-${String(i).padStart(2, '0')}.png`);
  try {
    execFileSync(CHROME, [
      '--headless', '--disable-gpu', '--hide-scrollbars',
      `--screenshot=${outPng}`,
      '--window-size=1280,720',
      `file:///${tmpHtml.replace(/\\/g, '/')}`,
    ], { stdio: 'pipe' });
    console.log(`  slide-${String(i).padStart(2, '0')}.png OK`);
  } catch (e) {
    console.error(`  slide ${i} 失败: ${e.message}`);
  } finally {
    try { unlinkSync(tmpHtml); } catch {}
  }
}
console.log('完成');
