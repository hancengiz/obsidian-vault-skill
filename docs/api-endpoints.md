# Obsidian Local REST API - Complete Endpoint Reference

Based on OpenAPI v3.0.2 specification. This document provides a complete breakdown of all available endpoints.

## Authentication

- **Method**: Bearer Token (API Key)
- **Header**: `Authorization: Bearer <your-api-key>`
- **Security Scheme**: HTTP Bearer authentication
- **Note**: Only the `/` endpoint does NOT require authentication

---

## System Endpoints

**What it is**: Meta-endpoints for the REST API itself - server info, versions, and SSL certificate.

**Use case**: Verify API connectivity and version compatibility before operations. Example: User troubleshooting asks "Check if my Obsidian API is working" - skill calls `GET /` to confirm the API is responding.

### GET `/`
**Summary**: Returns basic details about the server
**Auth Required**: No (only unauthenticated endpoint)

**Note**: This is a read-only health check endpoint - completely safe. Useful for verifying the API is running.

**Returns**:
```json
{
  "authenticated": boolean,
  "ok": "OK",
  "service": "Obsidian Local REST API",
  "versions": {
    "obsidian": "string",  // Obsidian plugin API version
    "self": "string"       // Plugin version
  }
}
```

### GET `/openapi.yaml`
**Summary**: Returns OpenAPI YAML specification
**Auth Required**: Yes
**Returns**: OpenAPI YAML document

**Note**: This is a read-only operation - returns the complete API documentation in OpenAPI format.

### GET `/obsidian-local-rest-api.crt`
**Summary**: Returns the SSL certificate used by the API
**Auth Required**: Yes
**Returns**: Certificate file

**Note**: This is a read-only operation - returns the SSL certificate file for HTTPS connections.

---

## Active File Operations

**What it is**: The note currently open and focused in Obsidian's editor window.

**Use case**: Context-aware modifications without specifying file paths. Example: User working on project notes asks "Add a new task under the Tasks heading" - skill uses `PATCH /active/` to modify whatever file they're currently viewing.

Operations on the **currently active file** in Obsidian.

### GET `/active/`
**Summary**: Get content of the active file
**Accept Headers**:
- `text/markdown` - Returns raw markdown content
- `application/vnd.olrapi.note+json` - Returns JSON with parsed metadata

**Note**: This is a read-only operation - completely safe, doesn't modify anything.

**JSON Response Schema**:
```json
{
  "content": "string",
  "frontmatter": object,
  "path": "string",
  "stat": {
    "ctime": number,
    "mtime": number,
    "size": number
  },
  "tags": ["string"]
}
```

### POST `/active/`
**Summary**: Append content to the end of the active file
**Content-Type**: `text/markdown`
**Body**: Markdown content to append
**Returns**: 204 Success

**Note**: This is safe - only adds content to the end, doesn't remove anything. Use POST to add content, PUT to replace all content.

### PUT `/active/`
**Summary**: Replace the entire content of the active file
**Content-Type**: `text/markdown` or `*/*`
**Body**: New content
**Returns**: 204 Success

⚠️ **DESTRUCTIVE OPERATION**: Replaces ALL content in the active file. Original content is completely lost (no append, full replace).

### PATCH `/active/`
**Summary**: Partially update content relative to headings, blocks, or frontmatter
**Headers**:
- `Operation`: `append` | `prepend` | `replace` (required)
- `Target-Type`: `heading` | `block` | `frontmatter` (required)
- `Target`: Target identifier (required, URL-encoded for non-ASCII)
- `Target-Delimiter`: Delimiter for nested headings (default: `::`)
- `Trim-Target-Whitespace`: `true` | `false` (default: `false`)
- `Create-Target-If-Missing`: Create target if doesn't exist (frontmatter only)

**Content-Type**: `text/markdown` or `application/json`
**Body**: Content to insert
**Returns**: 200 Success

**Examples**:
- Heading: `Target: Heading 1::Subheading 1:1`
- Block: `Target: 2d9b4a` (block reference ID)
- Frontmatter: `Target: fieldName`
- Table (as JSON): `[["row1col1", "row1col2"], ["row2col1", "row2col2"]]`

