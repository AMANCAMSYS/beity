-- Tasks Phase Database Contract
-- Feature: 015-tasks-phase
-- Date: 2026-05-13

-- ============================================================
-- TABLES
-- ============================================================

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
  title varchar(200) NOT NULL,
  description text,
  due_date date,
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  assigned_to uuid REFERENCES auth.users(id),
  status varchar(20) NOT NULL DEFAULT 'incomplete' CHECK (status IN ('incomplete', 'completed')),
  recurrence_type varchar(20) CHECK (recurrence_type IN ('daily', 'weekly', 'monthly') OR recurrence_type IS NULL),
  completed_by uuid REFERENCES auth.users(id),
  completed_at timestamptz,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  archived_at timestamptz,
  CHECK (char_length(title) <= 200),
  CHECK (description IS NULL OR char_length(description) <= 2000)
);

-- Task comments table
CREATE TABLE IF NOT EXISTS task_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  content text NOT NULL CHECK (char_length(content) > 0),
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_tasks_home_id ON tasks(home_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_category_id ON tasks(category_id);
CREATE INDEX idx_tasks_created_by ON tasks(created_by);
CREATE INDEX idx_tasks_active ON tasks(home_id) WHERE deleted_at IS NULL AND archived_at IS NULL;

CREATE INDEX idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX idx_task_comments_created_at ON task_comments(created_at);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

-- Tasks policies
CREATE POLICY "Members can view home tasks"
  ON tasks FOR SELECT
  USING (home_id IN (
    SELECT home_id FROM home_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Members can insert tasks"
  ON tasks FOR INSERT
  WITH CHECK (home_id IN (
    SELECT home_id FROM home_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Creator assignee or admin can update tasks"
  ON tasks FOR UPDATE
  USING (
    created_by = auth.uid()
    OR assigned_to = auth.uid()
    OR home_id IN (
      SELECT home_id FROM home_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Task comments policies
CREATE POLICY "Members can view task comments"
  ON task_comments FOR SELECT
  USING (task_id IN (
    SELECT id FROM tasks WHERE home_id IN (
      SELECT home_id FROM home_members WHERE user_id = auth.uid()
    )
  ));

CREATE POLICY "Members can insert task comments"
  ON task_comments FOR INSERT
  WITH CHECK (task_id IN (
    SELECT id FROM tasks WHERE home_id IN (
      SELECT home_id FROM home_members WHERE user_id = auth.uid()
    )
  ));

CREATE POLICY "Own comments can be updated"
  ON task_comments FOR UPDATE
  USING (created_by = auth.uid());

CREATE POLICY "Own comments can be deleted"
  ON task_comments FOR DELETE
  USING (created_by = auth.uid());

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Auto-archive completed tasks older than 7 days
CREATE OR REPLACE FUNCTION archive_old_completed_tasks()
RETURNS void AS $$
BEGIN
  UPDATE tasks 
  SET archived_at = now()
  WHERE status = 'completed'
    AND completed_at < now() - interval '7 days'
    AND archived_at IS NULL
    AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create next recurring task instance
CREATE OR REPLACE FUNCTION create_next_recurring_task(p_task_id uuid)
RETURNS uuid AS $$
DECLARE
  v_task tasks%ROWTYPE;
  v_new_due_date date;
  v_new_task_id uuid;
BEGIN
  -- Get the completed task
  SELECT * INTO v_task FROM tasks WHERE id = p_task_id;
  
  IF v_task IS NULL OR v_task.recurrence_type IS NULL OR v_task.status != 'completed' THEN
    RETURN NULL;
  END IF;
  
  -- Calculate next due date
  IF v_task.due_date IS NOT NULL THEN
    CASE v_task.recurrence_type
      WHEN 'daily' THEN
        v_new_due_date := v_task.due_date + interval '1 day';
      WHEN 'weekly' THEN
        v_new_due_date := v_task.due_date + interval '7 days';
      WHEN 'monthly' THEN
        v_new_due_date := (v_task.due_date + interval '1 month');
        -- Handle edge cases (e.g., Jan 31 -> Feb 28)
        IF EXTRACT(DAY FROM v_task.due_date) > EXTRACT(DAY FROM v_new_due_date) THEN
          v_new_due_date := (DATE_TRUNC('month', v_new_due_date) + interval '1 month - 1 day')::date;
        END IF;
    END CASE;
  ELSE
    -- No due date on original: calculate from completion date
    CASE v_task.recurrence_type
      WHEN 'daily' THEN
        v_new_due_date := CURRENT_DATE + interval '1 day';
      WHEN 'weekly' THEN
        v_new_due_date := CURRENT_DATE + interval '7 days';
      WHEN 'monthly' THEN
        v_new_due_date := (CURRENT_DATE + interval '1 month');
    END CASE;
  END IF;
  
  -- Create new task instance
  INSERT INTO tasks (
    home_id, title, description, due_date, category_id,
    assigned_to, recurrence_type, created_by
  ) VALUES (
    v_task.home_id, v_task.title, v_task.description, v_new_due_date, v_task.category_id,
    v_task.assigned_to, v_task.recurrence_type, v_task.created_by
  ) RETURNING id INTO v_new_task_id;
  
  RETURN v_new_task_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user can edit a task (creator, assignee, or admin)
CREATE OR REPLACE FUNCTION can_edit_task(p_task_id uuid, p_user_id uuid)
RETURNS boolean AS $$
DECLARE
  v_task tasks%ROWTYPE;
  v_role varchar;
BEGIN
  SELECT * INTO v_task FROM tasks WHERE id = p_task_id;
  
  IF v_task IS NULL THEN
    RETURN false;
  END IF;
  
  -- Check if creator or assignee
  IF v_task.created_by = p_user_id OR v_task.assigned_to = p_user_id THEN
    RETURN true;
  END IF;
  
  -- Check if home admin
  SELECT role INTO v_role FROM home_members 
  WHERE home_id = v_task.home_id AND user_id = p_user_id;
  
  IF v_role IN ('owner', 'admin') THEN
    RETURN true;
  END IF;
  
  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-update updated_at on tasks
CREATE OR REPLACE FUNCTION update_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_tasks_updated_at();

-- Auto-set completed_by and completed_at when status changes to completed
CREATE OR REPLACE FUNCTION handle_task_completion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status = 'incomplete' THEN
    NEW.completed_by := auth.uid();
    NEW.completed_at := now();
  ELSIF NEW.status = 'incomplete' AND OLD.status = 'completed' THEN
    NEW.completed_by := NULL;
    NEW.completed_at := NULL;
    NEW.archived_at := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_task_completion
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION handle_task_completion();
