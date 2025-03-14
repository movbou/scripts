# ===================================================
# CVisualizer - Advanced C Debugging Visualization
# ===================================================
# A comprehensive GDB script for enhanced C debugging
# Created: 2025-03-14
# Author: GitHub Copilot for movbouthink
# ===================================================

# Load Python extensions for advanced visualization
python
import gdb
import re
import sys
import os
from collections import defaultdict

# =========================== UTILITY FUNCTIONS ===========================

class Color:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

def print_header(text):
    print(f"{Color.HEADER}{Color.BOLD}{'=' * 80}\n{text}\n{'=' * 80}{Color.END}")

def print_subheader(text):
    print(f"{Color.YELLOW}{Color.BOLD}{text}{Color.END}")
    print(f"{Color.YELLOW}{'-' * 50}{Color.END}")

def print_address(addr):
    return f"{Color.CYAN}0x{addr:x}{Color.END}" if isinstance(addr, int) else f"{Color.CYAN}{addr}{Color.END}"

def print_value(value):
    if isinstance(value, int) and not isinstance(value, bool):
        return f"{Color.GREEN}{value}{Color.END} ({Color.BLUE}0x{value:x}{Color.END})"
    else:
        return f"{Color.GREEN}{value}{Color.END}"

def get_pointer_value(ptr_str):
    """Extract numerical pointer value from GDB output"""
    try:
        if isinstance(ptr_str, int):
            return ptr_str
        if ptr_str.startswith("0x"):
            return int(ptr_str, 16)
        match = re.search(r"0x[0-9a-fA-F]+", ptr_str)
        if match:
            return int(match.group(0), 16)
    except (ValueError, AttributeError):
        pass
    return None

# =========================== MEMORY VISUALIZATION ===========================

class MemVisualizer(gdb.Command):
    """Visualize memory regions with different formats"""
    
    def __init__(self):
        super(MemVisualizer, self).__init__("memvis", gdb.COMMAND_DATA)
        
    def invoke(self, arg, from_tty):
        args = gdb.string_to_argv(arg)
        if len(args) < 2:
            print_header("Memory Visualizer Usage")
            print("memvis ADDRESS SIZE [format]")
            print("  formats: hex (default), ascii, int32, int64, float, double")
            return
            
        addr = args[0]
        size = int(args[1])
        fmt = args[2] if len(args) > 2 else "hex"
        
        print_header(f"Memory at {addr} ({size} bytes)")
        
        # Create the appropriate display command based on format
        if fmt == "ascii":
            gdb.execute(f"x/{size}c {addr}")
        elif fmt == "int32":
            gdb.execute(f"x/{size//4}w {addr}")
        elif fmt == "int64":
            gdb.execute(f"x/{size//8}g {addr}")
        elif fmt == "float":
            gdb.execute(f"x/{size//4}f {addr}")
        elif fmt == "double":
            gdb.execute(f"x/{size//8}f {addr}")
        else:  # default to hex
            bytes_per_row = 16
            for i in range(0, size, bytes_per_row):
                row_bytes = min(bytes_per_row, size - i)
                gdb.execute(f"x/{row_bytes}xb {addr}+{i}")

MemVisualizer()

# =========================== STACK VISUALIZATION ===========================

class StackVisualizer(gdb.Command):
    """Visualize the stack with frames and local variables"""

    def __init__(self):
        super(StackVisualizer, self).__init__("stackvis", gdb.COMMAND_STACK)
    
    def invoke(self, arg, from_tty):
        args = gdb.string_to_argv(arg)
        depth = int(args[0]) if args else 5
        
        print_header("Stack Frame Visualization")
        
        # Get current stack pointer
        try:
            sp = int(gdb.parse_and_eval("$sp"))
            print(f"Current SP: {print_address(sp)}")
        except:
            print("Could not determine stack pointer.")
        
        # Display frames
        frames = []
        frame = gdb.selected_frame()
        current_frame_num = 0
        
        while frame and current_frame_num < depth:
            frames.append(frame)
            try:
                frame = frame.older()
                current_frame_num += 1
            except:
                break
        
        for i, frame in enumerate(frames):
            try:
                func_name = frame.function().name
            except:
                func_name = "???"
                
            frame_sp = frame.read_register("sp") if hasattr(frame, "read_register") else "unknown"
            
            print_subheader(f"Frame #{i}: {func_name}")
            print(f"Frame pointer: {print_address(frame_sp)}")
            
            # Print local variables
            print(f"\n{Color.BOLD}Local variables:{Color.END}")
            try:
                block = frame.block()
                for symbol in block:
                    if symbol.is_variable or symbol.is_argument:
                        try:
                            val = symbol.value(frame)
                            print(f"  {symbol.name} = {print_value(val)}")
                        except:
                            print(f"  {symbol.name} = <error reading value>")
            except:
                print("  Error accessing local variables")
            
            print("\n")
            
        print(f"Use 'stackvis {depth+5}' to see more frames.")

