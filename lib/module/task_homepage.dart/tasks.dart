import 'package:flutter/material.dart';
import 'package:taskapp/service/database/database_service.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _databaseService.database;
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks =
        await _databaseService.getTasks(); // Assume this method exists
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _addTask(String name, String description, int status) async {
    await _databaseService.addTask(name, description, status);
    _taskNameController.clear();
    _taskDescriptionController.clear();
    await _loadTasks();
  }

  Future<void> updateTask(int id, String name, String description, int status) async {
    await _databaseService.updateTask(
      id,
      name,
      description,
      status,
    ); // Assume this method exists
    _taskNameController.clear();
    _taskDescriptionController.clear();
    await _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    await _databaseService.deleteTask(id); // Assume this method exists
    await _loadTasks();
  }

  void _showAddTaskDialog([
    int? id,
    String? taskName,
    String? taskDescription,
    int? status, // Default to 'ToDo'
  ]) {
    if (id != null) {
      _taskNameController.text = taskName ?? '';
      _taskDescriptionController.text = taskDescription ?? '';
    } else {
      _taskNameController.clear();
      _taskDescriptionController.clear();
    }
    int _selectedStatus = status ?? 0; 

    String taskActionTitle = id != null ? 'Update task' : 'Add task';


    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(taskActionTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Task Name'),
                  controller: _taskNameController,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Task Description',
                  ),
                  controller: _taskDescriptionController,
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Status'),
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('ToDo')),
                    DropdownMenuItem(value: 1, child: Text('On Progress')),
                    DropdownMenuItem(value: 2, child: Text('Pending')),
                    DropdownMenuItem(value: 3, child: Text('Complete')),
                    DropdownMenuItem(value: 4, child: Text('Incomplete')),
                  ],
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  String taskName = _taskNameController.text;
                  String taskDescription = _taskDescriptionController.text;

                  if (taskName.isNotEmpty && taskDescription.isNotEmpty) {
                    Navigator.of(context).pop();
                    String taskAction = id != null ? 'updated' : 'added';
                    if (id != null) {
                      await updateTask(id, taskName, taskDescription, _selectedStatus);
                    } else {
                      await _addTask(taskName, taskDescription, _selectedStatus);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Task "$taskName" $taskAction successfully!',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter both task name and description.',
                        ),
                      ),
                    );
                  }
                },
                child: Text(id != null ? 'Update' : 'Add '),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
         foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF39131E),
        elevation: 0,
        ),
      body:
          _tasks.isEmpty
              ? const Center(child: Text('No tasks added yet.'))
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                 ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return buildTaskCard(
                      task['id'],
                      task['name'],
                      task['description'],
                      task['status'],
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF39131E),
        foregroundColor: Colors.white,
        onPressed: _showAddTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

Widget buildTaskCard(int id, String taskName, String taskDescription, int status) {
  // Helper to get background color based on status
  Color getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.red.withOpacity(0.5);       // ToDo
      case 1:
        return Colors.yellow.withOpacity(0.5);    // On Progress
      case 2:
        return Colors.blue.withOpacity(0.5);      // Pending
      case 3:
        return Colors.green.withOpacity(0.5);     // Complete
      case 4:
      default:
        return Colors.grey.withOpacity(0.5);      // Incomplete
    }
  }

  // Helper to get status text
  String getStatusLabel(int status) {
    switch (status) {
      case 0:
        return 'ToDo';
      case 1:
        return 'On Progress';
      case 2:
        return 'Pending';
      case 3:
        return 'Complete';
      case 4:
      default:
        return 'Incomplete';
    }
  }

  return Dismissible(
    key: Key(id.toString()),
    direction: DismissDirection.endToStart,
    background: Container(
      padding: const EdgeInsets.only(right: 20),
      alignment: Alignment.centerRight,
      color: Colors.redAccent,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (direction) async {
      // Confirm delete action
      return await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
          ],
        ),
      );
    },
    onDismissed: (_) async {
      await _deleteTask(id);
    },
    child: Card(
      color: getStatusColor(status),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(taskName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(taskDescription),
            const SizedBox(height: 4),
            Text(
              getStatusLabel(status),
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        onTap: () {
          _showAddTaskDialog(id, taskName, taskDescription, status);
        },
        // trailing: IconButton(
        //   icon: const Icon(Icons.edit),
        //   onPressed: () {
        //     _showAddTaskDialog(id, taskName, taskDescription, status);
        //   },
        // ),
      ),
    ),
  );
}

Widget buildAddTaskCard() {
  return Card(
    color: Colors.grey[200],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    child: ListTile(
      onTap: _showAddTaskDialog,
      leading: const Icon(Icons.add, size: 40, color: Colors.black54),
      title: const Text(
        'Add New Task',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );
}


}
