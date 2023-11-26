import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaylistsScreen extends StatefulWidget {
  @override
  _PlaylistsScreenState createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<dynamic> _userPlaylists = [];

  @override
  void initState() {
    super.initState();
    _loadUserPlaylists();
  }

  Future<void> _loadUserPlaylists() async {
    final Uri uri = Uri.parse('https://api.deezer.com/user/seuid/playlists'); //coloque seu id
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        _userPlaylists = data['data'];
      });
    } else {
      throw Exception('Failed to load user playlists');
    }
  }

  void _navigateToPlaylistTracks(int playlistId, String playlistTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistTracksScreen(playlistId: playlistId, playlistTitle: playlistTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlists'),
      ),
      body: _userPlaylists.isNotEmpty
          ? ListView.builder(
              itemCount: _userPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = _userPlaylists[index];
                return GestureDetector(
                  onTap: () {
                    _navigateToPlaylistTracks(playlist['id'], playlist['title']);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.grey[800],
                    ),
                    child: ListTile(
                      title: Text(
                        playlist['title'],
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Tracks: ${playlist['nb_tracks']}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.network(
                          playlist['picture_medium'],
                          width: 60.0,
                          height: 60.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class PlaylistTracksScreen extends StatelessWidget {
  final int playlistId;
  final String playlistTitle;

  PlaylistTracksScreen({required this.playlistId, required this.playlistTitle});

  Future<List<dynamic>> _loadPlaylistTracks() async {
    final Uri uri = Uri.parse('https://api.deezer.com/playlist/$playlistId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['tracks']['data'];
    } else {
      throw Exception('Failed to load playlist tracks');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlistTitle),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadPlaylistTracks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading playlist tracks'),
            );
          } else {
            List<dynamic> playlistTracks = snapshot.data!;
            return ListView.builder(
              itemCount: playlistTracks.length,
              itemBuilder: (context, index) {
                final track = playlistTracks[index];
                return ListTile(
                  title: Text(track['title']),
                  subtitle: Text(track['artist']['name']),
                );
              },
            );
          }
        },
      ),
    );
  }
}
