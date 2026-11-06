import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// API utilizada: PokéAPI -> https://pokeapi.co/api/v2/
// Endpoints:
//   GET /pokemon?limit=151   (lista os 151 primeiros Pokémon)
//   GET /pokemon/{id}        (detalhes de um Pokémon)
// ---------------------------------------------------------------------------

void main() => runApp(const PokedexApp());

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ----------------------------- MODELOS -------------------------------------

class PokemonItem {
  final int id;
  final String name;

  PokemonItem({required this.id, required this.name});

  // A lista da API traz só nome e URL; o id vem do final da URL.
  factory PokemonItem.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final segments = url.split('/').where((s) => s.isNotEmpty).toList();
    return PokemonItem(id: int.parse(segments.last), name: json['name']);
  }

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
}

class PokemonDetail {
  final int id;
  final String name;
  final double heightM;
  final double weightKg;
  final List<String> types;
  final Map<String, int> stats;

  PokemonDetail({
    required this.id,
    required this.name,
    required this.heightM,
    required this.weightKg,
    required this.types,
    required this.stats,
  });

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    return PokemonDetail(
      id: json['id'],
      name: json['name'],
      heightM: (json['height'] as int) / 10, // decímetros -> metros
      weightKg: (json['weight'] as int) / 10, // hectogramas -> kg
      types: (json['types'] as List)
          .map((t) => t['type']['name'] as String)
          .toList(),
      stats: {
        for (final s in json['stats'])
          s['stat']['name'] as String: s['base_stat'] as int,
      },
    );
  }

  String get artworkUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}

// ----------------------------- SERVIÇO -------------------------------------

class PokeApiService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  Future<List<PokemonItem>> fetchPokemonList() async {
    final response = await http.get(Uri.parse('$_baseUrl/pokemon?limit=151'));
    if (response.statusCode != 200) {
      throw Exception('Erro ${response.statusCode} ao buscar a lista');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => PokemonItem.fromJson(e))
        .toList();
  }

  Future<PokemonDetail> fetchPokemonDetail(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/pokemon/$id'));
    if (response.statusCode != 200) {
      throw Exception('Erro ${response.statusCode} ao buscar o Pokémon');
    }
    return PokemonDetail.fromJson(jsonDecode(response.body));
  }
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ----------------------------- TELA: LISTA ---------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = PokeApiService();
  late Future<List<PokemonItem>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.fetchPokemonList();
  }

  void _reload() {
    setState(() => _future = _service.fetchPokemonList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar Pokémon pelo nome',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PokemonItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 48),
                        const SizedBox(height: 8),
                        const Text('Não foi possível carregar os dados.'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Tentar de novo'),
                        ),
                      ],
                    ),
                  );
                }

                final list = snapshot.data!
                    .where((p) => p.name.contains(_query))
                    .toList();

                if (list.isEmpty) {
                  return const Center(child: Text('Nenhum Pokémon encontrado.'));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final p = list[i];
                    return ListTile(
                      leading: Image.network(
                        p.spriteUrl,
                        width: 56,
                        height: 56,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.catching_pokemon),
                      ),
                      title: Text(capitalize(p.name)),
                      subtitle: Text('#${p.id.toString().padLeft(3, '0')}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailPage(item: p),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------- TELA: DETALHES ------------------------------

class DetailPage extends StatefulWidget {
  final PokemonItem item;
  const DetailPage({super.key, required this.item});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<PokemonDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = PokeApiService().fetchPokemonDetail(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(capitalize(widget.item.name))),
      body: FutureBuilder<PokemonDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os detalhes.'));
          }

          final d = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Image.network(
                  d.artworkUrl,
                  height: 220,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.catching_pokemon, size: 120),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '#${d.id.toString().padLeft(3, '0')}  ${capitalize(d.name)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: d.types
                    .map((t) => Chip(label: Text(capitalize(t))))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoBox(label: 'Altura', value: '${d.heightM} m'),
                  _InfoBox(label: 'Peso', value: '${d.weightKg} kg'),
                ],
              ),
              const SizedBox(height: 24),
              Text('Status base',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...d.stats.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 130, child: Text(e.key)),
                      SizedBox(
                        width: 36,
                        child: Text('${e.value}', textAlign: TextAlign.end),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (e.value / 255).clamp(0.0, 1.0),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label),
      ],
    );
  }
}
