import from uuid { uuid4 }
import from datetime { datetime, timedelta, date }
import from byllm.lib { Model }
import from typing { Any }
import from json { loads, JSONDecodeError }
cl import "./styles.css";

glob llm = Model(model_name="gemini/gemini-2.5-flash");

node Todo {
    has id: str,
        title: str,
        done: bool = False,
        completion_time: int = 10, # in minutes
        deadline: date = date.today() + timedelta(days=1);
}

obj TodoItem {
    has id: str,
        title: str,
        done: bool,
        completion_time: int,
        deadline: str;
}


"""Add a todo"""
def:pub add_todo(title: str, completion_time: int = 10, deadline: str = "2025-02-10") -> dict {
    due = datetime.strptime(deadline, "%Y-%m-%d").date();
    todo = root ++> Todo(id=str(uuid4()), title=title, completion_time=completion_time, deadline=due);
    return {
        "id": todo[0].id, "title": todo[0].title,
        "done": todo[0].done,
        "completion_time": todo[0].completion_time,
        "deadline": todo[0].deadline,
    };
}

"""Get all todos."""
def:pub get_todos -> list {
    return [
        {"id": t.id, "title": t.title, "done": t.done, "completion_time": t.completion_time, "deadline": t.deadline}
        for t in [root-->](?:Todo)
    ];
}

"""Toggle a todo's done status."""
def:pub toggle_todo(id: str) -> dict {
    for todo in [root-->](?:Todo) {
        if todo.id == id {
            todo.done = not todo.done;
            return {
                "id": todo.id, "title": todo.title,
                "done": todo.done,
                "completion_time": todo.completion_time,
                "deadline": todo.deadline,
            };
        }
    }
    return {};
}

"""Delete a todo."""
def:pub delete_todo(id: str) -> dict {
    for todo in [root-->](?:Todo) {
        if todo.id == id {
            del todo;
            return {"deleted": id};
        }
    }
    return {};
}

"""Generate an action plan"""
def:pub generate_action_plan(tasks: list, focus_minutes: int) -> list {
    try {
        # We explicitly pass the context to the prompt mechanism
        planned_items = generate_action_plan_inner(tasks, focus_minutes);
        return [
            {"id": t.id, "title": t.title, "done": t.done, "completion_time": t.completion_time, "deadline": t.deadline} 
            for t in planned_items
        ];
    } except Exception as e {
        print("LLM ERROR:", e);
        return [];
    }
}

def:pub generate_action_plan_inner(tasks: list[TodoItem], focus_minutes: int) -> list[TodoItem] by llm();

cl def:pub app -> Any {
    has items: list = [],
        text: str = "",
        time: int = None,
        due: str = "",
        focus_minutes: int = None,
        plan: list = [];

    async can with entry {
        items = await get_todos();
    }

    async def add -> None {
        if text.trim() {
            todo = await add_todo(text.trim(), time,  due);
            items = items.concat([todo]);
            text = "";
        }
    }

    async def toggle(id: str) -> None {
        await toggle_todo(id);
        items = [
            (
                {
                    "id": t.id, "title": t.title,
                    "done": not t.done,
                    "completion_time": t.completion_time,
                    "deadline": t.deadline
                }
                if t.id == id else t
            )
            for t in items
        ];
    }

    async def remove(id: str) -> None {
        await delete_todo(id);
        items = items.filter(lambda t: Any -> bool { return t.id != id; });
    }

    async def generate_plan() -> list {
        uncompleted = items.filter(lambda t: Any -> bool { return not t.done; });
        plan = await generate_action_plan(uncompleted, focus_minutes);
    }

    remaining = items.filter(lambda t: Any -> bool { return not t.done; }).length;

    return
        <div class="container">
            <h1>AI Todo App</h1>
            <div class="input-row">
                <input
                    class="input"
                    value={text}
                    onChange={lambda e: Any -> None { text = e.target.value; }}
                    onKeyPress={lambda e: Any -> None {
                        if e.key == "Enter" { 
                            add(); 
                        }
                    }}
                    placeholder="What needs to be done?"
                />
                <input
                    type = "number"
                    class="input"
                    value={time}
                    onChange={lambda e: Any -> None { time = e.target.value; }}
                    placeholder="Mins"
                />
                <input
                    type = "date"
                    class="input"
                    value={due}
                    onChange={lambda e: Any -> None { due = e.target.value; }}
                    placeholder="Mins"
                />
                <button class="btn-add" onClick={add}>Add</button>
            </div>
        
            <div style={{"padding": "10px", "background": "#f0f0f0", "margin": "10px 0"}}>
                <h3>Focus Planner</h3>
                <input 
                    type="number" 
                    value={focus_minutes} 
                    onChange={lambda e: Any -> None { focus_minutes = e.target.value; }} 
                    placeholder="Mins to focus"
                />
                <button onClick={generate_plan}>Generate Plan</button>
                <ol>
                    {[ 
                        <li>{t["title"]} ({t["completion_time"]}m)</li> for t in plan 
                    ]}
                </ol>
            </div>
            {[
                <div key={t.id} class="todo-item">
                    <input
                        type="checkbox"
                        checked={t.done}
                        onChange={lambda -> None { toggle(t.id); }}
                    />
                    <span class={"todo-title " + ("todo-done" if t.done else "")}>
                        {t.title}
                    </span>
                    <span class="todo-meta">
                        Time: {t.completion_time}m
                        {(" | Due: " + t.deadline) if t.deadline else ""}
                    </span>
                    <button
                        class="btn-delete"
                        onClick={lambda -> None { remove(t.id); }}
                    >
                        X
                    </button>
                </div> for t in items
            ]}
            <div class="count"><span class="count-num">{remaining}</span>item(s) remaining</div>
        </div>;
}   