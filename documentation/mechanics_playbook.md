# Mechanics Playbook (BI4All Project)

## Git Workflow
### Editing on GitHub (web)
- GitHub auto-commits and auto-pushes.
- Local repo will be behind until you run `git pull`.

### Editing locally (Git Bash)
1. `git status`
2. `git add <files>`
3. `git commit -m "<message>"`
4. `git push`

### Rule
If you are unsure whether GitHub has newer commits: run `git pull` first.

---

## Power Apps: Where logic lives
- Screen load: `OnVisible`
- Buttons/toggles: `OnSelect` / `OnCheck` / `OnUncheck`
- Data shown in galleries: `Items`
- Form default values: `Default`
- Values sent on submit: `Update`
- Lock/unlock controls: `DisplayMode`

### Controlled edits
- Show all fields.
- Only approved fields are editable.
- System fields are read-only (configId, createDate, lastModifiedDate, etc).

---

## Power Automate: Standard pattern
1. Trigger: Power Apps (V2)
2. Inputs: explicit parameters
3. SQL: call stored procedure
4. Response: return success/fail + message to Power Apps

---

## SQL: Standard procedure shape
- Validate inputs
- Perform update/insert
- Return a clear status and message
