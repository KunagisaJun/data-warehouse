/* eslint-disable no-unused-vars */
/* global module */

const { Plugin, Notice, PluginSettingTab, Setting, TFile } = require("obsidian");

// Hardcoded strings
const SQL_TAG = "sql";
const PARENT_SECTION_HEADING = "zc-plugin-parent-node";
const FOCUS_TAG = "focus"; // fixed focus tag

const DEFAULT_SETTINGS = {
  maxNodes: 5000,
  resetGraphFilterToSql: true
};

function normalizeTagValue(tag) {
  const t = String(tag || "").trim();
  return t.startsWith("#") ? t.slice(1) : t;
}

function focusTagToFilterQuery(tagNoHash) {
  return `tag:#${tagNoHash}`;
}

/**
 * SQL note detection:
 * - YAML frontmatter tags includes sql (or #sql)
 * - OR inline tags contain #sql
 */
function isSqlNote(app, file) {
  const cache = app.metadataCache.getFileCache(file);
  if (!cache) return false;

  const fmTags = cache.frontmatter && cache.frontmatter.tags;

  if (Array.isArray(fmTags)) {
    for (const t of fmTags) {
      if (typeof t !== "string") continue;
      if (normalizeTagValue(t) === SQL_TAG) return true;
    }
  } else if (typeof fmTags === "string") {
    if (normalizeTagValue(fmTags) === SQL_TAG) return true;
    const parts = fmTags.split(",").map((s) => normalizeTagValue(s.trim()));
    if (parts.includes(SQL_TAG)) return true;
  }

  if (Array.isArray(cache.tags)) {
    for (const tagObj of cache.tags) {
      const norm = normalizeTagValue(tagObj.tag);
      if (norm === SQL_TAG) return true;
    }
  }

  return false;
}

/**
 * Extract ONLY wikilink targets from:
 * ## zc-plugin-parent-node
 * - [[A]]
 * * [[B|alias]]
 *
 * - Stop at ANY heading level (#, ##, ###, ####, ...)
 * - Only parse list item lines ("- " or "* ")
 */
function extractParentLinkTargetsFromMarkdown(markdown) {
  const lines = String(markdown || "").split(/\r?\n/);
  let startIdx = -1;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line === `## ${PARENT_SECTION_HEADING}`) {
      startIdx = i + 1;
      break;
    }
  }
  if (startIdx === -1) return [];

  const parents = [];

  for (let i = startIdx; i < lines.length; i++) {
    const raw = lines[i];
    const trimmed = raw.trim();

    if (trimmed.startsWith("#")) break;

    if (!(trimmed.startsWith("- ") || trimmed.startsWith("* "))) continue;

    let idx = 0;
    while (idx < raw.length) {
      const open = raw.indexOf("[[", idx);
      if (open === -1) break;
      const close = raw.indexOf("]]", open + 2);
      if (close === -1) break;

      const inner = raw.substring(open + 2, close).trim();
      const beforePipe = inner.split("|")[0].trim();
      const targetNoHeading = beforePipe.split("#")[0].trim();

      if (targetNoHeading) parents.push(targetNoHeading);
      idx = close + 2;
    }
  }

  const seen = new Set();
  const out = [];
  for (const p of parents) {
    if (!seen.has(p)) {
      seen.add(p);
      out.push(p);
    }
  }
  return out;
}

/**
 * Frontmatter tag helpers using processFrontMatter (safe YAML editing).
 */
async function removeTagFromFrontmatter(app, file, tagNoHash) {
  const target = normalizeTagValue(tagNoHash);

  await app.fileManager.processFrontMatter(file, (fm) => {
    let tags = [];
    const existing = fm.tags;

    if (Array.isArray(existing)) {
      tags = existing
        .filter((x) => typeof x === "string")
        .map((x) => normalizeTagValue(x));
    } else if (typeof existing === "string") {
      tags = existing
        .split(",")
        .map((s) => normalizeTagValue(s.trim()))
        .filter(Boolean);
    } else {
      tags = [];
    }

    fm.tags = tags.filter((t) => t !== target);
  });
}

async function addTagToFrontmatter(app, file, tagNoHash) {
  const target = normalizeTagValue(tagNoHash);

  await app.fileManager.processFrontMatter(file, (fm) => {
    let tags = [];
    const existing = fm.tags;

    if (Array.isArray(existing)) {
      tags = existing
        .filter((x) => typeof x === "string")
        .map((x) => normalizeTagValue(x));
    } else if (typeof existing === "string") {
      tags = existing
        .split(",")
        .map((s) => normalizeTagValue(s.trim()))
        .filter(Boolean);
    } else {
      tags = [];
    }

    if (!tags.includes(target)) tags.push(target);
    fm.tags = tags;
  });
}

