#!/usr/bin/env node
/*
 * check-contract.mjs - the method contract of AGENTS.md, checked on the source
 * of every business class (src/<module>/, not the abap-util copies in src/00).
 * No system and no BAPI is needed: it reads declarations and method bodies.
 *
 *   node .github/scripts/check-contract.mjs
 *
 * Every public method
 *   1. is a CLASS-METHODS (static, no state)
 *   2. exports ev_is_error TYPE abap_bool and et_bapiret TYPE bapirettab
 *   3. takes iv_commit TYPE abap_bool DEFAULT abap_false, or none at all
 *   4. sets the error flag through bapi_finish( ) - its last statement is
 *      bapi_finish( ) or a call that hands ev_is_error and et_bapiret to
 *      another method of the class - and never assigns ev_is_error directly
 *   5. passes its iv_commit on (to bapi_finish or to the method it delegates to)
 * Every method
 *   6. raises no exception (RAISE, MESSAGE ... RAISING)
 *   7. calls a function module inside a TRY that catches cx_root (a private
 *      helper may leave the TRY to its callers - then every call of it is
 *      inside one), and names error_message wherever it lists EXCEPTIONS
 *   8. commits and rolls back through bapi_finish( ) only
 *
 * EXEMPT names the public methods that are deliberately outside the contract.
 */
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const SRC = join(ROOT, "src");
const EXEMPT = {
  "zabaputil_cl_bus_ca_status.check_is_set":
    "a predicate: one SELECT, a boolean back, no message to return",
};
const errors = [];
let classes = 0;
let methods = 0;

// code without comments, literals blanked, lowercased, one statement per entry
function statements(text) {
  let out = "";
  for (const line of text.split("\n")) {
    if (line.startsWith("*")) continue;
    let i = 0;
    while (i < line.length) {
      const c = line[i];
      if (c === '"') break;
      if (c === "'" || c === "`" || c === "|") {
        let j = i + 1;
        while (j < line.length && line[j] !== c) j += line[j] === "\\" ? 2 : 1;
        out += c === "|" ? "``" : `${c}${line.slice(i + 1, j).toLowerCase()}${c}`;
        i = j + 1;
        continue;
      }
      out += c.toLowerCase();
      i++;
    }
    out += " ";
  }
  return out
    .split(".")
    .map((s) => s.replace(/\s+/g, " ").trim())
    .filter(Boolean);
}