StackVisualizer()

# =========================== HEAP VISUALIZATION ===========================

class HeapVisualizer(gdb.Command):
    """Visualize heap allocations in the program"""

    def __init__(self):
        super(HeapVisualizer, self).__init__("heapvis", gdb.COMMAND_DATA)
        
    def invoke(self, arg, from_tty):
        args = gdb.string_to_argv(arg)
        
        print_header("Heap Analysis")
        
        # Try to read malloc arena information
        print_subheader("Active Heap Allocations")
        
        try:
            # This approach uses gdb's built-in malloc-history feature if enabled
            gdb.execute("info malloc")
        except:
            print("Could not access malloc information. Try one of these:")
            print("1. Run with environment: MALLOC_CHECK_=3 ./your_program")
            print("2. Link with -lmcheck")
            print("3. Use 'set env LD_PRELOAD=/lib/libmcheck.so'")
            
        # Try to show heap metadata
        print_subheader("Heap Chunks")
        try:
            gdb.execute("maintenance info heap")
        except:
            print("Heap chunk information not available.")
        
        # Note on alternative approaches
        print("\nFor more detailed heap analysis, you can use:")
        print("1. heapshow ADDR - to examine a specific heap block")
        print("2. heapleak - to check for potential memory leaks")

HeapVisualizer()

# Heap block inspector
class HeapBlockInspector(gdb.Command):
    """Analyze a specific heap block"""

    def __init__(self):
        super(HeapBlockInspector, self).__init__("heapshow", gdb.COMMAND_DATA)
        
    def invoke(self, arg, from_tty):
        args = gdb.string_to_argv(arg)
        if not args:
            print("Usage: heapshow ADDRESS")
            return
            
        addr = args[0]
        print_header(f"Heap Block Analysis: {addr}")
        
        try:
            # Display memory around the block
            print_subheader("Block Memory")
            gdb.execute(f"x/32xb {addr}-16")
        except:
            print("Failed to examine memory")

HeapBlockInspector()

# =========================== POINTER CHAIN VISUALIZER ===========================

class PointerChainVisualizer(gdb.Command):
    """Visualize a chain of pointers starting from a given address"""

    def __init__(self):
        super(PointerChainVisualizer, self).__init__("ptrchain", gdb.COMMAND_DATA)
        
    def invoke(self, arg, from_tty):
        args = gdb.string_to_argv(arg)
        if not args:
            print("Usage: ptrchain POINTER_VARIABLE/ADDRESS [max_depth]")
            return
            
        pointer = args[0]
        max_depth = int(args[1]) if len(args) > 1 else 10
        
        print_header(f"Pointer Chain Starting From: {pointer}")
        
        # Start tracing the pointer chain
        current_ptr = pointer
        visited = set()
        depth = 0
        
        while depth < max_depth:
            try:
                # Get pointer value
                ptr_val = gdb.parse_and_eval(current_ptr)
                ptr_addr = get_pointer_value(str(ptr_val))
                
                if ptr_addr is None or ptr_addr == 0:
                    print(f"{' ' * depth}→ {Color.RED}NULL{Color.END}")
                    break
                    
                print(f"{' ' * depth}→ {print_address(ptr_addr)}")
                
                if ptr_addr in visited:
                    print(f"{' ' * (depth+2)}{Color.RED}CIRCULAR REFERENCE DETECTED!{Color.END}")
                    break
                    
                visited.add(ptr_addr)
                
                # Try to dereference this pointer to get the next in chain
                current_ptr = f"*(void**)({ptr_addr})"
                depth += 1
                
            except Exception as e:
                print(f"{' ' * (depth+2)}{Color.RED}Error: {str(e)}{Color.END}")
                break

