# CVisualizer - Advanced C Debugging Toolkit
**Manual & User Guide**

*Created: 2025-03-14*

## Table of Contents
1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Command Reference](#command-reference)
   - [Stack Visualization](#stack-visualization)
   - [Heap Analysis](#heap-analysis)
   - [Memory Visualization](#memory-visualization)
   - [Pointer Chain Visualization](#pointer-chain-visualization)
   - [Linked List Visualization](#linked-list-visualization)
   - [Tree Visualization](#tree-visualization)
   - [Data Structure Visualization](#data-structure-visualization)
   - [Memory Map Visualization](#memory-map-visualization)
4. [Customization](#customization)
5. [Troubleshooting](#troubleshooting)
6. [Examples](#examples)

## Installation

### Prerequisites
- GDB 7.0 or higher
- Python support in GDB (most modern versions have this)
- A terminal that supports ANSI color codes

### Setup
1. Place both script files in a convenient location:
   - `cvisualizer.gdb` - Main script with visualization commands
   - `gdb_printers.py` - Additional pretty printers

2. **Method 1**: Load manually each time
   ```
   (gdb) source /path/to/cvisualizer.gdb
   ```

3. **Method 2**: Auto-load for all GDB sessions
   ```bash
   # Add to your ~/.gdbinit file
   echo "source /path/to/cvisualizer.gdb" >> ~/.gdbinit
   ```

4. **Method 3**: Project-specific loading
   ```bash
   # Create a .gdbinit file in your project directory
   echo "source /path/to/cvisualizer.gdb" > .gdbinit
   ```

5. Verify installation:
   ```
   (gdb) cvishelp
   ```
   You should see the help menu with available commands.

## Quick Start

1. Start GDB with your program:
   ```bash
   gdb ./your_program
   ```

2. If not auto-loaded, source the script:
   ```
   (gdb) source /path/to/cvisualizer.gdb
   ```

3. Run your program to a breakpoint:
   ```
   (gdb) start
   # or
   (gdb) break main
   (gdb) run
   ```

4. Use visualization commands:
   ```
   (gdb) stackvis        # Visualize the stack
   (gdb) heapvis         # Analyze the heap
   (gdb) structvis var   # Visualize a complex structure
   ```

## Command Reference

### Stack Visualization

**Command**: `stackvis [depth]`

Displays the current stack frames with local variables in a colorful, structured format.

**Parameters**:
- `depth`: Number of stack frames to display (default: 5)

**Example**:
```
(gdb) stackvis 8        # Show 8 stack frames
```

**Features**:
- Stack pointer address display
- Function names for each frame
- Local variables with values and addresses
- Color coding for different elements

### Heap Analysis

**Command**: `heapvis`

Provides overview of heap allocations and memory blocks.

**Example**:
```
(gdb) heapvis
```

**Features**:
- Displays active heap allocations
- Shows heap metadata when available
- Links to more specific heap inspection tools

**Command**: `heapshow ADDRESS`

Examines a specific heap memory block in detail.

**Parameters**:
- `ADDRESS`: Memory address of heap block to examine

**Example**:
```
(gdb) heapshow 0x55555576a2a0
```

### Memory Visualization

**Command**: `memvis ADDRESS SIZE [format]`

Visualizes memory regions with different display formats.

**Parameters**:
- `ADDRESS`: Starting address to display
- `SIZE`: Number of bytes to display
- `format`: Display format (hex, ascii, int32, int64, float, double)

**Example**:
```
(gdb) memvis buffer 64 hex      # Show 64 bytes in hex format
(gdb) memvis buffer 32 ascii    # Show 32 bytes as ASCII characters
```

**Features**:
- Multiple display formats
- Organized byte layout
- Address annotations

### Pointer Chain Visualization

**Command**: `ptrchain POINTER [max_depth]`

Follows and visualizes a chain of pointers starting from a given address.

**Parameters**:
- `POINTER`: Starting pointer variable or address
- `max_depth`: Maximum depth to follow pointers (default: 10)

**Example**:
```
(gdb) ptrchain head 5          # Follow pointer chain from 'head' 5 levels deep
```

**Features**:
- Detects circular references
- Shows pointer addresses with colors
- Clear indentation showing the chain hierarchy

### Linked List Visualization

**Command**: `listvis HEAD_POINTER NEXT_FIELD [max_nodes] [data_fields...]`

Visualizes a linked list structure with customizable field display.

**Parameters**:
- `HEAD_POINTER`: Variable or address of list head
- `NEXT_FIELD`: Name of the field that points to next node
- `max_nodes`: Maximum number of nodes to display (default: 20)
- `data_fields`: List of fields to display for each node (default: "data")

**Example**:
```
(gdb) listvis my_list next 10 data key value
```

**Features**:
- Detects circular lists
- Shows node addresses and content
- Customizable field display
- Limited to prevent excessive output

### Tree Visualization

**Command**: `treevis ROOT_POINTER LEFT_FIELD RIGHT_FIELD [max_depth] [key_field]`

Visualizes a binary tree structure with customizable layout.

**Parameters**:
- `ROOT_POINTER`: Variable or address of tree root
- `LEFT_FIELD`: Name of the field pointing to left child
- `RIGHT_FIELD`: Name of the field pointing to right child
- `max_depth`: Maximum depth to display (default: 5)
- `key_field`: Field to use as node key (default: "key")

**Example**:
```
(gdb) treevis tree_root left right 3 value
```

**Features**:
- Tree-like ASCII art representation
- Shows node addresses and keys
- Customizable traversal depth
- Handles NULL branches gracefully

### Data Structure Visualization

**Command**: `structvis VARIABLE [max_depth]`

Recursively visualizes complex data structures like structs, unions, and arrays.

**Parameters**:
- `VARIABLE`: Variable name or address to visualize
- `max_depth`: Maximum recursion depth (default: 3)

**Example**:
```
(gdb) structvis my_config 2
```

**Features**:
- Recursive structure traversal
- Handles pointers, arrays, structs
- Detects circular references
- Limits depth to prevent excessive recursion

### Memory Map Visualization

**Command**: `memmap`

Displays the process memory map with regions and permissions.

**Example**:
```
(gdb) memmap
```

**Features**:
- Shows memory sections and their permissions
- Displays libraries and mapped files
- Helps identify memory regions (stack, heap, code, etc.)

## Customization

### Modifying Color Scheme

You can modify the colors used in the script by editing the `Color` class in `cvisualizer.gdb`:

```python
class Color:
    HEADER = '\033[95m'   # Purple
    BLUE = '\033[94m'     # Blue
    CYAN = '\033[96m'     # Cyan
    GREEN = '\033[92m'    # Green
    YELLOW = '\033[93m'   # Yellow
    RED = '\033[91m'      # Red
    BOLD = '\033[1m'      # Bold
    UNDERLINE = '\033[4m' # Underline
    END = '\033[0m'       # Reset
```

### Adding New Pretty Printers

To add support for custom data structures, edit the `gdb_printers.py` file and add new printer classes following the existing patterns.

## Troubleshooting

### Common Issues

1. **No colors in output**
   - Make sure your terminal supports ANSI color codes
   - Try running `export TERM=xterm-color` before starting GDB

2. **Python errors when loading script**
   - Verify your GDB has Python support: `gdb --config`
   - Check Python version compatibility: `python --version`

3. **"Undefined command" errors**
   - Make sure the script was properly sourced
   - Check for Python errors during loading

4. **Memory access errors**
   - Some commands may fail with invalid memory addresses
   - Ensure pointers are valid before visualization

### Debug Mode

To enable debug output for the script itself:

```
(gdb) set python print-stack full
```

## Examples

### Example 1: Debugging a Linked List

```c
// Program with a linked list
typedef struct node {
    int data;
    struct node *next;
} Node;

Node *create_list(int n) {
    // Creates a list with n nodes
}

int main() {
    Node *head = create_list(10);
    // ...
}
```

Debugging session:

```
(gdb) break main
(gdb) run
(gdb) next
... (after head is created)
(gdb) listvis head next 5 data
```

### Example 2: Analyzing a Binary Tree

```c
// Program with a binary tree
typedef struct tree_node {
    int key;
    void *value;
    struct tree_node *left;
    struct tree_node *right;
} TreeNode;

int main() {
    TreeNode *root = build_tree();
    // ...
}
```

Debugging session:

```
(gdb) break after_tree_built
(gdb) run
(gdb) treevis root left right 3 key
```

### Example 3: Complex Structure Analysis

```c
// Program with complex structures
typedef struct config {
    char name[64];
    int values[10];
    struct {
        int x, y, z;
    } coordinates;
    void *extra_data;
} Config;

int main() {
    Config my_config = {...};
    // ...
}
```

Debugging session:

```
(gdb) break main
(gdb) run
(gdb) structvis my_config
```

### Example 4: Stack and Memory Analysis

For any program with function calls:

```
(gdb) break some_function
(gdb) run
(gdb) stackvis
(gdb) memmap
```

---

For additional help on any command, use the built-in help system:

```
(gdb) cvishelp
```

This will display a summary of all available commands with brief usage instructions.