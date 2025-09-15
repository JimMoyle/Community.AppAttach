# PowerShell Code Style

## Always Use Singular Nouns for Function Names

- Function names should use singular nouns (e.g., `Get-Item`, not `Get-Items`) unless the function always returns multiple items. This improves clarity and aligns with PowerShell naming conventions.

**Example:**

```powershell
# Good
function Get-User { ... }

# Bad
function Get-Users { ... }
```

---

## Always Use PascalCase for Function and Parameter Names

- Use PascalCase for all function names and parameter names to match PowerShell conventions and improve readability.

**Example:**

```powershell
# Good
function Get-UserData { ... }
param([string]$UserName)

# Bad
function get_userdata { ... }
param([string]$username)
```

---

## Always Include Comment-Based Help for Public Functions

- Every public function should include comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE` sections. This improves discoverability and usability.

**Example:**

```powershell
<#
.SYNOPSIS
    Gets user data.
.DESCRIPTION
    Retrieves user data from the system.
.PARAMETER UserName
    The name of the user.
.EXAMPLE
    Get-UserData -UserName "Alice"
#>
function Get-UserData { ... }
```

---

## Always Use Verb-Noun Format for Function Names

- All function names must follow the approved PowerShell verb-noun format, using standard verbs from the [approved list](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands).

**Example:**

```powershell
# Good
function Set-UserPassword { ... }

# Bad
function ChangePassword { ... }
```

---

## Always Validate Parameter Input Where Appropriate

- Use `[ValidateSet()]`, `[ValidateRange()]`, or `[ValidatePattern()]` attributes to restrict parameter values when possible. This improves reliability and user experience.

**Example:**

```powershell
param(
    [Parameter(Position = 0, ValueFromPipelineByPropertyName = $true)]
    [ValidateSet('Start', 'Stop', 'Restart')]
    [string]$Action
)
```

---

## Always Use Consistent Indentation (4 Spaces)

- Indent all code blocks using 4 spaces, not tabs, for consistency and readability.

---

## Always Use Meaningful Variable Names

- Variable names should be descriptive and avoid abbreviations unless they are well-known. This improves code clarity and maintainability.

**Example:**

```powershell
# Good
$UserList = Get-UserList

# Bad
$ul = Get-UserList
```

---

## Always Use Write-Verbose and Write-Debug for Diagnostic Output

- Use `Write-Verbose` and `Write-Debug` for optional diagnostic output instead of `Write-Host`. This allows users to control output verbosity.

---

## Always Use Try/Catch/Finally for Error Handling in Functions

- Use structured error handling with `try/catch/finally` blocks in functions that perform actions which may fail. This improves robustness and error reporting.

**Example:**

```powershell
try {
    # Code that may throw
}
catch {
    Write-Error $_
}
finally {
    # Cleanup code
}
```

## Use Splatting for Commands and Function Calls with More Than Two Parameters

- When a PowerShell command or function call uses more than two parameters, use a splatting variable for improved readability and maintainability. This applies to both built-in cmdlets and custom functions.

**Example:**

```powershell
# Bad
Get-ChildItem -Path "C:\Temp" -Recurse -Filter "*.log"
My-Function -Path "C:\Temp" -Recurse -Filter "*.log"

# Good
$paramsGetChildItem = @{
    Path    = "C:\Temp"
    Recurse = $true
    Filter  = "*.log"
}
Get-ChildItem @paramsGetChildItem
My-Function @paramsGetChildItem
```

## Avoid Using Backtick (`) for Line Continuation

