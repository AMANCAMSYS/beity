-- Create inventory_items table
CREATE TABLE public.inventory_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL REFERENCES public.homes(id) ON DELETE CASCADE,
  name varchar(255) NOT NULL,
  quantity numeric(10,2) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  unit_id uuid REFERENCES public.units(id),
  category_id uuid REFERENCES public.categories(id),
  min_quantity numeric(10,2) CHECK (min_quantity IS NULL OR min_quantity >= 0),
  notes text,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  updated_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT uq_inventory_items_home_name_unit UNIQUE (home_id, name, unit_id, deleted_at)
);

-- Create inventory_transactions table
CREATE TABLE public.inventory_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_item_id uuid NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
  home_id uuid NOT NULL REFERENCES public.homes(id) ON DELETE CASCADE,
  previous_quantity numeric(10,2) NOT NULL,
  new_quantity numeric(10,2) NOT NULL,
  change_reason varchar(50) NOT NULL CHECK (change_reason IN ('manual_update', 'shopping_restock', 'zero_removal', 'initial_add', 'delete')),
  changed_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

-- Indexes for inventory_items
CREATE INDEX idx_inventory_items_home_id ON public.inventory_items (home_id);
CREATE INDEX idx_inventory_items_category ON public.inventory_items (home_id, category_id);
CREATE INDEX idx_inventory_items_name_search ON public.inventory_items (home_id, name);
CREATE INDEX idx_inventory_items_updated_by ON public.inventory_items (updated_by);
CREATE INDEX idx_inventory_items_low_stock ON public.inventory_items (home_id)
  WHERE quantity <= min_quantity AND deleted_at IS NULL;

-- Indexes for inventory_transactions
CREATE INDEX idx_inventory_transactions_item_id ON public.inventory_transactions (inventory_item_id);
CREATE INDEX idx_inventory_transactions_home_id ON public.inventory_transactions (home_id);
CREATE INDEX idx_inventory_transactions_created_at ON public.inventory_transactions (inventory_item_id, created_at DESC);

-- RLS Policies for inventory_items
CREATE POLICY "Users can view inventory items for their homes"
ON public.inventory_items FOR SELECT
USING (
  home_id IN (
    SELECT home_id FROM public.home_members
    WHERE user_id = (select auth.uid())
  )
);

CREATE POLICY "Users can add inventory items"
ON public.inventory_items FOR INSERT
WITH CHECK (
  home_id IN (
    SELECT home_id FROM public.home_members
    WHERE user_id = (select auth.uid())
  )
  AND created_by = (select auth.uid())
  AND updated_by = (select auth.uid())
);

CREATE POLICY "Users can update inventory items"
ON public.inventory_items FOR UPDATE
USING (
  home_id IN (
    SELECT home_id FROM public.home_members
    WHERE user_id = (select auth.uid())
  )
)
WITH CHECK (
  updated_by = (select auth.uid())
);

CREATE POLICY "Users can delete inventory items"
ON public.inventory_items FOR DELETE
USING (
  home_id IN (
    SELECT home_id FROM public.home_members
    WHERE user_id = (select auth.uid())
  )
);

-- RLS Policies for inventory_transactions
CREATE POLICY "Users can view inventory transactions"
ON public.inventory_transactions FOR SELECT
USING (
  home_id IN (
    SELECT home_id FROM public.home_members
    WHERE user_id = (select auth.uid())
  )
);

CREATE POLICY "Users can create inventory transactions"
ON public.inventory_transactions FOR INSERT
WITH CHECK (
  home_id IN (
    SELECT home_id FROM public.home_members
    WHERE user_id = (select auth.uid())
  )
  AND changed_by = (select auth.uid())
);

-- Trigger for updated_at on inventory_items
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.inventory_items
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);
