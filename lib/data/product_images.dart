const String fallbackProductImage = 'assets/products/_default.png';

String normalizeName(String s) {
  var x = s.toLowerCase().trim();

  // quita espacios dobles
  x = x.replaceAll(RegExp(r'\s+'), ' ');

  // quita tildes y ñ
  x = x
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');

  return x;
}

String productImageFor(String name) {
  final key = normalizeName(name);
  return productImageByName[key] ?? fallbackProductImage;
}

const Map<String, String> productImageByName = {
  "palet ciruela amarilla": "assets/products/ciruela_amarilla.jpg",
  "palet ciruela roja": "assets/products/ciruela_roja.jpg",
  "palet nectarina amarilla": "assets/products/nectarina_amarilla.jpg",
  "palet nectarina roja": "assets/products/nectarina_roja.jpg",
  "palet aguacate": "assets/products/aguacate.jpg",
  "palet melocoton amarillo": "assets/products/melocoton_amarillo.jpg",
  "palet melocoton rojo": "assets/products/melocoton_rojo.jpg",
  "palet manzana roja": "assets/products/manzana_roja.jpg",
  "palet manzana amarilla": "assets/products/manzana_amarilla.jpg",
  "palet mango": "assets/products/mango.jpg",
  "palet kiwi": "assets/products/kiwi.jpg",
  "palet naranja": "assets/products/naranja.jpg",
  "palet mandarina/clementina": "assets/products/mandarina.jpg",
  "palet limon": "assets/products/limon.jpg",
  "palet platano": "assets/products/platano.jpg",
  "palet pera conferencia": "assets/products/pera.jpg",
  "palet uva": "assets/products/uva.jpg",
  "palet pina": "assets/products/pina.jpg",
  "palet sandia": "assets/products/sandia.jpg",
};