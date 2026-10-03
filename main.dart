import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: SmartFridgeApp()));

class Product {
  String name;
  int quantity;
  Product({required this.name, this.quantity = 1});
}

class AiRecipe {
  final String title;
  final String duration;
  final String instructions;
  AiRecipe({required this.title, required this.duration, required this.instructions});
}

List<Product> myFridge = [
  Product(name: 'Картофель 🥔', quantity: 1),
  Product(name: 'Мясо 🥩', quantity: 1),
];

final List<String> foodRuDatabase = ['Картогель 🥔', 'Мясо 🥩', 'Молоко 🥛', 'Яйца 🥚', 'Хлеб 🍞'];

class SmartFridgeApp extends StatelessWidget {
  const SmartFridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text('Умный Холодильник 🍏', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.kitchen), text: 'Продукты'),
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Рецепты от ИИ'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FridgeTab(),
            RecipesTab(),
          ],
        ),
      ),
    );
  }
}

class FridgeTab extends StatefulWidget {
  const FridgeTab({super.key});
  @override
  State<FridgeTab> createState() => _FridgeTabState();
}

class _FridgeTabState extends State<FridgeTab> {
  TextEditingController? _autocompleteController;

  void _addNewProduct(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      int existingIndex = myFridge.indexWhere((p) => p.name.toLowerCase() == name.trim().toLowerCase());
      if (existingIndex != -1) {
        myFridge[existingIndex].quantity++;
      } else {
        myFridge.add(Product(name: name.trim()));
      }
      _autocompleteController?.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue val) {
                  if (val.text.isEmpty) return const Iterable<String>.empty();
                  return foodRuDatabase.where((opt) => opt.toLowerCase().contains(val.text.toLowerCase()));
                },
                onSelected: (selection) => _addNewProduct(selection),
                fieldViewBuilder: (ctx, textController, focusNode, onSubmitted) {
                  _autocompleteController = textController;
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Что добавим в холодильник?',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                        onPressed: () => _addNewProduct(textController.text),
                      ),
                    ),
                    onSubmitted: (value) => _addNewProduct(value),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: myFridge.length,
              itemBuilder: (context, index) {
                final product = myFridge[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 28),
                          onPressed: () => setState(() {
                            if (product.quantity > 1) {
                              product.quantity--;
                            } else {
                              myFridge.removeAt(index);
                            }
                          }),
                        ),
                        const SizedBox(width: 10),
                        Text('${product.quantity} шт', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
                          onPressed: () => setState(() => product.quantity++),
                        ),
                        const SizedBox(width: 25),
                        Expanded(child: Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecipesTab extends StatefulWidget {
  const RecipesTab({super.key});
  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  List<AiRecipe> aiRecipes = [];
  bool isLoading = false;

  Future<void> _askAiForRecipes() async {
    setState(() {
      isLoading = true;
    });

    String productsList = myFridge.map((p) => p.name).join(', ');

    // Обрати внимание: для отправки запросов к YandexGPT с мобильного устройства 
    // базовый URL "https://yandex.net" нужно будет заменить на полный эндпоинт:
    // https://yandex.net
    const String apiKey = "AQVNwoxqvYttqjttrXZj5sQEWUddtB1iz0SZ1Lp9"; 
    const String folderId = "b1gu1l2c8thgnac4nusp"; 
    const String url = "https://yandex.net";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key $apiKey',
        },
        body: jsonEncode({
          "modelUri": "gpt://$folderId/yandexgpt-lite/latest",
          "completionOptions": {
            "stream": false,
            "temperature": 0.5,
            "maxTokens": 1000
          },
          "messages": [
            {
              "role": "system",
              "content": "Ты ИИ-ассистент умного холодильника в стиле сайта Food.ru. Ты должен придумать 2 реальных рецепта из переданных продуктов. Ответь строго в формате готового JSON массива объектов, без разметки markdown и без слов вокруг. Формат ответа: [{\"title\": \"Название блюда\", \"duration\": \"Время\", \"instructions\": \"Инструкция\"}]"
            },
            {
              "role": "user",
              "content": "У меня в холодильнике есть: $productsList. Придумай рецепты."
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String aiTextResponse = decoded['result']['alternatives']['message']['text'];
        List<dynamic> jsonRecipes = jsonDecode(aiTextResponse);
        
        setState(() {
          aiRecipes = jsonRecipes.map((r) => AiRecipe(
            title: r['title'] ?? 'Рецепт без названия',
            duration: r['duration'] ?? 'Время не указано',
            instructions: r['instructions'] ?? 'Инструкция отсутствует'
          )).toList();
        });
      }
    } catch (e) {
      print("Ошибка ИИ: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _askAiForRecipes,
        label: const Text('Спросить ИИ'),
        icon: const Icon(Icons.bolt),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : aiRecipes.isEmpty 
          ? const Center(child: Text('Нажмите кнопку, чтобы получить рецепты от ИИ'))
          : ListView.builder(
              itemCount: aiRecipes.length,
              itemBuilder: (context, index) {
                final recipe = aiRecipes[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Время: ${recipe.duration}\n\n${recipe.instructions}'),
                  ),
                );
              },
            ),
    );
  }
}
