---
name: get-atc-results
description: Run ABAP Test Cockpit (ATC) checks on ABAP objects to validate code quality, clean core compliance, and cloud readiness. Use when checking code quality, running ATC, validating syntax quality, finding violations, or verifying cloud readiness. Keywords - ATC check, code quality, clean core, cloud readiness, static analysis, code inspector, quality check, compliance, findings, priority errors
license: MIT
---

# Get ATC Results

Run ABAP Test Cockpit (ATC) checks on any ABAP object using the MCP `ATCbyObject` tool and interpret the findings.

## When to Use This Skill

Use this skill when you need to:
- Validate code quality after creating or changing an ABAP object
- Check clean core compliance and cloud readiness
- Identify usage of non-released APIs, obsolete syntax, or performance issues
- Verify that critical findings are resolved before transport
- Prioritize modernization work based on ATC findings

## Required Parameters

- `object_name`: Name of the ABAP object to check (e.g., `ZCL_MY_CLASS`)
- `object_type`: ADT object type (e.g., `CLAS` for classes, `PROG` for programs, `DDLS` for CDS views, `BDEF` for behavior definitions, `DCLS` for access controls)

## Output Format

The tool returns ATC findings with:
- **Priority**: 1 (very high/error), 2 (high/warning), 3 (medium/info)
- **Check title and message**: What rule was violated and why
- **Location**: Object/include and line number of each finding

## Interpreting Results

1. **Priority 1 findings** must be fixed before activation/transport — they typically block cloud readiness or indicate errors
2. **Priority 2 findings** should be fixed unless there is a documented justification
3. **Priority 3 findings** are advisory — evaluate case by case
4. For non-released API findings, use the `get-released-api` skill to find cloud-ready alternatives

## Usage Examples

**Check a class:**
```
Run ATC checks on class ZCL_ORDER_PROCESSOR
```

**Check a CDS view:**
```
Validate quality of CDS view ZI_SALESORDER
```

**Verify after changes:**
```
I just changed ZMY_REPORT - check if it passes ATC
```

## Workflow Integration

Standard quality loop:
1. `create-ai-object` or `change-ai-object` → build/modify the object
2. `activate-object` → activate and syntax check
3. **`get-atc-results`** → run quality checks
4. Fix findings via `change-ai-object`, re-activate, re-check
5. Repeat until no Priority 1/2 findings remain

## Best Practices

- Always run ATC after every create or change — never present unvalidated code as final
- Resolve all Priority 1 findings before showing results to the user as complete
- When a finding references a non-released API, chain into `get-released-api` for the modern alternative
- Explain findings in plain language, including the impact on cloud readiness
