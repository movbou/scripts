# Function to print the entire linked list
define print_list
    set $t_list = $arg0
    while ($t_list != 0)
        printf "Node: %p, Data: %d, Next: %p\n", $t_list, ((t_list*)$t_list)->content, ((t_list*)$t_list)->next
        set $t_list = ((t_list*)$t_list)->next
    end
end

# Function to get the length of the linked list
define list_length
    set $t_list = $arg0
    set $count = 0
    while ($t_list != 0)
        set $count = $count + 1
        set $t_list = ((struct Node*)$t_list)->next
    end
    printf "List length: %d\n", $count
end

# Function to print the Nth t_list in the linked list (0-based index)
define print_nth_node
    set $t_list = $arg0
    set $n = $arg1
    set $i = 0
    while ($t_list != 0 && $i < $n)
        set $t_list = ((struct Node*)$t_list)->next
        set $i = $i + 1
    end
    if ($t_list != 0)
        printf "Node[%d]: %p, Data: %d, Next: %p\n", $n, $t_list, ((struct Node*)$t_list)->content, ((struct Node*)$t_list)->next
    else
        printf "Error: Index %d out of bounds\n", $n
    end
end

# Function to print the last t_list in the linked list
define print_last_node
    set $t_list = $arg0
    if ($t_list == 0)
        printf "Error: List is empty\n"
        return
    end
    while (((struct Node*)$t_list)->next != 0)
        set $t_list = ((struct Node*)$t_list)->next
    end
    printf "Last Node: %p, Data: %d, Next: %p\n", $t_list, ((struct Node*)$t_list)->content, ((struct Node*)$t_list)->next
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
            printf "Cycle detected at t_list: %p\n", $slow
            return
        end
    end
    printf "No cycle detected\n"
end

