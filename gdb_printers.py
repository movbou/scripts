# GDB Pretty Printers
# Additional pretty printers for common C data structures

import gdb
import re
from collections import namedtuple

class LinkedListPrinter:
    """Print a linked list structure"""

    def __init__(self, val, next_field='next'):
        self.val = val
        self.next_field = next_field
        self.count = 0
        self.limit = 20  # Maximum number of elements to print

    def display_hint(self):
        return 'array'

    def to_string(self):
        return f"Linked list with {self.count} nodes"

    def children(self):
        current = self.val
        i = 0
        while current and i < self.limit:
            yield (f"[{i}]", current)
            
            # Move to next node if possible
            try:
                if not current or current[self.next_field] == 0:
                    break
                current = current[self.next_field]
            except:
                break
                
            i += 1
            self.count += 1
            
        if current and current[self.next_field] != 0:
            yield (f"...", "...")

class BinaryTreeNodePrinter:
    """Print a binary tree node with its children"""
    
    def __init__(self, val, left_field='left', right_field='right', key_field='key'):
        self.val = val
        self.left_field = left_field
        self.right_field = right_field
        self.key_field = key_field
        self.visited = set()
        
    def to_string(self):
        try:
            key_val = self.val[self.key_field]
            return f"TreeNode(key={key_val})"
        except:
            return "TreeNode"
            
    def children(self):
        # Check for null or already visited to avoid recursion
        if not self.val:
            return
            
        try:
            # Add address to visited set
            addr = int(self.val.address)
            if addr in self.visited:
                yield ("circular", "...")
                return
                
            self.visited.add(addr)
            
            # Yield key field
            try:
                yield (self.key_field, self.val[self.key_field])
            except:
                pass
                
            # Left child
            try:
                if self.val[self.left_field]:
                    yield ("left", self.val[self.left_field])
            except:
                yield ("left", "error")
            
            # Right child
            try:
                if self.val[self.right_field]:
                    yield ("right", self.val[self.right_field])
            except:
                yield ("right", "error")
                
        except:
            yield ("error", "Cannot access tree node")

class HashMapPrinter:
    """Print a hash map / hash table structure (simplified)"""
    
    def __init__(self, val, buckets_field='buckets', size_field='size', capacity_field='capacity'):
        self.val = val
        self.buckets_field = buckets_field
        self.size_field = size_field
        self.capacity_field = capacity_field
    
    def to_string(self):
        try:
            size = int(self.val[self.size_field])
            capacity = int(self.val[self.capacity_field])
            return f"HashMap(size={size}, capacity={capacity})"
        except:
            return "HashMap"
    
    def children(self):
        try:
            buckets = self.val[self.buckets_field]
            capacity = int(self.val[self.capacity_field])
            
            # Show only non-empty buckets, up to a limit
            count = 0
            limit = min(capacity, 20)
            
            for i in range(capacity):
                if count >= limit:
                    break
                    
                bucket = buckets[i]
                if bucket:
                    yield (f"bucket[{i}]", bucket)
                    count += 1
                    
            if count >= limit and count < capacity:
                yield ("...", "...")
                
        except Exception as e:
            yield ("error", str(e))

def register_printers():
    # This function would be used to register printers for specific types
    # For now, we'll leave this as a placeholder
    pass

# Initialize printers
register_printers()