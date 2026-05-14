"""
generate_docs.py
Parse toàn bộ file .gd trong project SekaiRPG và sinh ra docs/index.html
"""
import os, re, json
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).parent
OUT  = ROOT / "docs"
SKIP = {".git", ".godot", "Export", "Assets", "Music", "Art", "Data"}

# ─── PARSER ───────────────────────────────────────────────────────────────────

def extract_block_docstring(text):
    """Lấy chuỗi docstring triple-quote đầu tiên."""
    m = re.search(r'"""(.*?)"""', text, re.DOTALL)
    return m.group(1).strip() if m else ""

def parse_file(path: Path):
    src = path.read_text(encoding="utf-8", errors="ignore")
    lines = src.splitlines()

    info = {
        "path": str(path.relative_to(ROOT)).replace("\\", "/"),
        "name": path.name,
        "extends": "",
        "class_name": "",
        "docstring": "",
        "functions": [],
        "variables": [],
    }

    # extends / class_name từ những dòng đầu
    for line in lines[:10]:
        m = re.match(r'^extends\s+(\S+)', line)
        if m: info["extends"] = m.group(1)
        m = re.match(r'^class_name\s+(\S+)', line)
        if m: info["class_name"] = m.group(1)

    # Module docstring: triple-quote ngay sau extends/class_name
    # Tìm block """ đầu tiên trong ~30 dòng đầu
    top_src = "\n".join(lines[:40])
    info["docstring"] = extract_block_docstring(top_src)

    # Biến cấp module (var, const, @export var)
    for line in lines:
        m = re.match(r'^(?:@export\s+)?(?:var|const)\s+(\w+)(?:\s*:\s*(\w+))?', line.strip())
        if m:
            vname = m.group(1)
            vtype = m.group(2) or ""
            info["variables"].append({"name": vname, "type": vtype})

    # Hàm: lấy tên + tham số + docstring/comment liền sau
    func_pattern = re.compile(r'^(func\s+(\w+)\s*\(([^)]*)\)(?:\s*->\s*\S+)?)\s*:', re.MULTILINE)
    for fm in func_pattern.finditer(src):
        fname  = fm.group(2)
        fparams = fm.group(3).strip()
        fstart  = fm.end()

        # Lấy text ngay sau dấu ':' để tìm docstring/comment
        snippet = src[fstart:fstart+600]
        doc = ""

        # Triple-quote docstring
        dq = re.match(r'\s*"""(.*?)"""', snippet, re.DOTALL)
        if dq:
            doc = dq.group(1).strip()
        else:
            # Single-line # comment ngay sau
            cm = re.match(r'\s*#\s*(.+)', snippet)
            if cm:
                doc = cm.group(1).strip()

        info["functions"].append({
            "name": fname,
            "params": fparams,
            "doc": doc,
        })

    return info

def collect_files():
    files = []
    for gd in sorted(ROOT.rglob("*.gd")):
        parts = set(gd.relative_to(ROOT).parts)
        if parts & SKIP:
            continue
        files.append(parse_file(gd))
    return files

# ─── BUILD TREE ───────────────────────────────────────────────────────────────

def build_tree(files):
    """Chuyển list file thành dict cây thư mục."""
    tree = {}
    for f in files:
        parts = Path(f["path"]).parts
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node[parts[-1]] = f
    return tree

# ─── HTML GENERATION ──────────────────────────────────────────────────────────

