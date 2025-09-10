# SourceMod Shop_Top10 Plugin - Copilot Instructions

## Repository Overview

This repository contains a SourceMod plugin that extends the Shop Core system with a "Top 10 Richest Players" functionality. The plugin integrates with a shop system to display the wealthiest players on the server through an interactive panel interface.

**Key Context:**
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11+ for Source engine games
- **Integration**: Depends on Shop Core plugin (srcdslab/sm-plugin-Shop-Core)
- **Build System**: SourceKnight (configured via sourceknight.yaml)
- **Database**: Async SQL queries for player data

## Project Structure

```
addons/sourcemod/scripting/
├── Shop_Top10.sp          # Main plugin source code
sourceknight.yaml          # Build configuration and dependencies
.github/workflows/ci.yml   # CI/CD pipeline for building/releasing
```

## Core Plugin Functionality

The plugin provides:
1. **Shop Integration**: Adds a menu item to the Shop Core functions menu
2. **Database Queries**: Retrieves top 10 players by money from shop database  
3. **UI Display**: Shows results in a SourceMod panel with navigation
4. **Error Handling**: Manages SQL errors and edge cases

## Code Standards & Best Practices

### SourcePawn Conventions
```sourcepawn
#pragma semicolon 1
#pragma newdecls required
```

### Variable Naming
- **Global variables**: Prefix with `g_` (e.g., `g_Database`, `g_DatabasePrefix`)
- **Functions**: PascalCase (e.g., `FunctionDisplay`, `GetTop10`)
- **Local variables**: camelCase (e.g., `clientSerial`, `playerCount`)

### Memory Management
- Use `delete` instead of `CloseHandle()` for modern SourceMod
- Always use `delete` without null checks (safe in SourceMod)
- For StringMap/ArrayList: use `delete` and recreate, never `.Clear()`

### Database Operations
- **ALL SQL queries MUST be asynchronous** using `SQL_TQuery`
- Use proper string escaping for SQL injection prevention
- Handle SQL errors in callbacks with proper logging
- Use database transactions when performing multiple related operations

### Correct Patterns
```sourcepawn
// ✅ Modern memory management
delete panel;

// ✅ Async SQL with error handling  
SQL_TQuery(database, CallbackFunction, query, clientSerial);

// ✅ Proper variable types
int money = SQL_FetchInt(hndl, 1);

// ✅ Global variable naming
Handle g_Database;
char g_DatabasePrefix[16];
```

### Anti-Patterns to Fix
```sourcepawn
// ❌ Old Handle API
CloseHandle(panel);

// ❌ Incorrect variable type
char money; // Should be 'int money'

// ❌ Missing global prefix
Handle dp; // Should be 'Handle g_Database'

// ❌ Sync SQL operations (forbidden)
SQL_Query(database, query);
```

## Build System

### SourceKnight Configuration
- **Build tool**: SourceKnight manages dependencies and compilation
- **Dependencies**: Auto-downloads SourceMod and Shop Core includes
- **Output**: Compiled .smx files in `/addons/sourcemod/plugins`

### Local Development
```bash
# Dependencies are managed automatically by SourceKnight
# Build process downloads SourceMod 1.11.0-git6917 and Shop Core includes
```

### CI/CD Pipeline
- **Triggers**: Push, PR, manual dispatch
- **Build**: Uses `maxime1907/action-sourceknight@v1`
- **Release**: Auto-creates releases for master/main and tags
- **Artifacts**: Packaged as .tar.gz with proper directory structure

## Integration Points

### Shop Core Dependency
```sourcepawn
#include <shop>

// Required callbacks
public void Shop_Started()     // Initialize when shop loads
public void OnPluginEnd()     // Cleanup: Shop_UnregisterMe()

// Integration functions
Shop_AddToFunctionsMenu()     // Register in shop menu
Shop_ShowFunctionsMenu()      // Return to shop menu
Shop_GetDatabase()            // Get shared database handle
Shop_GetDatabasePrefix()      // Get table prefix
```