PointerChainVisualizer()

# =========================== LINKED LIST VISUALIZER ===========================

class LinkedListVisualizer(gdb.Command):
    """Visualize a linked list structure"""

    def __init__(self):
        super(LinkedListVisualizer, self).__init__("listvis", gdb.COMMAND_DATA)
        
    def invoke(self, arg, from_tty):
        args = gdb.string_to_argv(arg)
        if len(args) < 2:
            print("Usage: listvis HEAD_POINTER NEXT_FIELD [max_nodes] [data_fields...]")
            print("Example: listvis my_list next 10 data key value")
            return
            
        head_ptr = args[0]
        next_field = args[1]
        max_nodes = int(args[2]) if len(args) > 2 else 20
        data_fields = args[3:] if len(args) > 3 else ["data"]
        
        print_header(f"Linked List Visualization: {head_ptr}")
        
        try:
            current = gdb.parse_and_eval(head_ptr)
            node_count = 0
            visited = set()
            
            while current and str(current) != "0x0" and node_count < max_nodes:
                # Get node address
                addr = get_pointer_value(str(current))
                if addr is None:
                    print(f"{Color.RED}Invalid pointer: {current}{Color.END}")
                    break
                    
                node_display = f"Node {node_count} @ {print_address(addr)}"
                print_subheader(node_display)
                
                # Display data fields
                for field in data_fields:
                    try:
                        value = current[field]
                        print(f"  {field}: {print_value(value)}")
                    except:
                        print(f"  {field}: <error accessing field>")
                        
                # Get next node
                try:
                    next_node = current[next_field]
                    next_addr = get_pointer_value(str(next_node))
                    
                    if next_addr in visited:
                        print(f"\n{Color.RED}Circular list detected!{Color.END}")
                        break
                        
                    print(f"\n  {next_field} → {print_address(next_addr)}")
                    
                    if str(next_node) == "0x0":
                        print(f"  {Color.BLUE}End of list{Color.END}")
                        break
                        
                    visited.add(next_addr)
                    current = next_node
                    
                except Exception as e:
                    print(f"\n  {Color.RED}Error accessing next node: {str(e)}{Color.END}")
                    break
                    
                node_count += 1
                print("")
                
            if node_count >= max_nodes:
                print(f"{Color.YELLOW}Reached maximum node count ({max_nodes}). Use a larger value to see more nodes.{Color.END}")
                
        except Exception as e:
            print(f"{Color.RED}Error: {str(e)}{Color.END}")

LinkedListVisualizer()

# =========================== TREE VISUALIZER ===========================