- Never use the backtick (`) character at the end of a line for line continuation. Instead, use splatting or other PowerShell best practices to improve readability.

**Example:**

```powershell
# Bad
Get-ChildItem `
    -Path "C:\Temp" `
    -Recurse `
    -Filter "*.log"

# Good
$paramsGetChildItem = @{
    Path    = "C:\Temp"
    Recurse = $true
    Filter  = "*.log"
}
Get-ChildItem @paramsGetChildItem
```

## Always Use Advanced Functions

- All PowerShell functions must be written as advanced functions using the `function` keyword and the `[CmdletBinding()]` attribute. This enables cmdlet-like features such as parameter validation, support for common parameters, and better pipeline integration.

**Example:**

```powershell
# Bad
function Get-Example {
    param($Path)
    Write-Output "Path is $Path"
}

# Good
function Get-Example {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Output "Path is $Path"
}
```

## Always Add ValueFromPipelineByPropertyName = $true to Parameters

- For all function parameters, always include `ValueFromPipelineByPropertyName = $true` in the `[Parameter()]` attribute. This ensures that parameters can accept values from pipeline property names, improving usability and consistency.
- Where appropriate, include `ValueFromPipeline = $true` for one parameter per function to support direct pipeline input.

**Example:**

```powershell
# Bad
param(
    [Parameter()]
    [string]$Name
)

# Good
param(
    [Parameter(
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [string]$Name
)
```

## Clarification: ValueFromPipeline vs. ValueFromPipelineByPropertyName

- Use `ValueFromPipeline = $true` for only one parameter per function, usually the main input, to allow direct pipeline input (e.g., passing objects directly to the function).
- Use `ValueFromPipelineByPropertyName = $true` for all parameters that should accept values from matching property names in pipeline input objects.
- You can use both on the same parameter to support both direct and property-based pipeline input.

**Example:**

```powershell
param(
    [Parameter(
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias('PSPath')]
    [string[]]$Path,

    [Parameter(
        ValueFromPipelineByPropertyName = $true
    )]
    [string]$Name
)
```

## Clarification: Comments in Empty begin, process, and end Blocks

- Always include a comment in any empty `begin`, `process`, or `end` block for clarity and consistency, such as `# No initialization needed`, `# No processing needed`, or `# No cleanup needed`.

**Example:**

```powershell
function Example-Function {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [string[]]$Path
    )
    begin {
        Set-StrictMode -Version Latest
        # No initialization needed
    }
    process {
        # No processing needed
    }
    end {
        # No cleanup needed
    }
}
```

## Always Specify the Correct Type for Parameters

- Always declare the most specific and appropriate type for each parameter in function definitions. This improves validation, error handling, and code clarity.
- The type should always be on a new line after all attributes.

**Example:**

```powershell
# Bad
param(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    $Uri
)

# Good
param(
    [Parameter(
        ValueFromPipelineByPropertyName = $true
    )]
    [System.Uri]$Path
)
```

## Prefer PowerShell Commands Over .NET Methods

- Never use a .NET method when an equivalent PowerShell cmdlet or function exists. This ensures better readability, compatibility, and error handling.

**Example:**

```powershell
# Bad
$files = [System.IO.Directory]::GetFiles("C:\Temp")

# Good
$files = Get-ChildItem -Path "C:\Temp" -File
```

## Prefer Switch Statements Over ElseIf Chains

- When handling multiple conditional branches based on the value of a single variable or expression, use a `switch` statement instead of multiple `elseif` statements. This improves readability and maintainability.
- Exceptions can be made for complex conditions where `switch` is not suitable.

**Example:**

```powershell
# Bad
if ($type -eq "json") {
    # handle json
} elseif ($type -eq "xml") {
    # handle xml
} elseif ($type -eq "csv") {
    # handle csv
}

# Good
switch ($type) {
    "json" { # handle json }
    "xml"  { # handle xml }
    "csv"  { # handle csv }
}
```

## Always Add Position = 0 for the First Parameter

- For every function, always specify `Position = 0` in the `[Parameter()]` attribute for the first parameter. This allows the first argument to be passed positionally, improving usability and script clarity.

**Example:**

```powershell
# Bad
param(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$Name
)

# Good
param(
    [Parameter(
        Position = 0,
        ValueFromPipelineByPropertyName = $true
    )]
    [string]$Name
)
```

## Always Include Begin, Process, and End Blocks in Functions

- Every function should include `begin`, `process`, and `end` blocks, even if some blocks are empty. This ensures consistency, makes it easier to add logic later, and supports pipeline input properly.
- If a block is empty, include a comment such as `# No initialization needed` for clarity.

**Example:**

```powershell
# Bad
function Get-Example {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0, 
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$Path
    )
    Write-Output "Path is $Path"
}

# Good
function Get-Example {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0, 
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [string]$Path
    )
    begin {
        Set-StrictMode -Version Latest
        # No initialization needed
    }
    process {
        Write-Output "Path is $Path"
    }
    end {
        # No cleanup needed
    }
}
```

## Always Add Set-StrictMode -Version Latest to the Begin Block

- Every function must include `Set-StrictMode -Version Latest` at the start of the `begin` block, even if the block is otherwise empty. This enforces strict coding practices and helps catch common errors early.

**Example:**

```powershell
# Good
function Get-Example {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0, 
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [string]$Path
    )
    begin {
        Set-StrictMode -Version Latest
        # Initialization code (if needed)
    }
    process {
        Write-Output "Path is $Path"
    }
    end {
        # Cleanup code (if needed)
    }
}
```

## Always Add Alias 'PSPath' for Parameters Named 'Path'

- If a parameter is named `Path`, always add an alias of `PSPath` using the `[Alias()]` attribute. This improves compatibility with common PowerShell conventions.
- This does not apply to `LiteralPath` or other path-like parameters.

**Example:**

```powershell
# Bad
param(
    [Parameter(
        Position = 0, 
        ValueFromPipelineByPropertyName = $true
    )]
    [string]$Path
)

# Good
param(
    [Parameter(
        Position = 0, 
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias('PSPath')]
    [string]$Path
)
```

## Always Place Parameter Attributes on a New Line

- Always put each parameter attribute (such as `[Parameter()]`, `[Alias()]`, `[ValidateSet()]`, etc.) on its own line directly above the parameter declaration.
- The type should always be on a new line after all attributes. This improves readability and consistency.
- The parameter name should be on teh smae line as the type

**Example:**

```powershell
# Bad
param(
    [Parameter(Position = 0, ValueFromPipelineByPropertyName = $true)][Alias('PSPath')][string]
    $Path
)

# Good
param(
    [Parameter(
        Position = 0,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias('PSPath')]
    [string]$Path
)
```

## Always Use PascalCase for Variables Derived from Parameters, and camelCase for Other Variables

- Variables that are directly assigned from function parameters should use PascalCase to match the parameter name and improve clarity.
- All other variables (local, temporary, or internal) should use camelCase for consistency and readability.

**Example:**

```powershell
function Get-UserData {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string]$UserName
    )
    begin {
        Set-StrictMode -Version Latest
        # No initialization needed
    }
    process {
        $UserName = $UserName   # PascalCase for parameter-derived variable
        $userList = Get-UserList # camelCase for local variable
        $resultCount = $userList.Count # camelCase for local variable
        Write-Output "$UserName has $resultCount results."
    }
    end {
        # No cleanup needed
    }
}
```

## Standard Parameter Names and Types

Prefer the following standard parameter names and types in all functions. Always use `[Parameter()]` for each parameter, place each attribute on its own line, and prefer `[string[]]` for multi-path support and `[string]` for single-path. For `Path`, always add `[Alias('PSPath')]`. For `Credential`, always use `[PSCredential]`.

| Parameter Name      | Data Type         | Description                                                                                  |
|---------------------|-------------------|----------------------------------------------------------------------------------------------|
| Accessed            | [switch]          | Operate on resources accessed based on date/time (with Before/After).                        |
| ACL                 | [string]          | Access control level for a catalog or URI.                                                   |
| After               | [datetime]        | Date/time after which the cmdlet was used (with Accessed/Created/Modified).                  |
| Allocation          | [int]             | Number of items to allocate.                                                                 |
| All                 | [switch]          | Act on all resources instead of a default subset.                                            |
| Application         | [string]          | Specify an application.                                                                      |
| Append              | [switch]          | Add content to the end of a resource.                                                        |
| Assembly            | [string]          | Specify an assembly.                                                                         |
| As                  | [string]          | Specify the cmdlet output format (e.g., Text, Script).                                       |
| Attribute           | [string]          | Specify an attribute.                                                                        |
| Before              | [datetime]        | Date/time before which the cmdlet was used (with Accessed/Created/Modified).                 |
| Binary              | [switch]          | Indicate that the cmdlet handles binary values.                                              |
| BlockCount          | [long]            | Specify the block count.                                                                     |
| CaseSensitive       | [switch]          | Require case sensitivity.                                                                    |
| CertFile            | [string]          | File containing a certificate or PKCS #12 file.                                              |
| CertIssuerName      | [string]          | Name or substring of the issuer of a certificate.                                            |
| CertRequestFile     | [string]          | File containing a PKCS #10 certificate request.                                              |
| CertSerialNumber    | [string]          | Serial number issued by the certification authority.                                         |
| CertStoreLocation   | [string]          | Location of the certificate store (typically a file path).                                   |
| CertSubjectName     | [string]          | Subject or substring of a certificate.                                                       |
| CertUsage           | [string]          | Key usage or enhanced key usage.                                                             |
| Class               | [string]          | Specify a .NET Framework class.                                                              |
| Cluster             | [string]          | Specify a cluster.                                                                           |
| Command             | [string]          | Command string to run.                                                                       |
| CompatibleVersion   | [System.Version]  | Version semantics for compatibility.                                                         |
| Compress            | [switch]          | Use data compression.                                                                        |
| CompressionLevel    | [string]          | Algorithm to use for data compression.                                                       |
| Continuous          | [switch]          | Process data until terminated by the user.                                                   |
| Count               | [int]             | Number of objects to be processed.                                                           |
| Created             | [switch]          | Operate on resources created based on date/time (with Before/After).                         |
| Credential          | [PSCredential]    | User credential for authentication.                                                          |
| CSPName             | [string]          | Name of the certificate service provider (CSP).                                              |
| CSPType             | [int]             | Type of CSP.                                                                                 |
| Culture             | [string]          | Culture in which to run the cmdlet.                                                          |
| Data                | [string]          | Specify data.                                                                                |
| Delete              | [switch]          | Delete resources after operation.                                                            |
| Description         | [string]          | Description for a resource.                                                                  |
| Domain              | [string]          | Domain name.                                                                                 |
| Drain               | [switch]          | Process outstanding work items before new data.                                              |
| Drive               | [string]          | Drive name.                                                                                  |
| Encoding            | [string]          | Type of encoding (e.g., ASCII, UTF8, Unicode, etc.).                                         |
| Erase               | [int]             | Number of times a resource is erased before deletion.                                        |
| ErrorLevel          | [int]             | Level of errors to report.                                                                   |
| Event               | [string]          | Event name.                                                                                  |
| Exact               | [switch]          | Resource term must match the resource name exactly.                                          |
| Exclude             | [string]        | Exclude items from an activity.                                                              |
| Filter              | [string]          | Filter for selecting resources.                                                              |
| Follow              | [switch]          | Track progress.                                                                              |
| Force               | [switch]          | Perform an action even if restrictions are encountered.                                      |
| From                | [string]          | Reference object to get information from.                                                    |
| Group               | [string]          | Collection of principals for access.                                                         |
| Id                  | [string]          | Identifier of a resource.                                                                    |
| Include             | [string[]]        | Include items in an activity.                                                                |
| Incremental         | [switch]          | Perform processing incrementally.                                                            |
| Input               | [string]          | Input file specification.                                                                    |
| InputObject         | [object]          | Input from other cmdlets (always use `ValueFromPipeline`).                                   |
| Insert              | [switch]          | Insert an item.                                                                              |
| Interactive         | [switch]          | Work interactively with the user.                                                            |
| Interface           | [string]          | Network interface name.                                                                      |
| Interval            | [hashtable]       | Hashtable of keywords and values.                                                            |
| IpAddress           | [string]          | IP address.                                                                                  |
| Job                 | [string]          | Job.                                                                                         |
| KeyAlgorithm        | [string]          | Key generation algorithm for security.                                                       |
| KeyContainerName    | [string]          | Name of the key container.                                                                   |
| KeyLength           | [int]             | Length of the key in bits.                                                                   |
| LiteralPath         | [string]          | Path to a resource when wildcards are not supported.                                         |
| Location            | [string]          | Location of the resource.                                                                    |
| Log                 | [switch]          | Audit the actions of the cmdlet.                                                             |
| LogName             | [string]          | Name of the log file to process or use.                                                      |
| Mac                 | [string]          | Media access controller (MAC) address.                                                       |
| Modified            | [datetime]        | Operate on resources changed based on date/time (with Before/After).                         |
| Name                | [string]          | Name of the resource.                                                                        |
| NewLine             | [switch]          | Support newline characters when specified.                                                   |
| NoClobber           | [switch]          | Prevent overwriting existing resources.                                                      |
| Notify              | [switch]          | Notify when the activity is complete.                                                        |
| NotifyAddress       | [string]          | E-mail address for notifications.                                                            |
| Operation           | [string]          | Action that can be performed on a protected object.                                          |
| Output              | [string]          | Output file.                                                                                 |
| Overwrite           | [switch]          | Overwrite existing data.                                                                     |
| Owner               | [string]          | Name of the owner of the resource.                                                           |
| ParentId            | [string]          | Parent identifier.                                                                           |
| Path                | [string]        | Resource paths (supports wildcards). Always add `[Alias('PSPath')]`.                         |
| Port                | [int]             | Port number.                                                                                 |
| Printer             | [int], [string]   | Printer (can be integer or string depending on context).                                     |
| Principal           | [string]          | Unique identifiable entity for access.                                                       |
| Privilege           | [string]        | Rights a cmdlet needs to perform an operation for a particular entity.                       |
| Prompt              | [string]          | Prompt for the cmdlet.                                                                       |
| Property            | [string]          | Name or names of the properties to use.                                                      |
| Quiet               | [switch]          | Suppress user feedback.                                                                      |
| Reason              | [string]          | Reason why this cmdlet is being invoked.                                                     |
| Recurse             | [switch]          | Recursively perform actions on resources.                                                    |
| Regex               | [switch]          | Use regular expressions when specified; disables wildcard resolution.                         |
| Repair              | [switch]          | Attempt to correct something from a broken state.                                            |
| RepairString        | [string]          | String to use when the Repair parameter is specified.                                        |
| Retry               | [int]             | Number of times to attempt an action.                                                        |
| Role                | [string]          | Set of operations that can be performed by an entity.                                        |
| SaveCred            | [switch]          | Use previously saved credentials when specified.                                             |
| Scope               | [string]          | Scope to operate on.                                                                         |
| Select              | [string[]]        | Array of the types of items.                                                                 |
| ShortName           | [switch]          | Support short names when specified.                                                          |
| SID                 | [string]          | Unique identifier that represents a principal.                                               |
| Size                | [int]             | Specify a size.                                                                              |
| Speed               | [int]             | Baud rate or speed of the resource.                                                          |
| State               | [string[]]        | Names of states, such as KEYDOWN.                                                            |
| Stream              | [switch]          | Stream multiple output objects through the pipeline.                                         |
| Strict              | [switch]          | Handle all errors as terminating errors.                                                     |
| TempLocation        | [string]          | Location of temporary data used during the operation.                                        |
| TID                 | [string]          | Transaction identifier (TID) for the cmdlet.                                                 |
| Timeout             | [int]             | Timeout interval (in milliseconds).                                                          |
| Truncate            | [switch]          | Truncate actions when specified.                                                             |
| Trusted             | [switch]          | Support trust levels when specified.                                                         |
| TrustLevel          | [string]          | Trust level that is supported (e.g., internet, intranet, fulltrust).                         |
| Type                | [string]          | Type of resource on which to operate.                                                        |
| URL                 | [string]          | Uniform Resource Locator (URL).                                                              |
| User                | [string]          | Specify a user.                                                                              |
| Value               | [object]          | Value to provide to the cmdlet.                                                              |
| Verify              | [switch]          | Test to determine whether an action has occurred.                                            |
| Version             | [string]          | Version of the property.                                                                     |
| Wait                | [switch]          | Wait for user input before continuing.                                                       |
| WaitTime            | [int]             | Duration (in seconds) to wait for user input when the Wait parameter is specified.           |
| Width               | [int]             | Width of the output device.                                                                  |
| Wrap                | [switch]          | Support text wrapping when specified.                                                        |

---

**Example Usage:**

```powershell
param(
    [Parameter(
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias('PSPath')]
    [string]$Path,

    [Parameter(
        ValueFromPipelineByPropertyName = $true
    )]
    [string]$Name,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [PSCredential]$Credential,

    [Parameter()]
    [int]$Count,

    [Parameter()]
    [int]$Port,

    [Parameter()]
    [string]$Printer,

    [Parameter()]
    [switch]$Recurse
)
```

- Always place each attribute on its own line.
- The type should always be on a new line after all attributes.
- Use `[Alias('PSPath')]` for all `Path` parameters.
- Use `[PSCredential]` for `Credential`.
- Use `[string[]]` for multi-path, `[string]` for single-path.
- Use `[int]` for `Count` and `Port`.
- Use `[switch]` for all switch parameters.
- For parameters that can be both `[int]` and `[string]` (like `Printer`), use parameter sets or clarify in documentation.

---

Refer to the [Microsoft Activity Parameters documentation](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/activity-parameters) for more details and additional parameter
