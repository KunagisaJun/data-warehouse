/* eslint-disable no-unused-vars */
/* global module */

const { Plugin, Notice, PluginSettingTab, Setting, TFile } = require("obsidian");

// Hardcoded strings
const SQL_TAG = "sql";

// Two lineage modes (two sections in markdown)
const LINEAGE_MODES = {
  object: {
    modeId: "object",
    title: "Object lineage",
    resultTag: "lineage/object",
    parentSectionHeading: "zc-plugin-parent-node"
  },
  data: {
    modeId: "data",
    title: "Data lineage",
    resultTag: "lineage/data",
    parentSectionHeading: "zc-plugin-parent-node-data"
  }
};

const DEFAULT_SETTINGS = {
  maxNodes: 5000,
  resetGraphFilterToSql: true
};

function normalizeTagValue(tag) {
  const t = String(tag || "").trim();
  return t.startsWith("#") ? t.slice(1) : t;
}

function tagToGraphFilter(tagNoHash) {
  return `tag:#${tagNoHash}`;
}

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
 * ## <heading>
 * - [[A]]
 * * [[B|alias]]
 *
 * Rules:
 * - Header must match exactly "## <heading>"
 * - Stop at ANY heading level (#, ##, ###, ...)
 * - Only parse list item lines "- " or "* "
 */
function extractParentLinkTargetsFromMarkdown(markdown, heading) {
  const lines = String(markdown || "").split(/\r?\n/);
  let startIdx = -1;

  const headerLine = `## ${heading}`;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim() === headerLine) {
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

async function removeTagFromFrontmatter(app, file, tagNoHash) {
  const target = normalizeTagValue(tagNoHash);

  await app.fileManager.processFrontMatter(file, (fm) => {
    let tags = [];
    const existing = fm.tags;

    if (Array.isArray(existing)) {
      tags = existing.filter((x) => typeof x === "string").map((x) => normalizeTagValue(x));
    } else if (typeof existing === "string") {
      tags = existing.split(",").map((s) => normalizeTagValue(s.trim())).filter(Boolean);
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
      tags = existing.filter((x) => typeof x === "string").map((x) => normalizeTagValue(x));
    } else if (typeof existing === "string") {
      tags = existing.split(",").map((s) => normalizeTagValue(s.trim())).filter(Boolean);
    } else {
      tags = [];
    }

    if (!tags.includes(target)) tags.push(target);
    fm.tags = tags;
  });
}

/**
 * Build child->parents map (resolved to file paths) for a given mode.
 */
async function buildChildToParentsMap(app, sqlFiles, mode) {
  const childToParents = new Map(); // Map<childPath, Set<parentPath>>

  for (const child of sqlFiles) {
    const md = await app.vault.cachedRead(child);
    const parentTargets = extractParentLinkTargetsFromMarkdown(md, mode.parentSectionHeading);

    if (!childToParents.has(child.path)) childToParents.set(child.path, new Set());

    for (const linktext of parentTargets) {
      const dest = app.metadataCache.getFirstLinkpathDest(linktext, child.path);
      if (!dest) continue;
      if (!(dest instanceof TFile)) continue;
      if (dest.extension !== "md") continue;
      if (!isSqlNote(app, dest)) continue; // SQL-only scope

      childToParents.get(child.path).add(dest.path);
    }
  }

  return childToParents;
}

/**
 * Data/Object closure:
 * - Upstream: parents only (recursive)
 * - Downstream: children only (recursive), derived by scanning childToParents (cached per parent)
 */
function computeScopedClosureWithScanningDownstream(startPath, childToParents, maxNodes) {
  const upstream = new Set();
  const downstream = new Set();
  const budget = { count: 1 };
  const childrenCache = new Map(); // parentPath -> Array<childPath>

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
      const iter = Array.isArray(neigh) ? neigh : Array.from(neigh);

      for (const n of iter) {
        if (n === seed) continue;
        if (visitedSet.has(n)) continue;

        visitedSet.add(n);
        q.push(n);

        budget.count++;
        if (budget.count >= maxNodes) return true;
      }
    }
    return false;
  }

  let capped = bfs(startPath, getParents, upstream);
  if (capped) {
    const closure = new Set([startPath, ...upstream]);
    return { closure, capped: true, upstreamCount: upstream.size, downstreamCount: 0 };
  }

  capped = bfs(startPath, getChildren, downstream);

  const closure = new Set([startPath]);
  for (const u of upstream) closure.add(u);
  for (const d of downstream) closure.add(d);

  return { closure, capped, upstreamCount: upstream.size, downstreamCount: downstream.size };
}