/**
 * Build ONLY child->parents map (resolved to file paths).
 * We intentionally DO NOT build parent->children here;
 * downstream will be derived by scanning child->parents with caching.
 */
async function buildChildToParentsMap(app, sqlFiles) {
  const childToParents = new Map(); // Map<childPath, Set<parentPath>>

  for (const child of sqlFiles) {
    const md = await app.vault.cachedRead(child);
    const parentTargets = extractParentLinkTargetsFromMarkdown(md);

    if (!childToParents.has(child.path)) childToParents.set(child.path, new Set());

    for (const linktext of parentTargets) {
      // resolve in the child's context
      const dest = app.metadataCache.getFirstLinkpathDest(linktext, child.path);
      if (!dest) continue;
      if (!(dest instanceof TFile)) continue;
      if (dest.extension !== "md") continue;

      // SQL-only scope (per your cleanup rules)
      if (!isSqlNote(app, dest)) continue;

      childToParents.get(child.path).add(dest.path);
    }
  }

  return childToParents;
}

/**
 * Correct scope closure:
 * - Upstream: follow parents ONLY recursively
 * - Downstream: follow children ONLY recursively
 *
 * Downstream derivation:
 * - children(P) = all SQL notes C where childToParents[C] contains P
 * - Implemented as scan + memoized cache so each parent is scanned once per run.
 */
function computeScopedClosureWithScanningDownstream(startPath, childToParents, maxNodes) {
  const upstream = new Set();
  const downstream = new Set();

  const budget = { count: 1 };
  let capped = false;

  // Cache: parentPath -> array of childPaths
  const childrenCache = new Map();

  function getParents(nodePath) {
    return childToParents.get(nodePath);
  }

  function getChildren(parentPath) {
    if (childrenCache.has(parentPath)) return childrenCache.get(parentPath);

    const children = [];
    for (const [childPath, parentsSet] of childToParents.entries()) {
      if (parentsSet && parentsSet.has(parentPath)) children.push(childPath);
    }
    childrenCache.set(parentPath, children);
    return children;
  }

  function bfs(seed, neighborFn, visitedSet) {
    const q = [seed];
    while (q.length) {
      const cur = q.shift();
      const neigh = neighborFn(cur);
      if (!neigh) continue;

      // neigh can be Set or Array
      const iter = Array.isArray(neigh) ? neigh : Array.from(neigh);

      for (const n of iter) {
        if (n === seed) continue;
        if (visitedSet.has(n)) continue;

        visitedSet.add(n);
        q.push(n);

        budget.count++;
        if (budget.count >= maxNodes) return true; // capped
      }
    }
    return false;
  }

  // Upstream only
  capped = bfs(startPath, getParents, upstream);
  if (capped) {
    const closure = new Set([startPath, ...upstream]);
    return { closure, capped: true, upstreamCount: upstream.size, downstreamCount: 0 };
  }

  // Downstream only (scan-based)
  capped = bfs(startPath, getChildren, downstream);

  const closure = new Set([startPath]);
  for (const u of upstream) closure.add(u);
  for (const d of downstream) closure.add(d);

  return { closure, capped, upstreamCount: upstream.size, downstreamCount: downstream.size };
}

class ZcFocusSettingTab extends PluginSettingTab {
  constructor(app, plugin) {
    super(app, plugin);
    this.plugin = plugin;
  }

  display() {
    const { containerEl } = this;
    containerEl.empty();

    containerEl.createEl("h2", { text: "Focus Lineage Closure" });

    new Setting(containerEl)
      .setName("Max nodes cap")
      .setDesc("Stops traversal if the upstream+downstream union reaches this many notes.")
      .addText((t) =>
        t
          .setPlaceholder("5000")
          .setValue(String(this.plugin.settings.maxNodes))
          .onChange(async (v) => {
            const n = Number(v);
            if (!Number.isFinite(n) || n <= 0) return;
            this.plugin.settings.maxNodes = Math.floor(n);
            await this.plugin.saveData(this.plugin.settings);
          })
      );

    new Setting(containerEl)
      .setName("Reset Graph filter to tag:#sql on clear")
      .setDesc("If off, the plugin will try to clear the graph filter instead.")
      .addToggle((tog) =>
        tog
          .setValue(this.plugin.settings.resetGraphFilterToSql)
          .onChange(async (v) => {
            this.plugin.settings.resetGraphFilterToSql = v;
            await this.plugin.saveData(this.plugin.settings);
          })
      );

    containerEl.createEl("p", { text: `Focus tag used: #${FOCUS_TAG} (fixed)` });
  }
}

