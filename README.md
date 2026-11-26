[![abaplint](https://github.com/abap-util/business-api/actions/workflows/abaplint.yaml/badge.svg)](https://github.com/abap-util/business-api/actions/workflows/abaplint.yaml)
[![auto_downport](https://github.com/abap-util/business-api/actions/workflows/auto_downport.yaml/badge.svg)](https://github.com/abap-util/business-api/actions/workflows/auto_downport.yaml)

# business-api
Class-based access to the SAP logistics BAPIs for Standard ABAP

#### Key Features
* One class per business object - sales order, delivery, handling unit, goods movement, transfer order, production order, notification, ...
* Every action a static method with the same contract: `iv_commit` in, `ev_is_error` and `et_bapiret` out
* No exception leaves a method - classic exceptions and runtime errors come back as `BAPIRET2` messages
* SD, MM, LE-WM, EWM, PP, PM, QM and CA in one repository; the EWM classes reach `/SCWM/` dynamically, so everything activates in systems without EWM
* 18 and 40 character material numbers on ECC and S/4HANA alike

#### Compatibility
* S/4HANA on-premise and private cloud
* ECC 6.0 - from NetWeaver 7.40 SP08 on `main`, from 7.02 on the branch `702`
* Standard ABAP only - the wrapped BAPIs are not released for ABAP Cloud

#### Installation
Install via [abapGit](https://abapgit.org) - pick the branch that fits the system:

| Branch | For |
|---|---|
| `main` | NetWeaver 7.40 SP08 and higher, S/4HANA |
| `702` | NetWeaver 7.02 to 7.31 - downported from `main` on every push |
| `rename_<name>` | a second installation under another name, built on request (see below) |

#### Usage
```abap
zabaputil_cl_bus_mm_goodsmvt=>transfer_storage_location(
  EXPORTING iv_matnr      = lv_matnr
            iv_werks      = '1000'
            iv_lgort_from = '0001'
            iv_lgort_to   = '0002'
            iv_menge      = 5
            iv_meins      = 'PC'
            iv_commit     = abap_true          " commit on success, rollback on error
  IMPORTING ev_mblnr      = DATA(lv_mblnr)
            ev_is_error   = DATA(lv_is_error)  " abap_true if a message of type E, A or X came back
            et_bapiret    = DATA(lt_bapiret) ). " all messages as BAPIRET2
```
* `iv_commit` defaults to `abap_false`: the caller owns the LUW, and several calls can be committed together.
* Read methods have no `iv_commit`.
* Complex input stays a BAPI structure (`is_header TYPE bapisdhd1`); convenience methods with simple parameters cover the common cases.

#### Objects

| Package | Class | Methods |
|---|---|---|
| SD | `zabaputil_cl_bus_sd_order` | `create`, `read`, `change`, `change_quantity`, `delete_item`, `delete` |
| SD | `zabaputil_cl_bus_sd_delivery` | `create_from_order`, `read`, `change_quantity`, `post_goods_issue`, `reverse_goods_issue`, `delete_item`, `delete` |
| SD | `zabaputil_cl_bus_sd_shipment` | `create`, `read`, `set_status`, `add_deliveries`, `remove_deliveries`, `change_carrier` |
| SD | `zabaputil_cl_bus_sd_hu` | `create`, `read`, `pack_material`, `pack_hu`, `unpack_material`, `unpack_hu`, `delete` |
| SD | `zabaputil_cl_bus_sd_serial` | `read`, `read_by_delivery` |
| MM | `zabaputil_cl_bus_mm_material` | `read`, `change`, `change_weight`, `change_mrp_controller`, `set_deletion_flag` |
| MM | `zabaputil_cl_bus_mm_goodsmvt` | `create`, `transfer_storage_location`, `transfer_plant`, `transfer_stock_type`, `goods_issue_order`, `goods_issue_reservation`, `goods_receipt_initial`, `cancel` |
| MM | `zabaputil_cl_bus_mm_inventory` | `create`, `count`, `post_differences` |
| MM | `zabaputil_cl_bus_mm_po` | `read`, `change`, `set_deletion_flag` |
| MM | `zabaputil_cl_bus_mm_preq` | `release`, `reset_release` |
| WM | `zabaputil_cl_bus_wm_to` | `create`, `create_from_delivery`, `create_from_requirement`, `read`, `confirm`, `cancel` |
| WM | `zabaputil_cl_bus_wm_tr` | `create`, `read`, `cancel` |
| WM | `zabaputil_cl_bus_wm_su` | `read`, `move` |
| EWM | `zabaputil_cl_bus_ewm_wt` | `create_hu`, `read`, `confirm`, `cancel` |
| EWM | `zabaputil_cl_bus_ewm_hu` | `read`, `read_by_bin` |
| EWM | `zabaputil_cl_bus_ewm_stock` | `read_bin`, `read_by_bin` |
| EWM | `zabaputil_cl_bus_ewm_resource` | `read` |
| PP | `zabaputil_cl_bus_pp_order` | `read`, `release`, `check_availability`, `complete_technically` |
| PP | `zabaputil_cl_bus_pp_confirm` | `read_proposal`, `create`, `cancel` |
| PM | `zabaputil_cl_bus_pm_notif` | `create`, `read`, `change`, `complete_task`, `close` |
| PM | `zabaputil_cl_bus_pm_measure` | `create`, `read_last` |
| PM | `zabaputil_cl_bus_pm_equipment` | `create`, `read`, `change` |
| QM | `zabaputil_cl_bus_qm_notif` | `create`, `read`, `add_defects` |
| QM | `zabaputil_cl_bus_qm_insp_lot` | `read`, `set_usage_decision` |
| CA | `zabaputil_cl_bus_ca_status` | `read`, `check_is_set`, `set_user_status` |
| CA | `zabaputil_cl_bus_ca_classif` | `read`, `change` |

The EWM classes reach every `/SCWM/` object dynamically, so the whole
repository activates in systems without EWM.

#### Package 00
`zabaputil_cl_bus` holds what every method uses: `finish( )` (error flag, commit or rollback), message helpers for `sy-msg`, exceptions and any message table, `set_material( )` (18 or 40 characters), `refresh_buffers( )` and `call_function( )` for dynamic calls.

The message handling runs on renamed copies of [abap-util](https://github.com/abap-util/abap-util) in the same package - copied, not installed, as abap-util is meant to be consumed:

| Copy | Master in abap-util |
|---|---|
| `zabaputil_cl_bus_util_context` | `zabaputil_cl_util_context` (trimmed) |
| `zabaputil_cl_bus_util_msg` | `zabaputil_cl_util_msg` |
| `zabaputil_cx_bus_util_error` | `zabaputil_cx_util_error` |

#### Renaming
To install business-api a second time next to another copy, run the workflow [build_rename](https://github.com/abap-util/business-api/actions/workflows/build_rename.yaml) with a new name - a customer name such as `ZMYAPI` or a registered namespace such as `/MYNS/`. It renames every class (`zabaputil_cl_bus_sd_hu` becomes `zmyapi_cl_bus_sd_hu`) and pushes the result to the branch `rename_<name>`, ready for abapGit.

#### Development
```bash
npm ci
npm run lint       # abaplint at 7.40 SP08
npm run downport   # rewrite src/ to 7.02 syntax and lint it at v702 - what auto_downport pushes to 702
npm run rename     # rename every class to the longest prefix build_rename allows
```
The conventions every change keeps are in [AGENTS.md](AGENTS.md). Nothing here has been verified on a system yet - the BAPI field and parameter names are only checked when a system activates the classes.
