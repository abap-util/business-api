# AGENTS.md — business-api

The single instruction file of this repository (`CLAUDE.md` points here).

## What this is

A thin, uniform layer over the SAP standard BAPIs and function modules of the
logistics modules: one class per business object, every action of that object
as a static method, one error and commit contract for all of them.

**Status: experimental.** Nothing here has been activated or run on a system
yet; the README says so at the top. Keep that notice until a system has
confirmed the classes, and remove it per module only on such evidence.

**Target:** Standard ABAP — ECC 6.0 (EHP7+, 7.40 SP08) and S/4HANA on-premise /
private cloud. The wrapped BAPIs are not released for ABAP Cloud.
**Language:** English — code, comments, commit messages, documentation.

## Layout

```
src/                ZABAPUTIL_BUS        root package
├─ 00/              ZABAPUTIL_BUS_00     the renamed copies of abap-util (zabaputil_c?_bus_util_*, see below):
│                                        messages, commit, buffers - the bapi_* methods of the context class
├─ sd/              ZABAPUTIL_BUS_SD     sales order, delivery, shipment, HU, serial numbers
├─ mm/              ZABAPUTIL_BUS_MM     material, goods movement, inventory, PO, requisition
├─ wm/              ZABAPUTIL_BUS_WM     LE-WM: transfer order, transfer requirement, storage unit
├─ ewm/             ZABAPUTIL_BUS_EWM    warehouse task, warehouse order, HU, stock, storage bin, physical inventory, resource
├─ pp/              ZABAPUTIL_BUS_PP     production order, confirmation
├─ pm/              ZABAPUTIL_BUS_PM     notification, measurement document, equipment
├─ qm/              ZABAPUTIL_BUS_QM     quality notification, inspection lot
└─ ca/              ZABAPUTIL_BUS_CA     object status, classification
```

Class names: `zabaputil_cl_bus_<module>_<object>` — at most 30 characters, so
the object names are short (`sd_hu`, `mm_goodsmvt`, `wm_to`).

## Vendored from abap-util — copy, don't depend

