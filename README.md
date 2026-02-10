# Jac AI Todo App

## Student Info
**Name:** David Yao
**UMID:** 47275006

## Feature: AI Task Planner
I added an AI task planner that selects tasks based on available time.

In support of this, I also added due dates and task durations to the todo items.

## Setup & Run

### Setup
```bash
git clone https://github.com/Davidyao217/Jac-todo-custom.git
pip install jaseci
export GEMINI_API_KEY="your_api_key"
```

### Run
```bash
jac start main.jac
```
Open browser to `http://localhost:8000` (or displayed URL).

## Implementation
Core added logic is in `main.jac` in lines 74-89:

**Logic**: `generate_action_plan_inner` (line 89) uses `by llm()` to process tasks using the task list and focus minutes as parameters. 