⚠️ **POTENTIALLY DESTRUCTIVE**: When the `Operation` header is set to `replace` (as opposed to `append` or `prepend`), the targeted section (heading content, block, or frontmatter field) is completely replaced. Wrong target can modify unintended sections. Safe operations are `append` and `prepend` which add content without removing existing content.

### DELETE `/active/`
**Summary**: Delete the currently active file
**Returns**: 204 Success

⚠️ **DESTRUCTIVE OPERATION**: Permanently deletes whichever file is currently open in Obsidian's editor. Risk: User may not be aware which file is active.

---

## Vault File Operations

**What it is**: A vault is your entire knowledge base - a folder structure containing all notes and attachments as markdown files.

**Use case**: Organized file management with specific paths. Example: User asks "Create a meeting note in Work/Meetings for today's standup" - skill uses `PUT /vault/Work/Meetings/2025-11-10-standup.md` to create the file in the correct location.

Operations on **specific files** by path.

### GET `/vault/{filename}`
**Summary**: Get content of a specific file
**Parameters**: `filename` - Path relative to vault root (format: `path`)
**Accept Headers**:
- `text/markdown` - Raw markdown
- `application/vnd.olrapi.note+json` - JSON with metadata

**Returns**: Same JSON schema as `/active/`

**Note**: This is a read-only operation - completely safe, doesn't modify anything.

