---
name: create-ai-object
description: Create new ABAP objects (programs, classes, CDS views, tables, structures, data elements, domains, etc.) with AI-generated code. Use when building, generating, or creating new ABAP development objects. Supports custom Z-prefixes or defaults to ZAI_ prefix. Creates in $TMP by default, or in any existing Z*-custom package with a transport request. Keywords: create, build, generate, new program, new class, new CDS, new object, create report, generate class, create table, create structure, create data element, create domain, transport request
license: MIT
---

# Create AI-Managed ABAP Objects

Create new ABAP objects with AI-generated source code using the MCP `CreateAIObject` tool.

## When to Use This Skill

Use this skill when you need to:
- Create new ABAP programs/reports
- Generate new classes or interfaces (including ABAP Unit test classes via the `testclasses` section)
- Build new CDS views, behavior definitions, behavior implementations, service definitions
- Create function groups and function modules
- Generate data elements, domains, tables, structures, and table types
- Create metadata extensions (DDLX) for Fiori UI

## Supported Object Types

| Type | Description | Source Format |
|------|-------------|---------------|
| `program` | ABAP reports/programs | Plain ABAP text |
| `class` | Global classes | Plain ABAP text or multi-section (main, definitions, implementations, testclasses, macros) |
| `interface` | Global interfaces | Plain ABAP text |
| `include` | Include programs | Plain ABAP text (no REPORT/PROGRAM line) |
| `function_group` | Function groups | Plain ABAP text (minimal shell) |
| `function` | Function modules | Plain ABAP text (requires `function_group`) |
| `function_group_include` | Function group includes | Plain ABAP text (requires `function_group`) |
| `data_element` | Data elements | Full XML (`blue:wbobj`) |
| `domain` | Domains (value set: type, length, fixed values) | Full XML (`doma:domain`) or auto-built from `additional_params` |
| `table` | Database tables | DDL definition |
| `structure` | ABAP structures | DDL definition (`define structure ...`) |
| `table_type` | Table types (row type + access type) | Full XML (`ttyp:tableType`) or auto-built from `additional_params` |
| `cds_view` | CDS views | DDL with associations |
| `dcl` | Access Control (DCLS) | DCL syntax |
| `behaviour_definition` | RAP behavior (BDEF) | BDEF syntax |
| `service_definition` | Service definitions | Service exposure syntax |
| `metadata_extension` | Metadata extensions (DDLX) | @UI annotations |

**Domain vs Data Element**: Use `domain` to define the VALUE SET (allowed type, length, fixed values, conversion exit — shared by many data elements). Use `data_element` to define the SEMANTIC MEANING (field labels, documentation — references a domain for its technical type).

## Required Parameters

- `object_name`: Name of object to create
- `source_code`: Complete ABAP source (string or multi-section object)

## Optional Parameters

- `description`: Object description (max 60 characters, defaults to "AI-Generated {Type}")
- `object_type`: Type from enum above (defaults to `program`)
- `package_name`: Target package (defaults to `$TMP` — see Package and Transport below)
- `transport_request`: Transport request for non-`$TMP` packages (see Package and Transport below)
- `additional_params`: Object-specific parameters (see below)

## Naming Conventions

### Custom Z-Prefixes (Preserved)
If you provide a custom Z-prefix, it's preserved as-is:
- `ZP_SALES_REPORT` → stays `ZP_SALES_REPORT`
- `ZF_HELPER` → stays `ZF_HELPER`
- `ZC_MY_VIEW` → stays `ZC_MY_VIEW`

### Default ZAI_ Prefix
Without a custom Z-prefix, auto-adds `ZAI_`:
- `SALES_REPORT` → becomes `ZAI_SALES_REPORT`
- `MY_CLASS` → becomes `ZAI_MY_CLASS`

### Length Limits
⚠️ **CRITICAL**: ABAP name length limits apply per object type, INCLUDING the prefix:
- Classes, interfaces, CDS views: max 30 characters
- Programs, includes: max 40 characters
- Function groups, function modules: max 30 characters
- Method names: max 30 characters
- Descriptions: max 60 characters

## Source Code Formats

### Simple String (Most Objects)
```abap
"Program, Interface, Include, CDS View, etc.
source_code: "REPORT zmy_test. WRITE: 'Hello'."
```