`src/00` carries nothing but renamed copies of [abap-util](https://github.com/abap-util/abap-util)
classes, the way every abap-util consumer does: no dependency to install, no
name clash with an installed abap-util.

**The rename is mechanical:** `bus_` is inserted after `zabaputil_cl_` /
`zabaputil_cx_`, the rest of the name stays - so every copy names its master,
and `util` (no module) keeps the copies apart from the business classes.

| Copy here | Master in abap-util | Scope |
|---|---|---|
| `zabaputil_cl_bus_util_context` | `zabaputil_cl_util_context` | trimmed to the `bapi_*` methods, `conv_alpha_in` and what the exception calls, with their helpers |
| `zabaputil_cx_bus_util_error` | `zabaputil_cx_util_error` | as is |

**`.github/abap-util.json` is the record of the copies:** the abap-util commit
they were taken from, the rename back to the master names, and per copy the
master file and whether it is trimmed. abap-util's
`.github/scripts/sync-check.mjs` reads it and compares every method body and
declaration with the master; the job `sync` of the workflow `test` runs it at
that commit on every pull request and fails on a difference. So a change made
in a copy here is either synced back to abap-util (then set `commit` to the
abap-util commit that has it) or named in the manifest - under `settled`
(differs on purpose) or `own` (no master), with the reason. The same job
reports the differences to abap-util's `main`, without failing: that is what a
refresh would bring. Locally:
`node ../abap-util/.github/scripts/sync-check.mjs --consumer .`

The `bapi_*` methods turn abap-util's message
model (`ty_t_msg`) into rows of `BAPIRET2` - of any table with its
components, filled by name. Do not edit the copies for style: a fix goes
into abap-util and is copied back, or is made here and synced back. To
refresh a copy, take the master, apply the rename (back: `bus_util_` →
`util_`), and trim the context class to the closure of the methods this
repository calls (`bapi_*`, `conv_alpha_in`) and the exception calls
(`uuid_get_c32`, `rtti_check_printable`, `rtti_get_classname_by_ref`,
`error_get_attributes`, `error_get_source_position`): every method, type and
constant they reach, transitively. The copy's test class is `ltcl_bapi_ops`
of the master's, renamed - refresh it together with the copy.
A new copy must stay within 30 characters after the rename.

## The method contract — every method keeps it

```abap
CLASS-METHODS <action>
  IMPORTING
    <api-specific input>
    iv_commit   TYPE abap_bool DEFAULT abap_false   " write methods only
  EXPORTING
    <api-specific output>
    ev_is_error TYPE abap_bool
    et_bapiret  TYPE bapirettab.
```

1. **Static methods, no state.** `zabaputil_cl_bus_sd_delivery=>post_goods_issue( … )`.
2. **`et_bapiret` holds every message** — of the BAPI, of a classic exception
   (from `sy-msg`), of a runtime error (`cx_root`), and own checks. It is
   cleared at the start of the method.
3. **`ev_is_error` is set by `zabaputil_cl_bus_util_context=>bapi_finish( )` only** — abap_true
   when `et_bapiret` holds a message of type E, A or X.
4. **No exception leaves a method.** Every call sits in `TRY … CATCH cx_root`;
   a classic `CALL FUNCTION` has `EXCEPTIONS error_message = … OTHERS = …`.
5. **`iv_commit`:** abap_true commits (`BAPI_TRANSACTION_COMMIT`, wait) on
   success and rolls back on error, via `bapi_finish( )`. abap_false (default): the
   caller owns the LUW, the method neither commits nor rolls back. Function
   modules with an own commit flag (`i_commit_work`, `iv_commit_work`) are
   always called without it. A module that commits by itself is named in the
   method's ABAP Doc.
6. **Read methods** have no `iv_commit` and end with `bapi_finish( )` without it.
7. **Every method ends with `zabaputil_cl_bus_util_context=>bapi_finish( )`.**

8. **The one exception** is `zabaputil_cl_bus_ca_status=>check_is_set( )`: a
   predicate with one SELECT and a boolean back, no message to return. It is
   named in `EXEMPT` of `.github/scripts/check-contract.mjs`; a new exception
   to the contract goes there with its reason, or it fails the check.

`npm run contract` checks points 1 to 7 on the source: the signature
(`ev_is_error`, `et_bapiret`, `iv_commit`), that the last statement is
`bapi_finish( )` or the call a convenience method delegates to, that
`iv_commit` is passed on, that nothing raises, that every `CALL FUNCTION` is
inside a `TRY … CATCH cx_root` (a private helper may leave that to its
callers) and names `error_message` where it lists `EXCEPTIONS`, and that
nothing commits or rolls back on its own.

## Rules

- **Nothing customer-specific.** No Z fields, no customizing values, no
  organizational units in the code — everything is a parameter. Sources are the
  SAP standard interfaces and their documentation only.
- **Everything is neutral — no trace of a customer, a project or a system.**
  This repository is public. Nothing in it names or hints at where a
  requirement came from: no customer, partner or project name, no customer or
  partner namespace (`/XYZ/`), no system id, client, host or URL, no user name,
  no real warehouse, plant, material or document number, no ticket or transport
  number. That holds for code, comments, ABAP Doc, tests and their data, the
  README, this file, commit messages, branch names, pull requests and issues.
  A method is described by the SAP standard function it wraps, never by the
  process or the installation that needed it. Code from a customer system is
  never copied in: a method is written here, against the standard interface.
  Examples use the neutral values SAP documentation uses (`1000`, `0001`).
- **A parameter is named after the DDIC field it carries** (`iv_vbeln`,
  `iv_menge` with `iv_meins`, `iv_budat`), and a quantity comes with its unit.
  Published signatures only grow (a new optional parameter, never a rename or
  a removal), so these older names stay: `iv_quantity`/`iv_unit` in `sd_hu`
  (VEMNG/VEMEH) and `ewm_wt=>create_product` (generic, as EWM types are not
  referenced statically), `iv_quantity` with the optional `iv_vrkme` in
  `sd_order=>change_quantity`, `iv_lfimg`/`iv_vrkme` in
  `sd_delivery=>change_quantity`, and `iv_date` for a count, measurement or
  key date where the BAPI has no posting date (`mm_inventory=>count`, `pm_*`).
- **Complex BAPI input stays a BAPI structure** (`is_header TYPE bapisdhd1`);
  convenience methods with simple parameters are added for the common cases.
- **Material numbers go through `zabaputil_cl_bus_util_context=>bapi_set_material( )`**, which
  fills `MATERIAL_LONG` on S/4HANA and `MATERIAL` elsewhere.
- **Reset the buffers** (`zabaputil_cl_bus_util_context=>bapi_refresh_buffers( )`) before a
  write that reads delivery, HU or serial number data.
- **EWM:** no static reference to a `/SCWM/` object (types, tables, function
  modules). Create the data dynamically and call through
  `zabaputil_cl_bus_util_context=>bapi_call_function( )`, so the classes activate in systems
  without EWM.
- **Only DDIC types that exist in every ERP system** in signatures (SD, MM,
  LE-WM, PP, PM, QM, CA are there in ECC and S/4HANA).
- abapGit format: XML with UTF-8 BOM, LF, a final newline, no tabs, no trailing
  blanks, lines up to 255 characters.

## Verify

```bash
npm ci
npm run lint       # abaplint at 7.40 SP08
npm run downport   # 7.02: abaplint --fix + lint at v702 (changes src/ - do not commit that)
npm run rename     # every class renamed to the 11-character placeholder prefix
npm run contract   # the method contract above, on every business class
npm run transpile  # package 00 to JavaScript
npm run unit       # its unit tests (ltcl_bapi_ops) in Node.js
npm test           # lint, rename, contract, transpile, unit
```

CI: `abaplint` (lint), `test_rename`, and `test` with the jobs `contract`,
`unit` and `sync` - on every pull request and every push to `main`. Actions
are pinned to a commit sha; `bump-deps` moves the pins and the npm
dependencies once a month in one pull request.

SAP standard types are void for abaplint (no dependency has them), so it checks
the syntax of the own code, not the BAPI field names. **Activation and the BAPI
calls are only verified on a system** — the `bapi_*` methods are unit-tested
here and in abap-util (`ltcl_bapi_ops`); the module classes have the contract
check, but no unit tests: they need the BAPIs.

## Downport and renaming

- **`auto_downport`** downports every push to `main` and force-pushes the result
  to the branch `702`. The downport cannot infer a void type: declare a variable
  with a BAPI structure type explicitly (`DATA ls_item TYPE bapi2017_gm_item_create.`)
  instead of `DATA(ls_item) = …`, and build a table of BAPI rows into a typed
  local table rather than `VALUE #( … )` in a method call.
- **`build_rename`** (run by hand) renames every class to a chosen name and pushes
  `rename_<name>`. Object names stay at 29 characters or less, so the longest
  prefix (10 characters plus `_`) still fits into 30. No object name may appear
  in a string literal - the rename only follows references. `test_rename` runs
  the rename on every pull request.
