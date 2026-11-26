[![abaplint](https://github.com/abap-util/business-api/actions/workflows/abaplint.yaml/badge.svg)](https://github.com/abap-util/business-api/actions/workflows/abaplint.yaml)

# business-api

Simple, class-based access to the SAP logistics BAPIs - one class per business
object, every action a static method, one error and commit contract for all.

#### Compatibility
* S/4HANA on-premise and private cloud
* ECC 6.0 from NetWeaver 7.40 SP08
* Standard ABAP only - the wrapped BAPIs are not released for ABAP Cloud

#### Installation
Install via [abapGit](https://abapgit.org).

#### One contract for every method
```abap
zabaputil_cl_bus_mm_goodsmvt=>transfer_storage_location(
  EXPORTING iv_matnr      = lv_matnr
            iv_werks      = '1000'
            iv_lgort_from = '0001'
            iv_lgort_to   = '0002'
            iv_menge      = 5
            iv_meins      = 'PC'
            iv_commit     = abap_true      " commit on success, rollback on error
  IMPORTING ev_mblnr      = DATA(lv_mblnr)
            ev_is_error   = DATA(lv_error) " abap_true if a message of type E/A/X came back
            et_bapiret    = DATA(lt_msg) ). " all messages as BAPIRET2
```
* `iv_commit` - default `abap_false`: the caller owns the LUW, several calls can
  be committed together.
* No exception leaves a method; runtime errors and classic exceptions come back
  as messages in `et_bapiret`.
* Read methods have no `iv_commit`.

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

#### Core
`zabaputil_cl_bus` holds what every method uses: `finish( )` (error flag,
commit or rollback), message helpers for `sy-msg`, exceptions and any message
table, `set_material( )` (18 or 40 characters), `refresh_buffers( )` and
`call_function( )` for dynamic calls.

The message handling runs on renamed copies of [abap-util](https://github.com/abap-util/abap-util)
(`zabaputil_cl_bus_context`, `zabaputil_cl_bus_msg`, `zabaputil_cx_bus_error`) -
copied, not installed, as abap-util is meant to be consumed.