### Database Schema Expectations
- Table: `{prefix}players`
- Required columns: `name` (varchar), `money` (int)
- Query pattern: `SELECT name, money FROM {prefix}players ORDER BY money DESC LIMIT 10`

## Common Development Tasks

### Adding New Features
1. **Always maintain Shop Core integration patterns**
2. **Use async SQL for any database operations**
3. **Implement proper error handling and edge cases**
4. **Follow existing panel/menu interaction patterns**
5. **Test with various player counts (0, 1-9, 10+ players)**

### Debugging Database Issues
```sourcepawn
// Check SQL errors in callbacks
if (hndl == INVALID_HANDLE || error[0]) 
{
    LogError("QueryName: %s", error);
    return;
}
```

### Panel/Menu Patterns
- Use `CreatePanel()` for display-only interfaces
- Implement proper key handling in `PanelHandler`
- Always provide "Back" (key 8) and "Exit" (key 10) options
- Set appropriate timeouts (typically 30 seconds)

## Performance Considerations

### Database Optimization
- **Limit queries**: Use `LIMIT 10` to prevent excessive data retrieval
- **Index considerations**: Ensure `money` column is indexed for performance
- **Connection reuse**: Use shared Shop Core database handle

### Frequency Optimization  
- **Avoid timers**: This plugin is event-driven, no background processing
- **Cache results**: Consider caching if called frequently (not applicable here)
- **Minimize string operations**: Pre-format common strings when possible

## Testing & Validation

### Manual Testing Scenarios
1. **Normal case**: 10+ players in database, verify display formatting
2. **Edge cases**: 0 players, 1-9 players, exactly 10 players  
3. **Database errors**: Test with invalid database connection
4. **Navigation**: Test "Back" and "Exit" functionality
5. **Integration**: Verify shop menu registration and navigation

### Error Conditions
- Database connection failures
- Empty player database
- SQL query syntax errors
- Invalid client serials in callbacks

## Common Issues & Solutions

### Memory Leaks
- **Problem**: Using `CloseHandle()` instead of `delete`
- **Solution**: Replace all `CloseHandle(handle)` with `delete handle`

### Variable Type Mismatches
- **Problem**: `char money;` for numeric values
- **Solution**: Use appropriate types (`int money`)

### Blocking Operations
- **Problem**: Using synchronous SQL functions
- **Solution**: Always use `SQL_TQuery` with callbacks

### Global Variable Naming
- **Problem**: Variables like `dp` without prefixes
- **Solution**: Use `g_` prefix for globals (`g_Database`)

## Version Management

- **Versioning**: Follow semantic versioning in plugin info
- **Current**: Version 2.0.2 (as of latest commit)
- **Releases**: Automated via GitHub Actions on tags and master/main
- **Compatibility**: Maintain compatibility with SourceMod 1.11+

## Quick Reference

### Essential Functions
```sourcepawn
Shop_AddToFunctionsMenu(displayFunc, selectFunc)  // Register menu item
SQL_TQuery(db, callback, query, data)             // Async SQL query
GetClientFromSerial(serial)                        // Validate client in callback
CreatePanel() / delete panel                       // UI creation/cleanup
```

### Common Patterns
```sourcepawn
// Plugin lifecycle
public void OnPluginStart() { /* late loading check */ }
public void Shop_Started() { /* initialize */ }
public void OnPluginEnd() { Shop_UnregisterMe(); }

// Menu integration
public void FunctionDisplay(int client, char[] buffer, int maxlength)
public bool FunctionSelect(int client)

// SQL callback pattern
public void SqlCallback(Handle owner, Handle hndl, const char[] error, any data)
```

This plugin demonstrates a clean integration with Shop Core while providing a specific utility function. When modifying or extending it, maintain the established patterns and always prioritize compatibility with the Shop Core ecosystem.