import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'playlists.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deezer',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.purple),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          iconTheme: IconThemeData(color: Colors.purple),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<Map<String, dynamic>> _favoritedSongs = [];
  bool isDarkMode = true;
  final userId = ""; // coloque seu id

  Future<void> _searchDeezer(String query) async {
    final Uri uri = Uri.parse('https://api.deezer.com/search?q=$query');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data != null) {
        final dynamic responseData = data['data'];
        if (responseData != null && responseData is List) {
          setState(() {
            _searchResults = responseData;
            _favoritedSongs = List.generate(responseData.length, (index) => {'isFavorite': false});
          });
        }
      }

      _searchController.clear();
    } else {
      throw Exception('Falha ao carregar os resultados da busca');
    }
  }

  Future<void> _toggleFavorite(int index) async {
    final trackId = _searchResults[index]['id'].toString();
    final isFavorite = _favoritedSongs[index]['isFavorite'];

    try {
      final Uri updateFavoriteUri = Uri.parse('https://api.deezer.com/user/$userId/tracks');

      if (isFavorite) {
        final removeResponse = await http.put(updateFavoriteUri, body: {'track_id': trackId});

        if (removeResponse.statusCode == 200) {
          setState(() {
            _favoritedSongs[index]['isFavorite'] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removido dos favoritos'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('Falha ao remover dos favoritos');
        }
      } else {
        final addResponse = await http.put(updateFavoriteUri, body: {'track_id': trackId});

        if (addResponse.statusCode == 200) {
          setState(() {
            _favoritedSongs[index]['isFavorite'] = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Adicionado aos favoritos'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('Falha ao adicionar aos favoritos');
        }
      }
    } catch (error) {
      print('Erro: $error');
    }
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _navigateToPlaylists() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaylistsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deezer', style: TextStyle(color: Colors.purple)),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.album),
            onPressed: _navigateToPlaylists,
          ),
        ],
      ),
      body: Container(
        color: isDarkMode ? Colors.black : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Buscar músicas...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          _searchDeezer(_searchController.text);
                        },
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _searchResults.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            ),
                            child: ListTile(
                              title: Text(
                                _searchResults[index]['title'],
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                              ),
                              subtitle: Text(
                                _searchResults[index]['artist']['name'],
                                style: TextStyle(color: Colors.grey),
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.network(
                                  _searchResults[index]['album']['cover_medium'],
                                  width: 60.0,
                                  height: 60.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  _favoritedSongs[index]['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.purple,
                                ),
                                onPressed: () {
                                  _toggleFavorite(index);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
