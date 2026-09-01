---
name: change-ai-object
description: Update existing ABAP objects with new source code. Use when modifying, updating, fixing, or refactoring existing ABAP objects. SECURITY: Only modifies Z*-namespace objects in $TMP or Z*-custom packages; non-$TMP changes are recorded on a transport request. Keywords: modify, update, change, fix, refactor, edit code, update program, change class, fix errors, transport request
license: MIT
---

# Change AI-Managed ABAP Objects

Update existing ABAP objects with new source code using the MCP `ChangeAIObject` tool.

## When to Use This Skill

Use this skill when you need to:
- Update existing ABAP programs/reports
- Modify class implementations
- Fix syntax errors or bugs
- Refactor code for quality/performance
- Update CDS views or behavior definitions
- Change function modules or includes
- Apply ATC recommendations

## ⚠️ SECURITY RESTRICTION

**This tool only modifies Z*-namespace objects located in `$TMP` or a Z*-custom package.** Both conditions are validated before any change.

- ✅ Allowed: Z* objects in `$TMP` (local development, no transport)
- ✅ Allowed: Z* objects in Z*-custom packages (changes are recorded on a transport request)
- ❌ Blocked: SAP standard objects and objects in standard SAP/customer packages

**Why this restriction:**
- Prevents accidental modification of SAP standard or team-owned standard code
- Keeps every non-local change tracked on a transport request
- Allows safe experimentation

## Transport Handling (non-`$TMP` objects)

- If the object is already locked under an open transport (e.g. from its original creation), that transport is **auto-detected and reused** — no `transport_request` needed; passing a different one is rejected with an error naming the correct transport
- Only the **first change** of a non-`$TMP` object with no existing transport assignment needs `transport_request`: pass `"NEW"` to create a fresh transport, or an existing transport number (e.g. `"B42K902346"`)
- Omit it in that case and the tool changes nothing — it returns your open transport requests to choose from (`status: "transport_selection_required"`); re-call with the chosen `transport_request` to proceed

## Supported Object Types

Same as `create-ai-object`:
- `program`, `class`, `interface`, `include`
- `function_group`, `function`, `function_group_include`
- `data_element`, `domain`, `table`, `structure`, `table_type`
- `cds_view`, `dcl`, `behaviour_definition`
- `service_definition`, `metadata_extension`

## Required Parameters

- `object_name`: Name of existing object (Z* namespace, in `$TMP` or a Z*-custom package)
- `source_code`: Updated ABAP source (string or multi-section object)

## Optional Parameters

- `description`: Updated description (max 60 characters)
- `object_type`: Type from enum (defaults to `program`)
- `transport_request`: Transport request for non-`$TMP` objects (see Transport Handling above)
- `additional_params`: Object-specific parameters

## Source Code Formats

### Simple String
```abap
source_code: "Updated program code..."
```

### Multi-Section (Classes, Behavior Implementations)
```javascript
source_code: {
  main: "Updated class definition...",
  definitions: "Updated type definitions...",
  implementations: "Updated local handler classes...",
  testclasses: "Updated test classes...",
  macros: "Updated macros..."
}
```

## Workflow and Safety

The tool automatically:
1. ✅ Validates object exists
2. ✅ Validates Z* namespace and package (`$TMP` or Z*-custom)
3. ✅ Resolves the transport request for non-`$TMP` objects (auto-detect, reuse, or create)
4. ✅ Locks the object (prevents concurrent changes)
5. ✅ Updates source code
6. ✅ Unlocks the object
7. ✅ **Activates the object**
8. ✅ Returns activation results with errors/warnings

## Validation Before Change

**Pre-change checks:**
- Object must exist
- Object must have a Z* namespace prefix and live in `$TMP` or a Z*-custom package
- Non-`$TMP` objects must have a resolvable transport request
- Object must be unlocked or lockable
- User must have modification authority

**If validation fails:**
- Clear error message
- No changes made
- Suggestions for resolution

## Activation Results

Returns detailed activation status:
```json
{
  "success": true,
  "object_name": "ZAI_MY_PROGRAM",
  "changes_applied": true,
  "activation": {
    "success": false,
    "errors": [
      {
        "line": 12,
        "message": "Unknown variable 'lv_test'",
        "severity": "error"
      }
    ],
    "warnings": []
  }
}
```

## Usage Examples

**Fix syntax errors:**
```
Fix the syntax error on line 12 in program ZAI_SALES_REPORT
```

**Refactor code:**
```
Refactor class ZAI_CUSTOMER_HANDLER to use the builder pattern
```

**Add functionality:**
```
Add a new method 'validate_email' to class ZAI_VALIDATOR
```