### Multi-Section Object (Classes, Behavior Implementations)
```javascript
source_code: {
  main: "CLASS zcl_my_class DEFINITION PUBLIC...",
  definitions: "Type definitions and constants",
  implementations: "Local helper classes - LHC_*, LSC_*",
  testclasses: "Unit test classes",
  macros: "Macro definitions"
}
```

**Multi-section enables:**
- RAP behavior implementation classes with local handler classes (LHC_*) and saver classes (LSC_*)
- Separation of concerns in complex classes
- **ABAP Unit test classes** in the dedicated `testclasses` section
- Reusable definitions and macros

## Additional Parameters by Type

### Function Modules
**Required:**
- `function_group`: Parent function group name

### Data Elements
**Optional:**
- `typeKind`: `predefinedAbapType` or `domain`
- `dataType`: CHAR, NUMC, INT4, etc.
- `dataTypeLength`: Default 50
- `dataTypeDecimals`: Default 0
- `shortLabel`: Short field label
- `mediumLabel`: Medium field label
- `longLabel`: Long field label
- `headingLabel`: Column heading

### Domains
Pass the full `doma:domain` XML as `source_code`, OR pass a placeholder string plus `additional_params`:
- `datatype`: CHAR, NUMC, INT4, DATS, TIMS, DEC, CURR, QUAN, CLNT, LANG, RAW, FLTP (default CHAR)
- `length` (default 10), `decimals` (default 0)
- `conversionExit`: e.g. "ALPHA"
- `signExists`, `lowercase`: booleans
- `valueTableRef`: check-table name
- `fixValues`: array of `{low, high?, text?}` for fixed-value lists

### Table Types
Pass the full `ttyp:tableType` XML as `source_code`, OR pass a placeholder string plus `additional_params`:
- `rowTypeKind`: `dictionaryType` (default), `predefinedAbapType`, `refToDictionaryType`, `refToClassOrInterfaceType`, `rangeTypeOnPredefinedType`, `rangeTypeOnDataelement`
- `rowTypeName`: referenced structure/table/data element (required for `dictionaryType`)
- `accessType`: `standard` (default), `sorted`, `hashed`, `index`
- `keyDefinition`, `keyKind`, `secondaryKeysAllowed`, `initialRowCount`

## Package and Transport

**Default: `$TMP` (local development package)**
- No transport request needed
- Ideal for prototyping, experimentation, and fast iteration
- Easy to delete/recreate

**Existing custom packages (`package_name`)**
- Pass `package_name` to create the object in a real development package
- The package MUST already exist (the tool does not create packages) and MUST be in the Z* custom namespace (e.g. `ZAI_TEST`)
- Standard SAP and customer packages are rejected

**Transport requests (`transport_request`)** — required for non-`$TMP` packages:
- `"NEW"` — creates a fresh transport request (its text is derived from the object description)
- An existing transport number (e.g. `"B42K902346"`) — reuses that request
- **Omit it on the first call** — the tool creates nothing and instead returns your open transport requests to choose from (`status: "transport_selection_required"`); re-call with the same arguments plus the chosen `transport_request` to proceed

## Workflow and Activation

The tool automatically:
1. ✅ Creates the object
2. ✅ Uploads source code
3. ✅ Unlocks the object
4. ✅ **Activates the object**
5. ✅ Returns activation results

**Activation results include:**
- Syntax errors with line numbers
- Warnings with line numbers
- Success/failure status
- Quickfix suggestions (if available)

## Output Format

Returns structured JSON:
```json
{
  "success": true,
  "object_name": "ZAI_MY_PROGRAM",
  "object_type": "PROG/P",
  "package": "$TMP",
  "activation": {
    "success": true,
    "errors": [],
    "warnings": [
      {
        "line": 5,
        "message": "Variable is not used",
        "severity": "warning"
      }
    ]
  }
}
```

## Usage Examples

**Create a simple program:**
```
Create an ABAP program called SALES_REPORT that displays sales data
```

**Create a class with custom prefix:**
```
Generate class ZP_CUSTOMER_MANAGER that handles customer data operations
```

**Create a CDS view:**
```
Build CDS view ZI_BOOKING for booking data with associations to customer and flight
```