### POST `/vault/{filename}`
**Summary**: Append content to file (creates if doesn't exist)
**Parameters**: `filename`
**Content-Type**: `text/markdown`
**Body**: Content to append
**Returns**: 204 Success

**Note**: This is safe - only adds content to the end of the file. If the file doesn't exist, it creates it with the content. Use POST to add, PUT to replace.

### PUT `/vault/{filename}`
**Summary**: Create new file or replace existing file content
**Parameters**: `filename`
**Content-Type**: `text/markdown` or `*/*`
**Body**: New content
**Returns**: 204 Success

⚠️ **DESTRUCTIVE IF FILE EXISTS**: If the file exists, ALL content is replaced. If creating a new file, this is safe. Always check if file exists first to avoid accidental overwrites.

### PATCH `/vault/{filename}`
**Summary**: Partially update content (same as PATCH `/active/`)
**Parameters**: `filename`
**Headers**: Same as PATCH `/active/` (see above for full header list)
**Returns**: 200 Success

⚠️ **POTENTIALLY DESTRUCTIVE**: When the `Operation` header is set to `replace`, the targeted section is completely replaced. Validate target before execution. (Note: `Operation` can be `append`, `prepend`, or `replace` - only `replace` is destructive)

### DELETE `/vault/{filename}`
**Summary**: Delete a file
**Parameters**: `filename`
**Returns**: 204 Success

⚠️ **DESTRUCTIVE OPERATION**: Permanently deletes the specified file. Cannot be undone via API.

---

## Vault Directory Operations

**What it is**: Browse and list the folder structure within your vault.

**Use case**: Explore vault structure before operations. Example: User asks "What notes do I have in my Projects folder?" - skill uses `GET /vault/Projects/` to list files and subdirectories, helping find the right location or discover existing notes.

### GET `/vault/`
**Summary**: List files in vault root directory
**Returns**:
```json
{
  "files": [
    "mydocument.md",
    "somedirectory/"
  ]
}
```
**Note**: This is a read-only operation - completely safe. Directories end with `/`.

### GET `/vault/{pathToDirectory}/`
**Summary**: List files in a specific directory
**Parameters**: `pathToDirectory` - Directory path relative to vault root
**Returns**: Same as `/vault/` above
**Note**: This is a read-only operation - completely safe. Empty directories are not returned.

---

## Periodic Notes Operations

**What it is**: Time-based notes with automatic date-based filenames (via Periodic Notes plugin). Used for journaling, planning, and time-based organization.

**Use case**: Seamless time-based workflows without knowing dates. Example: User asks "Add 'Review quarterly goals' to my weekly tasks" - skill uses `PATCH /periodic/weekly/` to modify this week's note, which is automatically calculated and created if needed.

Supports: `daily`, `weekly`, `monthly`, `quarterly`, `yearly` notes.

### GET `/periodic/{period}/`
**Summary**: Get current periodic note for the specified period
**Parameters**:
- `period`: `daily` | `weekly` | `monthly` | `quarterly` | `yearly` (default: `daily`)

**Accept Headers**: Same as vault files
**Returns**: Note content (markdown or JSON)

**Note**: This is a read-only operation - completely safe. Gets today's daily note, this week's weekly note, etc.

### GET `/periodic/{period}/{year}/{month}/{day}/`
**Summary**: Get periodic note for a specific date
**Parameters**:
- `period`: Period type
- `year`: Year (number)
- `month`: Month 1-12 (number)
- `day`: Day 1-31 (number)

**Returns**: Note content

**Note**: This is a read-only operation - completely safe. Gets a historical periodic note for the specified date.

### POST `/periodic/{period}/`
**Summary**: Append to current periodic note (creates if doesn't exist)
**Parameters**: `period`
**Body**: Content to append
**Returns**: 204 Success

**Note**: This is safe - adds content to the end of today's/this week's periodic note. Creates the note if it doesn't exist yet.

### POST `/periodic/{period}/{year}/{month}/{day}/`
**Summary**: Append to periodic note for specific date (creates if needed)
**Parameters**: `period`, `year`, `month`, `day`
**Body**: Content to append
**Returns**: 204 Success

**Note**: This is safe - adds content to the end of a historical periodic note. Creates the note if it doesn't exist.

### PUT `/periodic/{period}/`
**Summary**: Replace content of current periodic note
**Parameters**: `period`
**Body**: New content
**Returns**: 204 Success

⚠️ **DESTRUCTIVE OPERATION**: Replaces entire content of the current period's note (today's daily note, this week's weekly note, etc.). All existing content is lost.

### PUT `/periodic/{period}/{year}/{month}/{day}/`
**Summary**: Replace content of periodic note for specific date
**Parameters**: `period`, `year`, `month`, `day`
**Body**: New content
**Returns**: 204 Success

⚠️ **DESTRUCTIVE OPERATION**: Replaces entire content of a historical periodic note. All existing content is lost.

### PATCH `/periodic/{period}/`
**Summary**: Partially update current periodic note
**Parameters**: `period`
**Headers**: Same as PATCH `/active/` (see Active File Operations section for full header list)
**Returns**: 200 Success

⚠️ **POTENTIALLY DESTRUCTIVE**: When the `Operation` header is set to `replace`, targeted sections in the current period's note are completely replaced. The `Operation` header can be `append`, `prepend`, or `replace` - only `replace` is destructive.

### PATCH `/periodic/{period}/{year}/{month}/{day}/`
**Summary**: Partially update periodic note for specific date
**Parameters**: `period`, `year`, `month`, `day`
**Headers**: Same as PATCH `/active/` (see Active File Operations section for full header list)
**Returns**: 200 Success

⚠️ **POTENTIALLY DESTRUCTIVE**: When the `Operation` header is set to `replace`, targeted sections in historical periodic notes are completely replaced. The `Operation` header can be `append`, `prepend`, or `replace` - only `replace` is destructive.

### DELETE `/periodic/{period}/`
**Summary**: Delete current periodic note
**Parameters**: `period`
**Returns**: 204 Success

**⚠️ WARNING - DESTRUCTIVE**: This deletes the note for the current time period:
- `daily` → Deletes today's note (e.g., `2025-11-10.md`)
- `weekly` → Deletes this week's note (e.g., `2025-W45.md`)
- `monthly` → Deletes this month's note (e.g., `2025-11.md`)
- `quarterly` → Deletes this quarter's note (e.g., `2025-Q4.md`)
- `yearly` → Deletes this year's note (e.g., `2025.md`)

The API automatically calculates the current date and determines which file to delete based on periodic notes plugin configuration. Calling `DELETE /periodic/daily/` at 11 PM deletes all of today's journal entries, tasks, and notes - an entire day's work gone in one API call.

### DELETE `/periodic/{period}/{year}/{month}/{day}/`
**Summary**: Delete periodic note for specific date
**Parameters**: `period`, `year`, `month`, `day`
**Returns**: 204 Success

**⚠️ WARNING - DESTRUCTIVE**: This deletes historical periodic notes for the specified date. For example, `DELETE /periodic/daily/2025/10/15/` deletes the daily note from October 15, 2025, permanently removing all content from that date.

---

## Search Operations

**What it is**: Simple text search finds content in notes. Advanced search uses Dataview (SQL-like queries for metadata/frontmatter) or JsonLogic (JSON-based queries). Note: Dataview can only query metadata, not note content.

**Use case**: Query knowledge base like a database. Example: User asks "Find all book notes rated 5 stars that I'm still reading" - skill sends Dataview DQL query: `TABLE rating, status FROM #book WHERE rating = 5 AND status = "reading"` to return matching files.

### POST `/search/`
**Summary**: Advanced search using Dataview DQL or JsonLogic queries
**Content-Type**:
- `application/vnd.olrapi.dataview.dql+txt` - Dataview DQL query
- `application/vnd.olrapi.jsonlogic+json` - JsonLogic query

**Note**: This is a read-only operation - completely safe, doesn't modify any files.

**Dataview DQL Example**:
```
TABLE
  time-played AS "Time Played",
  length AS "Length",
  rating AS "Rating"
FROM #game
SORT rating DESC
```

**JsonLogic Examples**:

Find by frontmatter value:
```json
{
  "==": [
    {"var": "frontmatter.myField"},
    "myValue"
  ]
}
```

Find by tag:
```json
{
  "in": [
    "myTag",
    {"var": "tags"}
  ]
}
```

Find by URL glob:
```json
{
  "or": [
    {"===": [{"var": "frontmatter.url"}, "https://myurl.com/some/path/"]},
    {"glob": [{"var": "frontmatter.url-glob"}, "https://myurl.com/some/path/"]}
  ]
}
```

**Custom JsonLogic Operators**:
- `glob: [PATTERN, VALUE]` - Match glob patterns
- `regexp: [PATTERN, VALUE]` - Match regular expressions

**Response**:
```json
[
  {
    "filename": "path/to/file.md",
    "result": "string|number|array|object|boolean"
  }
]
```

**Note**: Only returns non-falsy results. Falsy values: `false`, `null`, `undefined`, `0`, `[]`, `{}`

### POST `/search/simple/`
**Summary**: Simple text-based search
**Query Parameters**:
- `query`: Search text (required)
- `contextLength`: Context around match (default: 100)

**Note**: This is a read-only operation - completely safe, doesn't modify any files.

**Response**:
```json
[
  {
    "filename": "path/to/file.md",
    "score": number,
    "matches": [
      {
        "match": {
          "start": number,
          "end": number
        },
        "context": "string"
      }
    ]
  }
]
```

---

## Command Operations

**What it is**: The Command Palette (Cmd/Ctrl+P) contains hundreds of commands from Obsidian core and plugins. Each has a unique ID (e.g., `graph:open`) and can be executed programmatically.

**Use case**: Trigger any Obsidian feature or plugin command. Example: User asks "Open the graph view" - skill uses `GET /commands/` to find the graph command ID, then `POST /commands/{id}/` to execute it in Obsidian's UI.

Execute Obsidian commands programmatically.

### GET `/commands/`
**Summary**: List all available Obsidian commands
**Returns**:
```json
{
  "commands": [
    {
      "id": "global-search:open",
      "name": "Search: Search in all files"
    },
    {
      "id": "graph:open",
      "name": "Graph view: Open graph view"
    }
  ]
}
```

**Note**: This is a read-only operation - completely safe, just lists available commands.

### POST `/commands/{commandId}/`
**Summary**: Execute a specific command
**Parameters**: `commandId` - ID of the command to execute
**Returns**: 204 Success
**Error**: 404 if command doesn't exist

⚠️ **CONTEXT-DEPENDENT RISK**: Impact varies by command. Some commands may delete files, modify vault structure, or perform bulk operations. Always verify command behavior before execution. Examples of risky commands: delete operations, bulk modifications, vault restructuring.

---

## Open File Operation

**What it is**: Bring a specific file into focus in Obsidian's editor (like clicking a file in the file explorer).

**Use case**: Guide user attention after operations. Example: After creating a meeting note, user asks "Open it" - skill uses `POST /open/Work/Meetings/2025-11-10-standup.md` with `newLeaf=true` to open the file in a new tab, creating seamless workflow between Claude and Obsidian.

### POST `/open/{filename}`
**Summary**: Open a file in the Obsidian UI
**Parameters**:
- `filename`: Path to file (relative to vault root)
- `newLeaf`: Open in new leaf/tab? (query parameter, optional, boolean)

**Returns**: 200 Success

**Note**: This brings a file into focus in Obsidian's editor. If the file doesn't exist, it creates an empty file. Set `newLeaf=true` to open in a new tab instead of the current pane.

---

## Error Responses

All errors return an `Error` schema:
```json
{
  "errorCode": 40149,  // 5-digit unique error code
  "message": "Description of the error"
}
```

**Common HTTP Status Codes**:
- `200`: Success (with body)
- `204`: Success (no body)
- `400`: Bad Request - Invalid parameters or content
- `401`: Unauthorized - Invalid or missing API key
- `404`: Not Found - File, directory, or command doesn't exist
- `405`: Method Not Allowed - Path references directory instead of file

---

## NoteJson Schema

When using `Accept: application/vnd.olrapi.note+json`, files are returned as:

```json
{
  "content": "string",        // Raw markdown content
  "frontmatter": object,      // Parsed YAML frontmatter as JSON
  "path": "string",          // Path relative to vault root
  "stat": {
    "ctime": number,         // Creation time (timestamp)
    "mtime": number,         // Modification time (timestamp)
    "size": number           // File size in bytes
  },
  "tags": ["string"]        // All tags in the file (including frontmatter and inline)
}
```

---

## Key Notes

1. **PATCH API Change**: Version 3.0 changed PATCH API. Old version deprecated, will be removed in 4.0. See: https://github.com/coddingtonbear/obsidian-local-rest-api/wiki/Changes-to-PATCH-requests-between-versions-2.0-and-3.0

2. **Path Format**:
   - Always relative to vault root
   - Use forward slashes `/`
   - No leading slash
   - Include file extension (`.md`)
   - Example: `folder/subfolder/note.md`

3. **URL Encoding**:
   - Target values with non-ASCII characters MUST be URL-encoded
   - Recommended for all targets to avoid issues

4. **Content Types**:
   - Markdown: `text/markdown`
   - JSON: `application/json`
   - Any: `*/*`
   - Note JSON: `application/vnd.olrapi.note+json`
   - Dataview: `application/vnd.olrapi.dataview.dql+txt`
   - JsonLogic: `application/vnd.olrapi.jsonlogic+json`

5. **Default Server Endpoints**:
   - HTTPS: `https://127.0.0.1:27124` (default, secure mode)
   - HTTP: `http://127.0.0.1:27123` (insecure mode)
   - Configurable host and port

---

## Complete Endpoint List

| Method | Endpoint | Summary |
|--------|----------|---------|
| GET | `/` | Server info (no auth) |
| GET | `/openapi.yaml` | API specification |
| GET | `/obsidian-local-rest-api.crt` | SSL certificate |
| GET | `/active/` | Get active file |
| POST | `/active/` | Append to active file |
| PUT | `/active/` | Replace active file |
| PATCH | `/active/` | Partial update active file |
| DELETE | `/active/` | Delete active file |
| GET | `/vault/{filename}` | Get file |
| POST | `/vault/{filename}` | Append to file |
| PUT | `/vault/{filename}` | Create/replace file |
| PATCH | `/vault/{filename}` | Partial update file |
| DELETE | `/vault/{filename}` | Delete file |
| GET | `/vault/` | List root directory |
| GET | `/vault/{path}/` | List directory |
| GET | `/periodic/{period}/` | Get current periodic note |
| POST | `/periodic/{period}/` | Append to current periodic note |
| PUT | `/periodic/{period}/` | Replace current periodic note |
| PATCH | `/periodic/{period}/` | Partial update current periodic note |
| DELETE | `/periodic/{period}/` | Delete current periodic note |
| GET | `/periodic/{period}/{y}/{m}/{d}/` | Get periodic note for date |
| POST | `/periodic/{period}/{y}/{m}/{d}/` | Append to periodic note for date |
| PUT | `/periodic/{period}/{y}/{m}/{d}/` | Replace periodic note for date |
| PATCH | `/periodic/{period}/{y}/{m}/{d}/` | Partial update periodic note for date |
| DELETE | `/periodic/{period}/{y}/{m}/{d}/` | Delete periodic note for date |
| POST | `/search/` | Advanced search (Dataview/JsonLogic) |
| POST | `/search/simple/` | Simple text search |
| GET | `/commands/` | List commands |
| POST | `/commands/{id}/` | Execute command |
| POST | `/open/{filename}` | Open file in UI |

**Total**: 31 distinct endpoints
