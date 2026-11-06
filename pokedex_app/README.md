# Pokédex (Flutter)

App mobile que consome uma API REST externa e mostra os dados em uma interface Flutter.

## API utilizada
- **PokéAPI** — https://pokeapi.co/api/v2/
- `GET /pokemon?limit=151` — lista dos 151 primeiros Pokémon
- `GET /pokemon/{id}` — detalhes (tipos, altura, peso, status)
- Gratuita, sem chave de API.

## Conceitos aplicados
- Requisições HTTP com o pacote `http`
- Decodificação de JSON (`jsonDecode` + `fromJson`)
- Métodos assíncronos (`Future`, `async/await`) e `FutureBuilder`
- Estados de carregamento, erro (com botão "tentar de novo") e lista vazia
- Busca por nome e navegação entre duas telas

## Como rodar
```bash
flutter create .        # gera as pastas android/ios (só na primeira vez)
flutter pub get
flutter run
```
> Se for rodar no Android em release, confirme que o `AndroidManifest.xml` tem
> `<uses-permission android:name="android.permission.INTERNET"/>`.
