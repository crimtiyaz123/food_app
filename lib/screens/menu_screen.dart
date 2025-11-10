import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_category.dart';
import '../models/product.dart';
import '../models/cart_model.dart';
import '../services/food_category_service.dart';
import 'product_screen.dart';

class MenuScreen extends StatefulWidget {
  final Map<String, List<Product>> stock;

  const MenuScreen({super.key, required this.stock});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    // All categories keys
    final categories = ["All", ...widget.stock.keys];

    // Products to display based on filter
    List<Product> productsToShow = [];
    if (selectedCategory == "All") {
      widget.stock.values.forEach((list) => productsToShow.addAll(list));
    } else {
      productsToShow = widget.stock[selectedCategory] ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Products grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
               itemCount: productsToShow.length,
               itemBuilder: (context, index) {
                 final product = productsToShow[index];
                 return Card(
                   elevation: 4,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Product Image
                       Container(
                         height: 100,
                         width: double.infinity,
                         decoration: BoxDecoration(
                           borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                         ),
                         child: Center(
                           child: Container(
                             width: 100,
                             height: 100,
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(12),
                               image: product.imageUrl != null
                                   ? DecorationImage(
                                       image: NetworkImage(product.imageUrl!),
                                       fit: BoxFit.cover,
                                     )
                                   : null,
                             ),
                             child: product.imageUrl == null
                                 ? const Icon(Icons.fastfood, size: 40, color: Colors.grey)
                                 : null,
                           ),
                         ),
                       ),
                       // Product Details
                       Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             // Name
                             Text(
                               product.name,
                               style: const TextStyle(
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                             const SizedBox(height: 2),
                             // Description
                             Text(
                               product.description ?? '',
                               style: const TextStyle(
                                 fontSize: 10,
                                 color: Colors.grey,
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                             const SizedBox(height: 4),
                             // Price and Rating
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(
                                   '\$${product.price.toStringAsFixed(2)}',
                                   style: const TextStyle(
                                     fontWeight: FontWeight.bold,
                                     color: Colors.green,
                                     fontSize: 12,
                                   ),
                                 ),
                                 Row(
                                   children: [
                                     const Icon(Icons.star, color: Colors.amber, size: 12),
                                     Text(
                                       product.rating?.toStringAsFixed(1) ?? 'N/A',
                                       style: const TextStyle(fontSize: 10),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                             const SizedBox(height: 6),
                             // Add Button
                             SizedBox(
                               width: double.infinity,
                               child: ElevatedButton(
                                 onPressed: () {
                                   context.read<CartModel>().addItem(product);
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(content: Text('${product.name} added to cart!')),
                                   );
                                 },
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.orange,
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(6),
                                   ),
                                   padding: const EdgeInsets.symmetric(vertical: 6),
                                   minimumSize: const Size(double.infinity, 32),
                                 ),
                                 child: const Text(
                                   'Add',
                                   style: TextStyle(fontSize: 12, color: Colors.white),
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 );
               },
             ),
           )
        ],
      ),
    );
  }
}
