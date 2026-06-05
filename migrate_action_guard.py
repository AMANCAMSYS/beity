import os
import re

files_to_modify = [
    "lib/features/auth/presentation/screens/login_screen.dart",
    "lib/features/auth/presentation/screens/register_screen.dart",
    "lib/features/auth/presentation/screens/profile_screen.dart",
    "lib/features/homes/presentation/screens/create_home_screen.dart",
    "lib/features/shopping_lists/presentation/screens/create_shopping_list_screen.dart",
    "lib/features/shopping_lists/presentation/screens/add_item_screen.dart",
    "lib/features/shopping_lists/presentation/screens/edit_item_screen.dart",
    "lib/features/categories/presentation/screens/create_category_screen.dart",
    "lib/features/categories/presentation/screens/create_unit_screen.dart",
    "lib/features/expenses/presentation/screens/add_expense_screen.dart",
    "lib/features/tasks/presentation/screens/add_task_screen.dart",
    "lib/features/inventory/presentation/screens/add_inventory_item_screen.dart",
    "lib/features/inventory/presentation/screens/edit_inventory_item_screen.dart"
]

for file_path in files_to_modify:
    full_path = os.path.join("/home/omar/Desktop/Sawa", file_path)
    if not os.path.exists(full_path):
        print(f"File not found: {full_path}")
        continue
        
    with open(full_path, "r") as f:
        content = f.read()

    # Skip if already migrated
    if "ActionGuard" in content and "ActionDebouncer" not in content:
        continue

    # 1. Replace imports
    content = content.replace("import 'package:sawa/core/utils/action_debouncer.dart';", "import 'package:sawa/core/utils/action_guard.dart';")
    content = content.replace("import '../../../../core/utils/action_debouncer.dart';", "import '../../../../core/utils/action_guard.dart';")
    content = content.replace("import '../../../core/utils/action_debouncer.dart';", "import '../../../core/utils/action_guard.dart';")

    # 2. Add final _guard = ActionGuard(); to state classes
    # Find class _XXXState extends
    state_class_match = re.search(r'(class\s+_[a-zA-Z0-9_]+State\s+extends\s+(ConsumerState|State)<[^>]+>\s*\{)', content)
    if state_class_match:
        insert_pos = state_class_match.end()
        # check if it already has _guard
        if "final _guard = ActionGuard();" not in content:
            content = content[:insert_pos] + "\n  final _guard = ActionGuard();" + content[insert_pos:]

    # 3. Add _guard.dispose() to dispose() method
    dispose_match = re.search(r'(void\s+dispose\(\)\s*\{)', content)
    if dispose_match:
        insert_pos = dispose_match.end()
        if "_guard.dispose();" not in content:
            content = content[:insert_pos] + "\n    _guard.dispose();" + content[insert_pos:]
    else:
        # Create dispose method if it doesn't exist
        # Find where to put it (after _guard declaration usually)
        if state_class_match:
            guard_decl = re.search(r'final\s+_guard\s*=\s*ActionGuard\(\);', content)
            if guard_decl:
                insert_pos = guard_decl.end()
                dispose_method = "\n\n  @override\n  void dispose() {\n    _guard.dispose();\n    super.dispose();\n  }"
                content = content[:insert_pos] + dispose_method + content[insert_pos:]

    # 4. Replace ActionDebouncer.execute with _guard.run
    content = content.replace("ActionDebouncer.execute", "_guard.run")

    with open(full_path, "w") as f:
        f.write(content)
        
    print(f"Migrated {file_path}")
