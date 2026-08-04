import 'dart:async';

import 'package:flutter/material.dart';

import '../services/places_service.dart';
import '../theme/app_colors.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends State<DestinationSearchScreen> {
  final TextEditingController searchController =
      TextEditingController();

  Timer? debounce;
  List<PlaceSuggestion> suggestions = [];

  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged(String value) {
    debounce?.cancel();

    debounce = Timer(
      const Duration(milliseconds: 450),
      () => searchPlaces(value),
    );
  }

  Future<void> searchPlaces(String query) async {
    if (query.trim().length < 2) {
      if (!mounted) return;

      setState(() {
        suggestions = [];
        errorMessage = null;
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results =
          await PlacesService.autocomplete(query);

      if (!mounted) return;

      setState(() {
        suggestions = results;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        suggestions = [];
        isLoading = false;
        errorMessage =
            'Adres önerileri alınamadı. Tekrar deneyin.';
      });
    }
  }

  Future<void> selectPlace(
    PlaceSuggestion suggestion,
  ) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final selection =
          await PlacesService.getPlaceDetails(suggestion);

      if (!mounted) return;

      if (selection == null) {
        setState(() {
          isLoading = false;
          errorMessage =
              'Seçilen adresin konumu alınamadı.';
        });
        return;
      }

      Navigator.pop(context, selection);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Adres bilgisi alınamadı. Tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        title: const Text('Gidilecek Yer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              autofocus: true,
              onChanged: onSearchChanged,
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Adres, cadde veya işletme ara...',
                hintStyle: const TextStyle(
                  color: Colors.white38,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.yellow,
                ),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            suggestions = [];
                            errorMessage = null;
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                        ),
                      ),
                filled: true,
                fillColor: const Color(0xFF171717),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: AppColors.yellow,
                ),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              )
            else if (suggestions.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Adres aramak için en az 2 karakter yaz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) =>
                      const Divider(
                        color: Colors.white10,
                      ),
                  itemBuilder: (context, index) {
                    final suggestion =
                        suggestions[index];

                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.yellow,
                      ),
                      title: Text(
                        suggestion.description,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        selectPlace(suggestion);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}