module.exports = class ZcFocusLineageClosurePlugin extends Plugin {
  async onload() {
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());

    this.addCommand({
      id: "focus-lineage-closure",
      name: "Focus lineage closure",
      callback: async () => {
        const start = this.getActiveMarkdownFile();
        if (!start) {
          new Notice("No active markdown file.");
          return;
        }
        await this.focusLineageClosureFromFile(start);
      }
    });

    this.addCommand({
      id: "clear-lineage-focus",
      name: "Clear lineage focus",
      callback: async () => this.clearLineageFocus()
    });

    // Right-click in File Explorer
    this.registerEvent(
      this.app.workspace.on("file-menu", (menu, file) => {
        if (!(file instanceof TFile)) return;
        if (file.extension !== "md") return;

        menu.addItem((item) => {
          item
            .setTitle("Focus lineage closure")
            .setIcon("dot-network")
            .onClick(async () => {
              await this.focusLineageClosureFromFile(file);
            });
        });

        menu.addItem((item) => {
          item
            .setTitle("Clear lineage focus")
            .setIcon("trash")
            .onClick(async () => {
              await this.clearLineageFocus();
            });
        });
      })
    );

    this.addSettingTab(new ZcFocusSettingTab(this.app, this));
  }

  getActiveMarkdownFile() {
    const f = this.app.workspace.getActiveFile();
    if (!f) return null;
    if (f.extension !== "md") return null;
    return f;
  }

  async focusLineageClosureFromFile(startFile) {
    if (!(startFile instanceof TFile) || startFile.extension !== "md") {
      new Notice("Target is not a markdown file.");
      return;
    }

    if (!isSqlNote(this.app, startFile)) {
      new Notice("Target note is not tagged #sql. No action taken.");
      return;
    }

    const allMd = this.app.vault.getMarkdownFiles();
    const sqlFiles = allMd.filter((f) => isSqlNote(this.app, f));

    // Remove fixed focus tag first from ALL #sql notes
    for (const f of sqlFiles) {
      await removeTagFromFrontmatter(this.app, f, FOCUS_TAG);
    }

    // Build child->parents map once (resolved to file paths)
    const childToParents = await buildChildToParentsMap(this.app, sqlFiles);

    // Compute correct scope with downstream scan+cache
    const { closure, capped, upstreamCount, downstreamCount } =
      computeScopedClosureWithScanningDownstream(startFile.path, childToParents, this.settings.maxNodes);

    if (capped) {
      new Notice(`Warning: scope hit max cap (${this.settings.maxNodes}). Tagged partial set.`);
    }

    // Apply focus tag to closure nodes (SQL-only)
    for (const p of closure) {
      const f = this.app.vault.getAbstractFileByPath(p);
      if (!(f instanceof TFile)) continue;
      if (f.extension !== "md") continue;
      if (!isSqlNote(this.app, f)) continue;
      await addTagToFrontmatter(this.app, f, FOCUS_TAG);
    }

    // Auto-filter graph
    // If you want to also require sql, change to: const filter = "tag:#sql tag:#focus";
    const filter = focusTagToFilterQuery(FOCUS_TAG);
    const graphSet = await this.trySetNativeGraphFilter(filter);

    const detail = `U:${upstreamCount} D:${downstreamCount} Total:${closure.size}`;
    if (graphSet) {
      new Notice(`Tagged ${closure.size} notes with #${FOCUS_TAG} (${detail}) and set Graph filter.`);
    } else {
      new Notice(`Tagged ${closure.size} notes with #${FOCUS_TAG} (${detail}). Set Graph filter to: ${filter}`);
    }
  }

  async clearLineageFocus() {
    const allMd = this.app.vault.getMarkdownFiles();
    const sqlFiles = allMd.filter((f) => isSqlNote(this.app, f));

    for (const f of sqlFiles) {
      await removeTagFromFrontmatter(this.app, f, FOCUS_TAG);
    }

    const desired = this.settings.resetGraphFilterToSql ? "tag:#sql" : "";
    const ok = await this.trySetNativeGraphFilter(desired);

    new Notice(ok ? "Cleared lineage focus and reset Graph filter." : "Cleared lineage focus. Graph filter not changed.");
  }

  /**
   * Best-effort Graph filter setter (no stable public API exists).
   * 1) ensure graph leaf exists & is active
   * 2) try leaf.setViewState with common keys
   * 3) try internal setters
   * 4) DOM fallback inside the leaf
   */
  async trySetNativeGraphFilter(filter) {
    const getGraphLeaf = () => {
      const leaves = this.app.workspace.getLeavesOfType("graph");
      return leaves && leaves[0];
    };

    let leaf = getGraphLeaf();

    if (!leaf) {
      const idsToTry = ["graph:open", "graph:open-global", "workspace:open-graph"];
      for (const id of idsToTry) {
        try {
          if (this.app.commands && typeof this.app.commands.executeCommandById === "function") {
            this.app.commands.executeCommandById(id);
            break;
          }
        } catch (_) {}
      }
      leaf = getGraphLeaf();
    }

    if (!leaf) return false;

    try {
      this.app.workspace.setActiveLeaf(leaf, { focus: true });
    } catch (_) {}

    const view = leaf.view;

    // 1) View state
    try {
      if (typeof leaf.getViewState === "function" && typeof leaf.setViewState === "function") {
        const cur = leaf.getViewState();
        const curState = (cur && cur.state) ? cur.state : {};
        const next = {
          ...cur,
          state: {
            ...curState,
            filter: filter,
            query: filter,
            searchQuery: filter
          }
        };
        await leaf.setViewState(next, { focus: true });
        return true;
      }
    } catch (_) {}

    // 2) Internal setters
    try {
      if (typeof view.setFilter === "function") {
        view.setFilter(filter);
        return true;
      }
      if (typeof view.setQuery === "function") {
        view.setQuery(filter);
        return true;
      }
      if (view.dataEngine && typeof view.dataEngine.setQuery === "function") {
        view.dataEngine.setQuery(filter);
        return true;
      }
      if (view.graph && typeof view.graph.setQuery === "function") {
        view.graph.setQuery(filter);
        return true;
      }
      if (view.data && typeof view.onChangeFilter === "function") {
        view.data.filter = filter;
        view.onChangeFilter();
        return true;
      }
    } catch (_) {}

    // 3) DOM fallback
    try {
      const leafEl = leaf.containerEl || (leaf.view && leaf.view.containerEl);
      if (!leafEl) return false;

      const graphRoot =
        leafEl.querySelector('.workspace-leaf-content[data-type="graph"]') ||
        leafEl.querySelector('[data-type="graph"]') ||
        leafEl;

      const inputs = graphRoot.querySelectorAll('input[type="text"], input[type="search"], input:not([type])');
      if (!inputs || inputs.length === 0) return false;

      const score = (inp) => {
        const ph = (inp.getAttribute("placeholder") || "").toLowerCase();
        const aria = (inp.getAttribute("aria-label") || "").toLowerCase();
        const cls = (inp.className || "").toLowerCase();
        let s = 0;
        if (ph.includes("filter")) s += 5;
        if (ph.includes("search")) s += 3;
        if (aria.includes("filter")) s += 5;
        if (aria.includes("search")) s += 3;
        if (cls.includes("filter")) s += 3;
        if (cls.includes("search")) s += 2;
        return s;
      };

      let best = null;
      let bestScore = -1;
      for (const inp of inputs) {
        if (!(inp instanceof HTMLInputElement)) continue;
        const st = window.getComputedStyle(inp);
        if (st.display === "none" || st.visibility === "hidden") continue;
        const sc = score(inp);
        if (sc > bestScore) {
          bestScore = sc;
          best = inp;
        }
      }

      if (!best) {
        for (const inp of inputs) {
          if (!(inp instanceof HTMLInputElement)) continue;
          const st = window.getComputedStyle(inp);
          if (st.display === "none" || st.visibility === "hidden") continue;
          best = inp;
          break;
        }
      }

      if (!best) return false;

      best.value = filter;
      best.dispatchEvent(new Event("input", { bubbles: true }));
      best.dispatchEvent(new Event("change", { bubbles: true }));
      best.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", bubbles: true }));
      best.dispatchEvent(new KeyboardEvent("keyup", { key: "Enter", bubbles: true }));

      return true;
    } catch (_) {
      return false;
    }
  }
};