**Create RAP behavior implementation:**
```
Create behavior implementation class for ZI_TRAVEL_BO with create, update, delete operations
```

**Create metadata extension:**
```
Generate metadata extension for ZC_BOOKING_PROC with Fiori UI annotations
```

**Create a table in an existing package with a new transport:**
```
Create table ZAI_BOOKINGS in package ZAI_TRAVEL on a new transport request
```

**Create a domain with fixed values:**
```
Create domain ZAI_STATUS as CHAR 2 with fixed values NW (New), IP (In Process), CO (Completed)
```

**Create a class with ABAP Unit tests:**
```
Create class ZAI_CALCULATOR with an add method and unit tests in the testclasses section
```

## RAP Development Pattern

For RAP (RESTFUL ABAP Programming), create in sequence:

1. **CDS View** (Interface view - ZI_*)
   ```
   Create CDS view ZI_BOOKING with fields booking_id, customer_id, flight_id
   ```

2. **Behavior Definition** (BDEF)
   ```
   Create behavior definition for ZI_BOOKING with create, update, delete
   ```

3. **Behavior Implementation** (Class with local handlers)
   ```
   Create behavior implementation for ZI_BOOKING with validation and determination
   ```
   
4. **Projection View** (Consumption - ZC_*)
   ```
   Create projection view ZC_BOOKING based on ZI_BOOKING
   ```

5. **Metadata Extension** (UI annotations)
   ```
   Create metadata extension for ZC_BOOKING with list and object page layouts
   ```

6. **Service Definition**
   ```
   Create service definition ZUI_BOOKING exposing ZC_BOOKING
   ```

### CDS Compositions: Two-Phase Workflow

When a root view entity and a child view entity reference each other (`composition of` / `association to parent`), SAP ADT rejects creating either one first because the referenced view does not exist yet. **Never create both views with cross-references in a single step:**

1. **Phase 1**: Create the root view WITHOUT the `composition of` line and the child view WITHOUT the `association to parent` line; activate both
2. **Phase 2**: Use `change-ai-object` to add the composition to the root and the parent association to the child; activate both again

## Error Handling

**Common errors and fixes:**

| Error | Cause | Fix |
|-------|-------|-----|
| Name too long | Exceeds type limit (30/40 chars) | Shorten name |
| Syntax error line X | Code issue | Review source, fix syntax |
| Object already exists | Duplicate name | Use different name or delete existing |
| Missing function_group | Function creation without group | Provide function_group parameter |
| Package rejected | Standard SAP/customer package | Use `$TMP` or an existing Z* custom package |
| transport_selection_required | Non-$TMP package without transport | Re-call with `transport_request` = "NEW" or a listed transport number |

## Tips for Effective Use

1. **Start simple**: Create basic structure first
2. **Describe requirements**: AI generates better code with clear description
3. **Use multi-section**: For complex classes with handlers and test classes
4. **Check activation**: Always review errors/warnings
5. **Iterate in $TMP**: Prototype locally, then create in the target package with a transport when stable
6. **Custom prefixes**: Use meaningful Z-prefixes for organization
7. **Ask before transporting**: Confirm the target package and transport request with the user before creating outside `$TMP`

## Output Expectations

When Copilot uses this skill, expect:
- Object created successfully
- Activation status (errors/warnings)
- Line numbers for any issues
- Recommendations for fixes
- Next steps: "Object created, now test it" or "Fix syntax errors"

## Integration with Other Skills

**Typical workflow:**
1. Use `sap-help-search` for API research
2. Use `search-object` to find similar objects
3. Use `get-object-info` to study patterns
4. Use `create-ai-object` to build new object
5. Use `activate-object` if changes needed

## Security and Safety

**Built-in safeguards:**
- ✅ Z-prefix enforcement (no SAP standard modification)
- ✅ Package validation: only `$TMP` or existing Z*-custom packages; standard SAP/customer packages are rejected
- ✅ Transport handling: non-`$TMP` objects always land on a transport request (new or existing)
- ✅ Automatic activation with syntax check

## When NOT to Use

❌ Don't use this skill when:
- Modifying existing objects (use `change-ai-object`)
- Just viewing code (use `get-object-info`)
- Searching for objects (use `search-object`)
