import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getProductByBarcode } from './openFoodFacts';

describe('getProductByBarcode', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  it('returns null for empty/whitespace barcode', async () => {
    expect(await getProductByBarcode('')).toBeNull();
    expect(await getProductByBarcode('   ')).toBeNull();
    expect(fetch).not.toHaveBeenCalled();
  });

  it('returns null when response not ok', async () => {
    vi.mocked(fetch).mockResolvedValue({ ok: false } as Response);
    expect(await getProductByBarcode('3017620422003')).toBeNull();
  });

  it('returns null when status !== 1 or no product', async () => {
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: async () => ({ status: 0 }),
    } as Response);
    expect(await getProductByBarcode('3017620422003')).toBeNull();

    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: async () => ({ status: 1 }),
    } as Response);
    expect(await getProductByBarcode('3017620422003')).toBeNull();
  });

  it('returns product with name and nutriments', async () => {
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: async () => ({
        status: 1,
        product: {
          product_name_fr: 'Nutella',
          product_name: 'Nutella',
          brands: 'Ferrero',
          nutriments: {
            'energy-kcal_100g': 225,
            proteins_100g: 6,
            fat_100g: 11,
            carbohydrates_100g: 57,
          },
        },
      }),
    } as Response);
    const p = await getProductByBarcode('3017620422003');
    expect(p).not.toBeNull();
    expect(p!.name).toBe('Nutella — Ferrero');
    expect(p!.nutriments).toEqual({ calories: 225, proteines: 6, lipides: 11, glucides: 57 });
  });

  it('uses product_name when product_name_fr missing', async () => {
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: async () => ({
        status: 1,
        product: {
          product_name: 'Hazelnut spread',
          brands: '',
          nutriments: {},
        },
      }),
    } as Response);
    const p = await getProductByBarcode('123');
    expect(p!.name).toBe('Hazelnut spread');
  });

  it('name is only brands when product_name empty', async () => {
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: async () => ({
        status: 1,
        product: {
          product_name_fr: '',
          product_name: '',
          brands: 'Brand',
          nutriments: {},
        },
      }),
    } as Response);
    const p = await getProductByBarcode('123');
    expect(p!.name).toBe('Brand');
  });

  it('trims barcode and encodes URL', async () => {
    vi.mocked(fetch).mockResolvedValue({ ok: false } as Response);
    await getProductByBarcode('  3017620422003  ');
    expect(fetch).toHaveBeenCalledWith(
      'https://world.openfoodfacts.org/api/v2/product/3017620422003.json'
    );
  });

  it('returns null on fetch error', async () => {
    vi.mocked(fetch).mockRejectedValue(new Error('network'));
    expect(await getProductByBarcode('123')).toBeNull();
  });

  it('defaults nutriments to 0 when missing', async () => {
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: async () => ({
        status: 1,
        product: {
          product_name: 'X',
          brands: '',
          nutriments: undefined,
        },
      }),
    } as Response);
    const p = await getProductByBarcode('123');
    expect(p!.nutriments).toEqual({ calories: 0, proteines: 0, lipides: 0, glucides: 0 });
  });
});
