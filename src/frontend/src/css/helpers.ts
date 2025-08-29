import { format } from "path";

export const getContrastColor = (hex: string) : 'black' | 'white' => {
    // Remove "#" if present
    hex = hex.replace(/^#/, '');

    // Convert shorthand hex to full form (e.g., "abc" → "aabbcc")
    if (hex.length === 3) {
        hex = hex.split('').map(c => c + c).join('');
    }

    // Parse RGB values
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);

    // Calculate luminance (per WCAG formula)
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b);

    // Return contrast color
    return luminance > 186 ? 'black' : 'white';
}
