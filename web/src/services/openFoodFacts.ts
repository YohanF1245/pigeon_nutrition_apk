const BASE_URL = 'https://world.openfoodfacts.org/api/v2';

export interface OpenFoodFactsProduct {
  name: string;
  brands?: string;
  nutriments: {
    calories: number;
    proteines: number;
    lipides: number;
    glucides: number;
  };
}

export async function getProductByBarcode(barcode: string): Promise<OpenFoodFactsProduct | null> {
  const trimmed = barcode.trim();
  if (!trimmed) return null;

  try {
    const res = await fetch(`${BASE_URL}/product/${encodeURIComponent(trimmed)}.json`);
    if (!res.ok) return null;

    const data = await res.json();
    if (data.status !== 1 || !data.product) return null;

    const p = data.product;
    const nutriments = p.nutriments ?? {};
    const name = p.product_name_fr ?? p.product_name ?? '';
    const brands = p.brands ?? '';

    return {
      name: brands ? `${name}${name ? ' — ' : ''}${brands}` : name,
      brands: brands || undefined,
      nutriments: {
        calories: Number(nutriments['energy-kcal_100g']) || 0,
        proteines: Number(nutriments.proteins_100g) || 0,
        lipides: Number(nutriments.fat_100g) || 0,
        glucides: Number(nutriments.carbohydrates_100g) || 0,
      },
    };
  } catch {
    return null;
  }
}
