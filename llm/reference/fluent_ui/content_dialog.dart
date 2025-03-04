Button(
  child: const Text('Show dialog'),
  onPressed: () => showContentDialog(context),
),

void showContentDialog(BuildContext context) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => ContentDialog(
      title: const Text('Delete file permanently?'),
      content: const Text(
        'If you delete this file, you won\'t be able to recover it. Do you want to delete it?',
      ),
      actions: [
        Button(
          child: const Text('Delete'),
          onPressed: () {
            Navigator.pop(context, 'User deleted file');
            // Delete file here
          },
        ),
        FilledButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context, 'User canceled dialog'),
        ),
      ],
    ),
  );
  setState(() {});
}