CSS = """
:root{
  --bg:#0d0f14;--sidebar:#111520;--panel:#161b27;--border:#252d40;
  --acc:#5eead4;--acc2:#818cf8;--text:#e2e8f0;--muted:#64748b;
  --fn:#f8fafc;--tag:#334155;--warn:#fbbf24;
  font-family:'Segoe UI',system-ui,sans-serif;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);display:flex;flex-direction:column;height:100vh;overflow:hidden}
/* Header */
header{background:var(--sidebar);border-bottom:1px solid var(--border);
  padding:14px 24px;display:flex;align-items:center;gap:16px;flex-shrink:0}
header h1{font-size:1.1rem;font-weight:700;color:var(--acc);letter-spacing:.04em}
header span{color:var(--muted);font-size:.8rem}
#search{margin-left:auto;background:var(--panel);border:1px solid var(--border);
  color:var(--text);padding:6px 12px;border-radius:6px;font-size:.85rem;width:220px;outline:none}
#search:focus{border-color:var(--acc)}
/* Layout */
.layout{display:flex;flex:1;overflow:hidden}
/* Sidebar */
aside{width:280px;min-width:220px;background:var(--sidebar);border-right:1px solid var(--border);
  overflow-y:auto;flex-shrink:0;padding:12px 0}
/* Tree */
.tree-item{display:flex;align-items:center;gap:6px;padding:4px 12px;
  cursor:pointer;font-size:.82rem;border-radius:0;transition:background .15s;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.tree-item:hover{background:rgba(94,234,212,.07)}
.tree-item.active{background:rgba(94,234,212,.12);color:var(--acc)}
.tree-folder{color:var(--acc2);font-weight:600;font-size:.8rem;
  padding:6px 12px;cursor:pointer;display:flex;align-items:center;gap:6px;
  user-select:none;border-radius:0}
.tree-folder:hover{background:rgba(129,140,248,.08)}
.tree-folder .arrow{transition:transform .2s;display:inline-block;font-size:.65rem}
.tree-folder.open .arrow{transform:rotate(90deg)}
.tree-children{display:none;padding-left:14px}
.tree-children.open{display:block}
.icon-folder{color:var(--acc2)}
.icon-file{color:var(--muted);font-size:.75rem}
/* Main panel */
main{flex:1;overflow-y:auto;padding:32px 40px}
.welcome{text-align:center;padding:80px 20px;color:var(--muted)}
.welcome h2{font-size:1.6rem;color:var(--acc);margin-bottom:8px}
/* File doc */
.file-header{margin-bottom:24px}
.file-header h2{font-size:1.4rem;font-weight:700;color:var(--fn);margin-bottom:4px}
.meta{display:flex;gap:8px;flex-wrap:wrap;margin-top:8px}
.badge{background:var(--tag);color:var(--acc);padding:2px 10px;border-radius:20px;font-size:.75rem}
.badge.ext{color:var(--acc2)}
.docstring{background:var(--panel);border-left:3px solid var(--acc);
  padding:14px 18px;border-radius:0 8px 8px 0;margin:16px 0;
  font-size:.88rem;line-height:1.7;color:#94a3b8;white-space:pre-wrap}
/* Sections */
h3{font-size:.95rem;font-weight:600;color:var(--muted);letter-spacing:.08em;
  text-transform:uppercase;margin:28px 0 12px;border-bottom:1px solid var(--border);padding-bottom:6px}
/* Functions */
.fn-card{background:var(--panel);border:1px solid var(--border);border-radius:8px;
  margin-bottom:10px;overflow:hidden;transition:border-color .2s}
.fn-card:hover{border-color:var(--acc)}
.fn-sig{padding:12px 16px;font-family:monospace;font-size:.85rem;
  display:flex;gap:8px;align-items:baseline;cursor:pointer}
.fn-kw{color:var(--acc2)}
.fn-name{color:var(--acc);font-weight:700}
.fn-params{color:#94a3b8}
.fn-doc{padding:8px 16px 14px;font-size:.82rem;color:#64748b;
  line-height:1.7;border-top:1px solid var(--border);white-space:pre-wrap;display:none}
.fn-card.open .fn-doc{display:block}
/* Variables */
.var-table{width:100%;border-collapse:collapse;font-size:.83rem}
.var-table th{text-align:left;color:var(--muted);font-weight:500;
  padding:6px 12px;border-bottom:1px solid var(--border)}
.var-table td{padding:5px 12px;border-bottom:1px solid rgba(37,45,64,.5)}
.var-table tr:hover td{background:rgba(94,234,212,.04)}
.vname{color:var(--acc);font-family:monospace}
.vtype{color:var(--acc2);font-size:.78rem}
/* Scrollbar */
::-webkit-scrollbar{width:6px}
::-webkit-scrollbar-track{background:var(--bg)}
::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
"""

