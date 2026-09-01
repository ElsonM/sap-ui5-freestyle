---
name: get-released-api
description: Find cloud-ready released API alternatives for legacy or non-released ABAP objects (BAPIs, function modules, classes, tables). Use when replacing deprecated APIs, checking C1 release contracts, finding successors, or making code cloud-compatible. Keywords - released API, C1 contract, cloud ready alternative, API successor, deprecated BAPI, non-released, ABAP Cloud API, replacement API
license: MIT
---

# Get Released API Alternatives

Find released, cloud-ready API alternatives for legacy ABAP objects using the MCP `GetReleasedAPI` tool.

## When to Use This Skill

Use this skill when you need to:
- Replace a non-released function module, BAPI, or class flagged by ATC
- Verify whether an object has a C1 release contract before using it
- Find the official successor for a deprecated API
- Plan modernization of legacy code toward ABAP Cloud

## Required Parameters

- `object_name`: Name of the legacy/classic object (e.g., `BAPI_PO_CREATE1`, `MARA`)

## Output Format

The tool returns:
- Release status of the queried object (released / not released / deprecated)
- Recommended released successor objects, where available
- Release contract information (e.g., C1 — use in cloud development)

## Usage Examples

**Find a BAPI replacement:**
```
What is the released alternative to BAPI_SALESORDER_CREATEFROMDAT2?
```

**Check release status:**
```
Is CL_GUI_FRONTEND_SERVICES released for cloud development?
```

**Modernization research:**
```
Find cloud-ready alternatives for the function modules used in ZOLD_REPORT
```

## Workflow Integration

Modernization loop:
1. `get-atc-results` → identify non-released API usage
2. **`get-released-api`** → find the released successor for each finding
3. `sap-help-search` → research how to use the new API
4. `change-ai-object` → refactor the code
5. `get-atc-results` → verify compliance

## Best Practices

- Verify the release contract of every function module, BAPI, or class BEFORE referencing it in new code
- When no released successor exists, search SAP Help and SAP Community for the recommended pattern (often a CDS view or a new API in a different shape)
- Always confirm alternatives on the connected system — successor availability differs by release