for (const pkg of readdirSync(SRC)) {
  const dir = join(SRC, pkg);
  if (pkg === "00" || !statSync(dir).isDirectory()) continue;
  for (const file of readdirSync(dir)) {
    if (!/\.clas\.abap$/.test(file)) continue;
    classes++;
    const rel = relative(ROOT, join(dir, file));
    const text = readFileSync(join(dir, file), "utf8").replace(/\r/g, "");
    const impl = text.search(/^CLASS\s+\S+\s+IMPLEMENTATION/im);
    const def = text.slice(0, impl);
    const pub = def.slice(
      def.search(/PUBLIC SECTION\./i),
      def.search(/PROTECTED SECTION\./i),
    );
    const bad = (m, msg) => errors.push(`${rel}: ${m}( ) - ${msg}`);

    const bodies = new Map();
    for (const m of text
      .slice(impl)
      .matchAll(/^\s*METHOD\s+([\w~]+)[^.\n]*\.\n([\s\S]*?)^\s*ENDMETHOD\./gim))
      bodies.set(m[1].toLowerCase(), statements(m[2]));

    const publics = new Map();
    for (const st of statements(pub)) {
      const m = st.match(/^(class-methods|methods) (\w+)/);
      if (m) publics.set(m[2], { kind: m[1], decl: st });
    }

    for (const [name, { kind, decl }] of publics) {
      methods++;
      if (EXEMPT[`${file.split(".")[0]}.${name}`]) continue;
      const body = bodies.get(name) ?? [];
      const all = body.join(" . ");
      if (kind !== "class-methods") bad(name, "is not a static method");
      if (!/ev_is_error type abap_bool/.test(decl))
        bad(name, "does not export ev_is_error TYPE abap_bool");
      if (!/et_bapiret type bapirettab/.test(decl))
        bad(name, "does not export et_bapiret TYPE bapirettab");
      const commit = /\biv_commit\b/.test(decl);
      if (commit && !/iv_commit type abap_bool default abap_false/.test(decl))
        bad(name, "iv_commit is not TYPE abap_bool DEFAULT abap_false");
      const finishes = /=>bapi_finish\(/.test(all);
      const delegates =
        /ev_is_error ?= ?ev_is_error/.test(all) &&
        /et_bapiret ?= ?et_bapiret/.test(all);
      // the last statement that is not the end of a block
      const last =
        body.findLast((st) => !/^(endif|endcase|endtry|endloop)$/.test(st)) ?? "";
      if (!finishes && !delegates)
        bad(name, "neither ends with bapi_finish( ) nor hands ev_is_error and et_bapiret to a method that does");
      else if (
        !/=>bapi_finish\(/.test(last) &&
        !/ev_is_error ?= ?ev_is_error/.test(last)
      )
        bad(name, "the last statement is neither bapi_finish( ) nor the call it delegates to");
      if (/(^| )ev_is_error ?= ?(?!ev_is_error)/.test(all.replace(/ev_is_error ?= ?ev_is_error/g, "")))
        bad(name, "assigns ev_is_error itself - only bapi_finish( ) sets it");
      if (commit && !/iv_commit ?= ?iv_commit/.test(all))
        bad(name, "does not pass iv_commit on");
    }

    // per method: is statement i inside a TRY that catches cx_root
    const guardedAt = new Map();
    for (const [name, body] of bodies) {
      const open = [];
      guardedAt.set(
        name,
        body.map((st, i) => {
          if (st === "try") {
            let d = 0;
            let ok = false;
            for (let j = i + 1; j < body.length; j++) {
              if (body[j] === "try") d++;
              else if (body[j] === "endtry") {
                if (d === 0) break;
                d--;
              } else if (d === 0 && /^catch .*\bcx_root\b/.test(body[j])) ok = true;
            }
            open.push(ok);
          } else if (st === "endtry") open.pop();
          return open.includes(true);
        }),
      );
    }
    const callsGuarded = (helper) => {
      let calls = 0;
      for (const [name, body] of bodies)
        for (let i = 0; i < body.length; i++)
          if (new RegExp(`(^|[ (=])${helper}\\(`).test(body[i])) {
            calls++;
            if (!guardedAt.get(name)[i]) return false;
          }
      return calls > 0;
    };

    for (const [name, body] of bodies) {
      body.forEach((st, i) => {
        if (/^raise /.test(st) || /^message .* raising /.test(st))
          bad(name, `raises: ${st.slice(0, 60)}`);
        if (/^call function /.test(st)) {
          const fm = st.match(/^call function (\S+)/)[1];
          if (/ exceptions /.test(st) && !/exceptions .*\berror_message ?=/.test(st))
            bad(name, `CALL FUNCTION ${fm} lists EXCEPTIONS without error_message`);
          if (!guardedAt.get(name)[i] && (publics.has(name) || !callsGuarded(name)))
            bad(name, `CALL FUNCTION ${fm} outside TRY ... CATCH cx_root`);
        }
        if (/^(commit work|rollback work)\b/.test(st) || /'bapi_transaction_(commit|rollback)'/.test(st))
          bad(name, `commits or rolls back itself: ${st.slice(0, 60)}`);
      });
    }
  }
}

for (const e of errors) console.log(e);
console.log(
  `check-contract: ${classes} classes, ${methods} public methods, ${errors.length} finding(s)`,
);
process.exit(errors.length ? 1 : 0);