class TreeVisualizer(gdb.Command):
    """Visualize a binary tree structure"""

    def __init__(self):
        super(TreeVisualizer, self).__init__("treevis", gdb.COMMAND_DATA)
        
    def invoke(self, arg, from_tty):
        args = gdb.string_to_argv(arg)
        if len(args) < 3:
            print("Usage: treevis ROOT_POINTER LEFT_FIELD RIGHT_FIELD [max_depth] [key_field]")
            print("Example: treevis tree->root left right 5 key")
            return
            
        root_ptr = args[0]
        left_field = args[1]
        right_field = args[2]
        max_depth = int(args[3]) if len(args) > 3 else 5
        key_field = args[4] if len(args) > 4 else "key"
        
        print_header(f"Binary Tree Visualization: {root_ptr}")
        
        def print_tree(node, depth, path):
            if depth > max_depth or node is None or str(node) == "0x0":
                return
                
            # Print current node
            indent = "│   " * (depth - 1)
            branch = "└── " if path.endswith("R") else "├── " if path else ""
            
            try:
                addr = get_pointer_value(str(node))
                if addr is None:
                    print(f"{indent}{branch}{Color.RED}Invalid pointer{Color.END}")
                    return
                
                try:
                    key_val = node[key_field]
                    print(f"{indent}{branch}Node @ {print_address(addr)} [Key: {print_value(key_val)}]")
                except:
                    print(f"{indent}{branch}Node @ {print_address(addr)}")
                
                # Process children
                try:
                    left = node[left_field]
                    if left and str(left) != "0x0":
                        print_tree(left, depth + 1, path + "L")
                    else:
                        print(f"{indent}│   └── {Color.BLUE}NULL{Color.END}")
                except Exception as e:
                    print(f"{indent}│   └── {Color.RED}Error: {str(e)}{Color.END}")
                
                try:
                    right = node[right_field]
                    if right and str(right) != "0x0":
                        print_tree(right, depth + 1, path + "R")
                    else:
                        print(f"{indent}    └── {Color.BLUE}NULL{Color.END}")
                except Exception as e:
                    print(f"{indent}    └── {Color.RED}Error: {str(e)}{Color.END}")
                    
            except Exception as e:
                print(f"{indent}{branch}{Color.RED}Error: {str(e)}{Color.END}")
        
        try:
            root = gdb.parse_and_eval(root_ptr)
            print_tree(root, 1, "")
            print(f"\n{Color.YELLOW}Max depth: {max_depth}. Use a larger value to see more levels.{Color.END}")
        except Exception as e:
            print(f"{Color.RED}Error: {str(e)}{Color.END}")

TreeVisualizer()

# =========================== DATA STRUCTURE VISUALIZER ===========================

class DataStructureVisualizer(gdb.Command):
    """Visualize complex data structures like structs and arrays"""

    def __init__(self):
        super(DataStructureVisualizer, self).__init__("structvis", gdb.COMMAND_DATA)
        
    def invoke(self, arg, from_tty):
        args = gdb.string_to_argv(arg)
        if not args:
            print("Usage: structvis VARIABLE [max_depth]")
            return
            
        var_name = args[0]
        max_depth = int(args[1]) if len(args) > 1 else 3
        
        print_header(f"Data Structure: {var_name}")
        
        def explore_struct(val, prefix="", depth=0, visited=None):
            if visited is None:
                visited = set()
                
            if depth > max_depth:
                print(f"{prefix}... (max depth reached)")
                return
            
            try:
                # Handle different types
                type_str = str(val.type)
                
                # Handle pointers
                if "*" in type_str:
                    if val == 0 or str(val) == "0x0":
                        print(f"{prefix}{Color.BLUE}NULL{Color.END}")
                        return
                    
                    addr = get_pointer_value(str(val))
                    if addr in visited:
                        print(f"{prefix}{print_address(addr)} {Color.YELLOW}(already visited){Color.END}")
                        return
                    
                    if addr is not None:
                        visited.add(addr)
                    
                    try:
                        deref_val = val.dereference()
                        print(f"{prefix}{type_str} @ {print_address(addr)}")
                        explore_struct(deref_val, prefix + "  ", depth + 1, visited)
                    except:
                        print(f"{prefix}{type_str} @ {print_address(addr)} {Color.RED}(cannot dereference){Color.END}")
                    
                # Handle structs and classes
                elif val.type.code == gdb.TYPE_CODE_STRUCT:
                    for field in val.type.fields():
                        field_name = field.name
                        if not field_name:  # Anonymous field/union
                            continue
                            
                        try:
                            field_val = val[field_name]
                            print(f"{prefix}{field_name}: ", end="")
                            explore_struct(field_val, prefix + "  ", depth + 1, visited)
                        except:
                            print(f"{prefix}{field_name}: {Color.RED}<error accessing field>{Color.END}")
                
                # Handle arrays
                elif val.type.code == gdb.TYPE_CODE_ARRAY:
                    array_len = val.type.range()[1] + 1  # Upper bound + 1
                    print(f"{prefix}Array of {array_len} elements:")
                    
                    # Print up to 10 elements
                    display_count = min(array_len, 10)
                    for i in range(display_count):
                        try:
                            print(f"{prefix}  [{i}]: ", end="")
                            explore_struct(val[i], prefix + "    ", depth + 1, visited)
                        except:
                            print(f"{prefix}  [{i}]: {Color.RED}<error accessing element>{Color.END}")
                            
                    if array_len > display_count:
                        print(f"{prefix}  ... {array_len - display_count} more elements ...")
                
                # Handle basic types
                else:
                    print(f"{print_value(val)}")
                    
            except Exception as e:
                print(f"{Color.RED}Error exploring structure: {str(e)}{Color.END}")
        
        try:
            var = gdb.parse_and_eval(var_name)
            explore_struct(var)
        except Exception as e:
            print(f"{Color.RED}Error: {str(e)}{Color.END}")