/**
 * Upstream-only ancestors for a whole seed set, using a child->parents map.
 * Includes the seeds themselves.
 */
function computeUpstreamAncestorsForSet(seedSet, childToParents, maxNodes) {
  const result = new Set();
  const q = [];

  for (const s of seedSet) {
    if (!result.has(s)) {
      result.add(s);
      q.push(s);
      if (result.size >= maxNodes) return { ancestors: result, capped: true };
    }
  }

  while (q.length) {
    const cur = q.shift();
    const parents = childToParents.get(cur);
    if (!parents) continue;

    for (const p of parents) {
      if (result.has(p)) continue;
      result.add(p);
      q.push(p);
      if (result.size >= maxNodes) return { ancestors: result, capped: true };
    }
  }

  return { ancestors: result, capped: false };
}

class ZcLineageSettingTab extends PluginSettingTab {
  constructor(app, plugin) {
    super(app, plugin);
    this.plugin = plugin;
  }

  display() {
    const { containerEl } = this;
    containerEl.empty();

    containerEl.createEl("h2", { text: "Lineage Tracking" });

    new Setting(containerEl)
      .setName("Max nodes cap")
      .setDesc("Stops traversal if upstream+downstream union reaches this many notes.")
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

    containerEl.createEl("p", {
      text:
        "Data mode now tags #lineage/data then also tags upstream object ancestors as #lineage/object."
    });
  }
}