JS = r"""
const DATA = __DATA__;

// Build sidebar tree
const aside = document.getElementById('sidebar');
function buildTree(node, parent, depth=0){
  for(const [key, val] of Object.entries(node)){
    if(val.path){
      // leaf = file
      const el = document.createElement('div');
      el.className='tree-item';
      el.style.paddingLeft=(12+depth*14)+'px';
      el.innerHTML=`<span class="icon-file">📄</span> ${key}`;
      el.dataset.path = val.path;
      el.onclick=()=>showFile(val, el);
      parent.appendChild(el);
    } else {
      // folder
      const folder = document.createElement('div');
      folder.className='tree-folder';
      folder.style.paddingLeft=(12+depth*14)+'px';
      folder.innerHTML=`<span class="arrow">▶</span><span class="icon-folder">📁</span> ${key}`;
      parent.appendChild(folder);
      const children = document.createElement('div');
      children.className='tree-children';
      parent.appendChild(children);
      buildTree(val, children, depth+1);
      folder.onclick=()=>{
        folder.classList.toggle('open');
        children.classList.toggle('open');
      };
    }
  }
}
buildTree(DATA.tree, aside);

// Show file details
let activeEl = null;
function showFile(f, el){
  if(activeEl){ activeEl.classList.remove('active'); }
  el.classList.add('active');
  activeEl = el;

  const main = document.getElementById('main');
  const path = f.path;
  const vars = (f.variables||[]).filter(v=>!v.name.startsWith('_'));
  const fns  = f.functions||[];

  let html = `<div class="file-header">
    <h2>📄 ${f.name}</h2>
    <div style="color:var(--muted);font-size:.8rem;margin-top:2px">${path}</div>
    <div class="meta">`;
  if(f.class_name) html+=`<span class="badge">${f.class_name}</span>`;
  if(f.extends)    html+=`<span class="badge ext">extends ${f.extends}</span>`;
  html+=`</div></div>`;

  if(f.docstring) html+=`<div class="docstring">${esc(f.docstring)}</div>`;

  if(vars.length){
    html+=`<h3>Thuộc tính (${vars.length})</h3>
    <table class="var-table"><thead><tr><th>Tên</th><th>Kiểu</th></tr></thead><tbody>`;
    vars.forEach(v=>{
      html+=`<tr><td class="vname">${esc(v.name)}</td><td class="vtype">${esc(v.type)}</td></tr>`;
    });
    html+=`</tbody></table>`;
  }

  if(fns.length){
    html+=`<h3>Hàm (${fns.length})</h3>`;
    fns.forEach((fn,i)=>{
      const id=`fn${i}`;
      html+=`<div class="fn-card" id="${id}">
        <div class="fn-sig" onclick="toggle('${id}')">
          <span class="fn-kw">func</span>
          <span class="fn-name">${esc(fn.name)}</span>
          <span class="fn-params">(${esc(fn.params)})</span>
        </div>`;
      if(fn.doc) html+=`<div class="fn-doc">${esc(fn.doc)}</div>`;
      html+=`</div>`;
    });
  }

  main.innerHTML = html;
}

function toggle(id){
  document.getElementById(id).classList.toggle('open');
}

function esc(s){ return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

// Search
document.getElementById('search').addEventListener('input', function(){
  const q = this.value.toLowerCase();
  document.querySelectorAll('.tree-item').forEach(el=>{
    const match = el.dataset.path.toLowerCase().includes(q);
    el.style.display = match ? '' : 'none';
  });
  // Auto-open folders that have visible children
  document.querySelectorAll('.tree-children').forEach(ch=>{
    const hasVisible = [...ch.querySelectorAll('.tree-item')].some(e=>e.style.display!=='none');
    const folder = ch.previousElementSibling;
    if(hasVisible){ ch.classList.add('open'); folder && folder.classList.add('open'); }
    else { ch.classList.remove('open'); folder && folder.classList.remove('open'); }
  });
});
"""

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SekaiRPG – Tài liệu kỹ thuật</title>
<style>{css}</style>
</head>
<body>
<header>
  <h1>⚔ SekaiRPG</h1>
  <span>Tài liệu kỹ thuật – tự động sinh từ GDScript</span>
  <input id="search" type="search" placeholder="Tìm file...">
</header>
<div class="layout">
  <aside id="sidebar"></aside>
  <main id="main">
    <div class="welcome">
      <h2>⚔ SekaiRPG Docs</h2>
      <p>Chọn file ở cây thư mục bên trái để xem tài liệu</p>
    </div>
  </main>
</div>
<script>
{js}
</script>
</body>
</html>"""

# ─── MAIN ─────────────────────────────────────────────────────────────────────

def main():
    print("Đang parse các file .gd ...")
    files = collect_files()
    print(f"  → Tìm thấy {len(files)} file")

    tree = build_tree(files)

    data_json = json.dumps({"files": files, "tree": tree}, ensure_ascii=False, indent=None)
    js_final  = JS.replace("__DATA__", data_json)

    OUT.mkdir(exist_ok=True)
    html = HTML_TEMPLATE.format(css=CSS, js=js_final)
    out_path = OUT / "index.html"
    out_path.write_text(html, encoding="utf-8")
    print(f"  → Đã xuất: {out_path}")
    print("Xong! Mở docs/index.html trong trình duyệt để xem.")

if __name__ == "__main__":
    main()