DataStructureVisualizer()

# =========================== MEMORY MAP VISUALIZER ===========================

class MemoryMapVisualizer(gdb.Command):
    """Visualize process memory map with regions"""

    def __init__(self):
        super(MemoryMapVisualizer, self).__init__("memmap", gdb.COMMAND_DATA)
        
    def invoke(self, arg, from_tty):
        print_header("Process Memory Map")
        
        try:
            gdb.execute("maintenance info sections")
            print("\nDetailed memory map:")
            gdb.execute("info proc mappings")
        except:
            print("Could not access memory mapping information.")

MemoryMapVisualizer()

# Register all commands
MemVisualizer()
StackVisualizer()
HeapVisualizer()
HeapBlockInspector()
PointerChainVisualizer()
LinkedListVisualizer()
TreeVisualizer()
DataStructureVisualizer()
MemoryMapVisualizer()

# =========================== HELP FUNCTION ===========================

class CVisualizerHelp(gdb.Command):
    """Display help for C Visualizer commands"""

    def __init__(self):
        super(CVisualizerHelp, self).__init__("cvishelp", gdb.COMMAND_SUPPORT)
        
    def invoke(self, arg, from_tty):
        print_header("CVisualizer Help")
        
        commands = [
            ("stackvis [depth]", "Visualize the program stack with frames and variables"),
            ("heapvis", "Analyze heap allocations and memory blocks"),
            ("heapshow ADDRESS", "Examine specific heap memory block"),
            ("memvis ADDRESS SIZE [format]", "Visualize memory in different formats"),
            ("ptrchain POINTER [max_depth]", "Follow and visualize a chain of pointers"),
            ("listvis HEAD NEXT_FIELD [max] [fields...]", "Visualize a linked list structure"),
            ("treevis ROOT LEFT RIGHT [max] [key]", "Visualize a binary tree structure"),
            ("structvis VARIABLE [max_depth]", "Visualize complex data structures recursively"),
            ("memmap", "Display process memory map with regions")
        ]
        
        for cmd, desc in commands:
            print(f"{Color.BOLD}{Color.GREEN}{cmd}{Color.END}")
            print(f"  {desc}\n")
            
        print_subheader("Examples")
        print("stackvis 10                         # Show 10 stack frames")
        print("listvis my_list next 5 data key     # Show linked list with data and key fields")
        print("ptrchain ptr 5                      # Follow pointer chain 5 levels deep")
        print("heapshow 0x55555576a2a0             # Examine heap block at this address")
        print("structvis my_complex_struct 2       # Visualize structure to depth 2")
        print("treevis tree_root left right 3 key  # Visualize a binary tree 3 levels deep")
        print("memvis buffer 64 ascii              # Show 64 bytes as ASCII text")

CVisualizerHelp()

end

# =========================== MAIN CONFIGURATION ===========================

# Set better defaults for debugging
set print pretty on
set print array on
set print array-indexes on
set print elements 100
set print frame-arguments all
set pagination off

# Create convenience functions
define xxd
    dump binary memory /tmp/gdb_xxd_dump.bin $arg0 $arg0+$arg1
    shell xxd /tmp/gdb_xxd_dump.bin
end

define hexdump
    xxd $arg0 $arg1
end

# Welcome message
python
print_header("CVisualizer - Advanced C Debugging Visualization")
print("Type 'cvishelp' for available commands")
end