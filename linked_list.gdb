# Function to print the entire linked list
define print_list
    set $node = $arg0
    while ($node != 0)
        printf "Node: %p, Data: %d, Next: %p\n", $node, ((struct Node*)$node)->data, ((struct Node*)$node)->next
        set $node = ((struct Node*)$node)->next
    end
end

# Function to get the length of the linked list
define list_length
    set $node = $arg0
    set $count = 0
    while ($node != 0)
        set $count = $count + 1
        set $node = ((struct Node*)$node)->next
    end
    printf "List length: %d\n", $count
end

# Function to print the Nth node in the linked list (0-based index)
define print_nth_node
    set $node = $arg0
    set $n = $arg1
    set $i = 0
    while ($node != 0 && $i < $n)
        set $node = ((struct Node*)$node)->next
        set $i = $i + 1
    end
    if ($node != 0)
        printf "Node[%d]: %p, Data: %d, Next: %p\n", $n, $node, ((struct Node*)$node)->data, ((struct Node*)$node)->next
    else
        printf "Error: Index %d out of bounds\n", $n
    end
end

# Function to print the last node in the linked list
define print_last_node
    set $node = $arg0
    if ($node == 0)
        printf "Error: List is empty\n"
        return
    end
    while (((struct Node*)$node)->next != 0)
        set $node = ((struct Node*)$node)->next
    end
    printf "Last Node: %p, Data: %d, Next: %p\n", $node, ((struct Node*)$node)->data, ((struct Node*)$node)->next
end

# Function to check if a linked list is cyclic (detect loops)
define check_cycle
    set $slow = $arg0
    set $fast = $arg0
    while ($fast != 0 && ((struct Node*)$fast)->next != 0)
        set $slow = ((struct Node*)$slow)->next
        set $fast = ((struct Node*)$fast)->next
        set $fast = ((struct Node*)$fast)->next
        if ($slow == $fast)
            printf "Cycle detected at node: %p\n", $slow
            return
        end
    end
    printf "No cycle detected\n"
end

