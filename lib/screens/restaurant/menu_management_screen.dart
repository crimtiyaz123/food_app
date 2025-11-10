import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/restaurant_owner_service.dart';

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;

  const MenuManagementScreen({super.key, required this.restaurantId});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final RestaurantOwnerService _service = RestaurantOwnerService();
  List<Product> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      final menu = await _service.getRestaurantMenu(widget.restaurantId);
      setState(() {
        _menuItems = menu;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading menu: $e')),
      );
    }
  }

  Future<void> _addMenuItem() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddMenuItemDialog(),
    );

    if (result != null) {
      try {
        await _service.addMenuItem(widget.restaurantId, result);
        await _loadMenu();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding menu item: $e')),
        );
      }
    }
  }

  Future<void> _editMenuItem(Product item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddMenuItemDialog(product: item),
    );

    if (result != null) {
      try {
        await _service.updateMenuItem(widget.restaurantId, item.id!, result);
        await _loadMenu();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating menu item: $e')),
        );
      }
    }
  }

  Future<void> _deleteMenuItem(Product item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteMenuItem(widget.restaurantId, item.id!);
        await _loadMenu();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting menu item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMenuItem,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No menu items yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first menu item',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Item Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: item.imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(item.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: item.imageUrl == null
                                  ? const Icon(Icons.fastfood, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 16),

                            // Item Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description ?? '',
                                    style: TextStyle(color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action Buttons
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editMenuItem(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteMenuItem(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class AddMenuItemDialog extends StatefulWidget {
  final Product? product;

  const AddMenuItemDialog({super.key, this.product});

  @override
  State<AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _categoryController.text = widget.product!.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Menu Item' : 'Edit Menu Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'name': _nameController.text,
                'description': _descriptionController.text,
                'price': double.parse(_priceController.text),
                'categoryId': _categoryController.text,
                'imageUrl': '',
                'rating': 0.0,
              };
              Navigator.of(context).pop(data);
            }
          },
          child: Text(widget.product == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}