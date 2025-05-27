enum UniteBase {
  gramme('g'),
  millilitre('ml');

  final String symbole;
  const UniteBase(this.symbole);

  static UniteBase fromSymbole(String symbole) {
    return UniteBase.values.firstWhere(
      (unite) => unite.symbole == symbole,
      orElse: () => UniteBase.gramme,
    );
  }
} 