**Update CDS view:**
```
Add association to I_Customer in CDS view ZAI_BOOKING
```

**Apply ATC fixes:**
```
Fix the performance warning in ZAI_DATA_PROCESSOR by removing SELECT in loop
```

## Iterative Development Pattern

Common workflow for fixing issues:

1. **Get current code:**
   ```
   Show me the code for ZAI_MY_PROGRAM
   ```

2. **Check quality:**
   ```
   Run ATC on ZAI_MY_PROGRAM
   ```

3. **Fix issues:**
   ```
   Fix the errors in ZAI_MY_PROGRAM [AI generates fix]
   ```

4. **Verify fix:**
   ```
   Run ATC again to verify fixes
   ```

## Error Handling

**Common errors and fixes:**

| Error | Cause | Fix |
|-------|-------|-----|
| Package not allowed | Object in a standard SAP/customer package | Can't modify — only `$TMP` or Z*-custom packages |
| transport_selection_required | First change of non-$TMP object without transport | Re-call with `transport_request` = "NEW" or a listed transport number |
| Wrong transport rejected | Object already locked under another open transport | Use the transport named in the error (or omit `transport_request`) |
| Object locked | Another user editing | Wait or break lock (if permitted) |
| Syntax error after change | Bad code generation | Review error, regenerate fix |
| Object not found | Wrong name | Check name with search-object |
| Activation failed | Structural issues | Review activation log |

## Tips for Effective Use

1. **Always get current code first**: Use `get-object-info` before changing
2. **Check ATC first**: Know what to fix
3. **Make incremental changes**: Small changes are easier to debug
4. **Review activation results**: Don't ignore warnings
5. **Test after changes**: Verify functionality
6. **Use version comparison**: Compare before/after

## Output Expectations

When Copilot uses this skill, expect:
- Change confirmation
- Activation status
- Line numbers for errors/warnings
- Severity levels (error/warning/info)
- Fix recommendations if activation failed
- Next steps: "Test the changes" or "Fix remaining errors"

## Integration with Other Skills

**Typical workflow:**
1. Use `get-object-info` to view current code
2. Use `change-ai-object` to apply fixes
3. Review activation results

**Quality improvement workflow:**
1. `sap-help-search` → Research best practices
2. `change-ai-object` → Apply improvements
3. Review activation results to verify improvements

## Multi-Section Updates

**For classes with local handler classes:**
```javascript
{
  main: "CLASS zcl_travel_handler DEFINITION... ENDCLASS. CLASS zcl_travel_handler IMPLEMENTATION... ENDCLASS.",
  implementations: "CLASS lhc_travel DEFINITION... ENDCLASS. CLASS lhc_travel IMPLEMENTATION... ENDCLASS."
}
```

**Benefits:**
- RAP behavior implementations with LHC_* classes
- Separation of test classes
- Cleaner code organization
- Easier maintenance

## Refactoring Patterns

### Performance Refactoring
```
Before: SELECT in loop
Fix: Single SELECT with FOR ALL ENTRIES
Tool: change-ai-object applies optimization
```

### Security Refactoring
```
Before: Concatenated SQL
Fix: Parameters and escaping
Tool: change-ai-object applies security fix
```

### Cloud Readiness
```
Before: Non-released API
Fix: Released API alternative
Tool: change-ai-object migrates to new API
```

## Safety Features

**Built-in safeguards:**
- ✅ Z*-namespace + package validation (SAP standard code can't be modified)
- ✅ Transport enforcement for every non-`$TMP` change
- ✅ Automatic locking (prevents conflicts)
- ✅ Activation with syntax check
- ✅ Rollback on activation failure
- ✅ Detailed error reporting

## When NOT to Use

❌ Don't use this skill when:
- Object is SAP standard or in a standard SAP/customer package (not modifiable)
- Only viewing code (use `get-object-info`)
- Creating new object (use `create-ai-object`)
- Just checking activation (use `activate-object`)

## Promoting a `$TMP` Prototype to a Package

Objects cannot be moved between packages by this tool. To promote a `$TMP` prototype:
1. Test thoroughly in `$TMP`
2. Re-create the object in the target Z*-custom package with `create-ai-object` (`package_name` + `transport_request`)
3. Delete the `$TMP` version

## Best Practices

1. **Version control mindset**: Treat each change as a commit
2. **Atomic changes**: One logical change at a time
3. **Test immediately**: Don't accumulate untested changes
4. **Document rationale**: Update description if behavior changes
5. **Review activation log**: Learn from errors
6. **Keep backups**: Copy code before major refactoring
