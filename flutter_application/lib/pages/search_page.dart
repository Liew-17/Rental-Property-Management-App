import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _history = [];
  List<String> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();

    _focusNode.addListener(() {
      setState(() {
        _isSearching = _focusNode.hasFocus;
      });
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint(prefs.toString());
    setState(() {
      _history = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveHistory(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _history.remove(query); // avoid duplicates
    _history.insert(0, query);
    if (_history.length > 5) _history = _history.sublist(0, 5);
    await prefs.setStringList('search_history', _history);
    setState(() {});
  }

  void _onSearch(String query) {
    _saveHistory(query);
    _focusNode.unfocus(); // hide keyboard
    setState(() {
      _results = List.generate(5, (i) => "$query result $i"); // fake results
      _isSearching = false;
    });
  }

  void _deleteHistory(int index) async {
    debugPrint(_history.toString());
    _history.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _history);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0,
        titleSpacing: 0, 
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlignVertical: TextAlignVertical.center, 
            decoration: InputDecoration(
              hintText: 'Search...',
              filled: true,
              fillColor: Colors.grey[200], 
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none, 
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.black54),
                onPressed: () => _onSearch(_controller.text),
              ),
            ),
            onSubmitted: _onSearch,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSearching? (     
                  // If searching   
                         ListView.builder(
                            key: const ValueKey('history'),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final term = _history[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    // Tap to search text
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {                           
                                          _controller.text = term;
                                          _onSearch(term);
                                        },
                                        child: Text(
                                          term,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),

                                    // Delete button
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                          _deleteHistory(index);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        ) 
                    : (
                    // Else  
                      _results.isNotEmpty?
                      // If results found
                         ListView.builder(
                            key: const ValueKey('results'),
                            itemCount: _results.length,
                            itemBuilder: (_, index) {
                              return ListTile(title: Text(_results[index]));
                            },
                          )
                        : 
                      // Else
                        const Center(child: Text("No results"))
                      ),
              ),
            ),
          ],
        ),
      )

    );
  }
}