module.exports = class ZcLineagePlugin extends Plugin {
  async onload() {
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());

    this.addCommand({
      id: "lineage-track-object",
      name: "Track lineage: object",
      callback: async () => {
        const start = this.getActiveMarkdownFile();
        if (!start) return new Notice("No active markdown file.");
        await this.runObjectOnlyFromFile(start);
      }
    });

    this.addCommand({
      id: "lineage-track-data-plus-object-ancestors",
      name: "Track lineage: data (plus object ancestors)",
      callback: async () => {
        const start = this.getActiveMarkdownFile();
        if (!start) return new Notice("No active markdown file.");
        await this.runDataPlusObjectAncestorsFromFile(start);
      }
    });

    this.addCommand({
      id: "lineage-clear-all",
      name: "Clear lineage tracking tags",
      callback: async () => this.clearAllLineageTags()
    });

    // Right-click in File Explorer
    this.registerEvent(
      this.app.workspace.on("file-menu", (menu, file) => {
        if (!(file instanceof TFile)) return;
        if (file.extension !== "md") return;

        menu.addItem((item) => {
          item
            .setTitle("Track lineage: object")
            .setIcon("dot-network")
            .onClick(async () => {
              await this.runObjectOnlyFromFile(file);
            });
        });

        menu.addItem((item) => {
          item
            .setTitle("Track lineage: data (plus object ancestors)")
            .setIcon("dot-network")
            .onClick(async () => {
              await this.runDataPlusObjectAncestorsFromFile(file);
            });
        });

        menu.addItem((item) => {
          item
            .setTitle("Clear lineage tracking tags")
            .setIcon("trash")
            .onClick(async () => {
              await this.clearAllLineageTags();
            });
        });
      })
    );

    this.addSettingTab(new ZcLineageSettingTab(this.app, this));
  }

  getActiveMarkdownFile() {
    const f = this.app.workspace.getActiveFile();
    if (!f) return null;
    if (f.extension !== "md") return null;
    return f;
  }

  async clearAllLineageTags() {
    const allMd = this.app.vault.getMarkdownFiles();
    const sqlFiles = allMd.filter((f) => isSqlNote(this.app, f));

    for (const f of sqlFiles) {
      await removeTagFromFrontmatter(this.app, f, LINEAGE_MODES.object.resultTag);
      await removeTagFromFrontmatter(this.app, f, LINEAGE_MODES.data.resultTag);
    }

    const desired = this.settings.resetGraphFilterToSql ? "tag:#sql" : "";
    const ok = await this.trySetNativeGraphFilter(desired);

    new Notice(ok ? "Cleared lineage tracking tags and reset Graph filter." : "Cleared lineage tracking tags. Graph filter not changed.");
  }

  async cleanupTags(sqlFiles) {
    for (const f of sqlFiles) {
      await removeTagFromFrontmatter(this.app, f, LINEAGE_MODES.object.resultTag);
      await removeTagFromFrontmatter(this.app, f, LINEAGE_MODES.data.resultTag);
    }
  }

  /**
   * Object-only = normal closure on object parent section
   */
  async runObjectOnlyFromFile(startFile) {
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

    await this.cleanupTags(sqlFiles);

    const objMap = await buildChildToParentsMap(this.app, sqlFiles, LINEAGE_MODES.object);

    const { closure, capped, upstreamCount, downstreamCount } =
      computeScopedClosureWithScanningDownstream(startFile.path, objMap, this.settings.maxNodes);

    for (const p of closure) {
      const f = this.app.vault.getAbstractFileByPath(p);
      if (f instanceof TFile && f.extension === "md" && isSqlNote(this.app, f)) {
        await addTagToFrontmatter(this.app, f, LINEAGE_MODES.object.resultTag);
      }
    }

    const filter = tagToGraphFilter(LINEAGE_MODES.object.resultTag);
    const graphSet = await this.trySetNativeGraphFilter(filter);

    const detail = `U:${upstreamCount} D:${downstreamCount} Total:${closure.size}`;
    new Notice(
      graphSet
        ? `Tagged ${closure.size} notes with #${LINEAGE_MODES.object.resultTag} (${detail}) and set Graph filter.`
        : `Tagged ${closure.size} notes with #${LINEAGE_MODES.object.resultTag} (${detail}). Set Graph filter to: ${filter}`
    );

    if (capped) new Notice(`Warning: hit max cap (${this.settings.maxNodes}).`);
  }

  /**
   * Data mode (new requested behavior):
   * 1) tag #lineage/data on data-closure (up+down on data graph)
   * 2) then tag #lineage/object on ALL upstream object ancestors of every node in that data closure
   */
  async runDataPlusObjectAncestorsFromFile(startFile) {
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

    await this.cleanupTags(sqlFiles);

    // Build both graphs once
    const dataMap = await buildChildToParentsMap(this.app, sqlFiles, LINEAGE_MODES.data);
    const objMap = await buildChildToParentsMap(this.app, sqlFiles, LINEAGE_MODES.object);

    // Phase 1: data closure
    const dataRes =
      computeScopedClosureWithScanningDownstream(startFile.path, dataMap, this.settings.maxNodes);

    // Tag lineage/data for data closure nodes
    for (const p of dataRes.closure) {
      const f = this.app.vault.getAbstractFileByPath(p);
      if (f instanceof TFile && f.extension === "md" && isSqlNote(this.app, f)) {
        await addTagToFrontmatter(this.app, f, LINEAGE_MODES.data.resultTag);
      }
    }

    // Phase 2: object ancestors upstream for every data node in scope
    const ancRes =
      computeUpstreamAncestorsForSet(dataRes.closure, objMap, this.settings.maxNodes);

    for (const p of ancRes.ancestors) {
      const f = this.app.vault.getAbstractFileByPath(p);
      if (f instanceof TFile && f.extension === "md" && isSqlNote(this.app, f)) {
        await addTagToFrontmatter(this.app, f, LINEAGE_MODES.object.resultTag);
      }
    }

    // Graph filter: show BOTH tags. (If OR isn't supported on your build, set manually.)
    const combinedFilter = `${tagToGraphFilter(LINEAGE_MODES.data.resultTag)} OR ${tagToGraphFilter(LINEAGE_MODES.object.resultTag)}`;
    const graphSet = await this.trySetNativeGraphFilter(combinedFilter);

    const detail = `Data(U:${dataRes.upstreamCount} D:${dataRes.downstreamCount} T:${dataRes.closure.size}) + ObjAnc:${ancRes.ancestors.size}`;
    new Notice(
      graphSet
        ? `Tagged data scope + object ancestors (${detail}) and set Graph filter.`
        : `Tagged data scope + object ancestors (${detail}). Set Graph filter to: ${combinedFilter}`
    );

    if (dataRes.capped || ancRes.capped) {
      new Notice(`Warning: hit max cap (${this.settings.maxNodes}).`);
    }
  }

  /**
   * Best-effort graph filter setter (Obsidian has no stable public API for this).
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
          state: { ...curState, filter, query: filter, searchQuery: filter }
        };
        await leaf.setViewState(next, { focus: true });
        return true;
      }
    } catch (_) {}

    // 2) Internal setters
    try {
      if (typeof view.setFilter === "function") { view.setFilter(filter); return true; }
      if (typeof view.setQuery === "function") { view.setQuery(filter); return true; }
      if (view.dataEngine && typeof view.dataEngine.setQuery === "function") { view.dataEngine.setQuery(filter); return true; }
      if (view.graph && typeof view.graph.setQuery === "function") { view.graph.setQuery(filter); return true; }
      if (view.data && typeof view.onChangeFilter === "function") { view.data.filter = filter; view.onChangeFilter(); return true; }
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
        if (sc > bestScore) { bestScore = sc; best = inp; }
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
