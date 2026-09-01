---
name: get-transport-objects
description: List the objects contained in an SAP transport request (TR). Use when inspecting a transport, reviewing what a TR contains, preparing a release, or auditing changes bundled in a change request. Keywords - transport request, TR contents, transport objects, change request, CTS, release transport, task objects
license: MIT
---

# Get Transport Request Objects

List all objects contained in a transport request using the MCP `GetTRObjects` tool.

## When to Use This Skill

Use this skill when you need to:
- Review what objects are included in a transport request before release
- Audit the scope of a change request
- Cross-check that all objects of a development are captured in the TR
- Analyze the impact of an incoming transport

## Required Parameters

- `transport_number`: The transport request ID (e.g., `A4HK900123`)

## Output Format

The tool returns the list of objects in the transport:
- Object type and name (e.g., `CLAS ZCL_ORDER_PROCESSOR`, `DDLS ZI_SALESORDER`)
- The tasks belonging to the request, where available

## Usage Examples

**Inspect a transport:**
```
Show me the objects in transport request A4HK900123
```

**Pre-release review:**
```
List everything in TR D01K912345 so I can review it before release
```

## Workflow Integration

1. **`get-transport-objects`** → list TR contents
2. `get-object-info` → inspect individual objects in the TR
3. `get-atc-results` → validate quality of each object before release
4. `where-used-search` → assess impact of the transported objects

## Best Practices

- Review TR contents before requesting release — verify no unintended objects are included
- Combine with ATC checks to enforce a quality gate on everything in the transport
- Use exact transport IDs; the tool does not search by description
