use starknet::ContractAddress;

#[starknet::interface]
trait ITodoListTrait<TContractState> {
    fn add_todo(ref self: TContractState, description: felt252, deadline: u32) -> bool;
    fn update_todo(ref self: TContractState, id: u8, description: felt252, deadline: u32) -> bool;
    fn get_todos(self: @TContractState) -> Array<TodoList::Todo>;
    fn get_todo(ref self: TContractState, id: u8) -> TodoList::Todo;
}

#[starknet::contract]
mod TodoList {
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        todolist: LegacyMap::<u8, Todo>,
        todo_id: u8,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Todo {
        id: u8,
        description: felt252,
        deadline: u32,
        completed: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl TodoList of super::ITodoListTrait<ContractState> {
        fn add_todo(ref self: ContractState, description: felt252, deadline: u32) -> bool {
            self._add_todo(description, deadline);
            true
        }

        fn update_todo(ref self: ContractState, id: u8, description: felt252, deadline: u32) -> bool {
            self._update_todo(id, description, deadline);
            true
        }

        fn get_todos(self: @ContractState) -> Array<Todo> {
            let mut todos = ArrayTrait::new();
            let total_todos = self.todo_id.read();
            let mut i: u8 = 1;
            
            while i <= total_todos {
                let todo = self.todolist.read(i);
                todos.append(todo);
                i += 1;
            };

            todos
        }

        fn get_todo(ref self: ContractState, id: u8) -> Todo {
            self.todolist.read(id)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_owner(ref self: ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn _add_todo(ref self: ContractState, description: felt252, deadline: u32) {
            let id = self.todo_id.read();
            let current_id = id + 1_u8;
            let new_todo = Todo {
                id: current_id,
                description,
                deadline,
                completed: false,
            };
            self.todolist.write(current_id, new_todo);
            self.todo_id.write(current_id);
        }

        fn _update_todo(ref self: ContractState, id: u8, description: felt252, deadline: u32) {
            let todo = self.todolist.read(id);
            let mut todo = todo;
            
            todo.description = description;
            todo.deadline = deadline;
            self.todolist.write(id, todo);
        }
    }
}